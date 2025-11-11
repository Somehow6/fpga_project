//****************************************Copyright (c)***********************************//
// 二值化模块
// 功能：动态阈值二值化
// 阈值计算：threshold = 0.3 × max(pixel)
// 实现方式：两次扫描 - 第一次找最大值，第二次二值化
//****************************************************************************************//

module binarization #(
    parameter IMG_SIZE = 784  // 图像像素总数（28×28=784）
)(
    input                 clk            ,  // 时钟
    input                 rst_n          ,  // 复位信号
    
    // 输入像素流
    input      [7:0]      pixel_in       ,  // 输入灰度像素
    input                 pixel_valid_in ,  // 输入有效信号
    input                 frame_start    ,  // 帧开始信号
    
    // 输出二值化像素
    output reg            pixel_out      ,  // 输出二值像素（0或1）
    output reg            pixel_valid_out,  // 输出有效信号
    output reg            frame_done        // 一帧处理完成
);

//==============================================================================
// 状态机
//==============================================================================
localparam STATE_SCAN1   = 2'd0;  // 第一次扫描：收集数据并计算最大值
localparam STATE_CALC    = 2'd1;  // 计算阈值
localparam STATE_SCAN2   = 2'd2;  // 第二次扫描：二值化输出
localparam STATE_DONE    = 2'd3;  // 完成

reg [1:0] state;

//==============================================================================
// 图像缓存（BRAM）
//==============================================================================
reg [7:0] image_buf [0:IMG_SIZE-1];

//==============================================================================
// 计数器与控制信号
//==============================================================================
reg [9:0] pixel_cnt;     // 像素计数器 (0~IMG_SIZE-1)
reg [7:0] max_value;     // 最大像素值
reg [7:0] threshold;     // 二值化阈值

//==============================================================================
// 状态机
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state           <= STATE_SCAN1;
        pixel_cnt       <= 10'd0;
        max_value       <= 8'd0;
        threshold       <= 8'd0;
        pixel_out       <= 1'b0;
        pixel_valid_out <= 1'b0;
        frame_done      <= 1'b0;
    end else begin
        case (state)
            //==============================================================
            // 状态0：第一次扫描 - 收集数据并找最大值
            //==============================================================
            STATE_SCAN1: begin
                frame_done      <= 1'b0;
                pixel_valid_out <= 1'b0;
                
                if (frame_start) begin
                    pixel_cnt <= 10'd0;
                    max_value <= 8'd0;
                end else if (pixel_valid_in) begin
                    // 存储像素到缓存
                    image_buf[pixel_cnt] <= pixel_in;
                    
                    // 更新最大值
                    if (pixel_in > max_value) begin
                        max_value <= pixel_in;
                    end
                    
                    // 像素计数
                    if (pixel_cnt == IMG_SIZE - 1) begin
                        pixel_cnt <= 10'd0;
                        state     <= STATE_CALC;  // 进入阈值计算状态
                    end else begin
                        pixel_cnt <= pixel_cnt + 10'd1;
                    end
                end
            end
            
            //==============================================================
            // 状态1：计算阈值 = 0.3 × max_value
            // 使用近似：0.3 ≈ 77/256 ≈ (64+13)/256 = (max>>2) + (max>>4) - 小误差
            // 更简单：threshold = (max_value * 77) >> 8
            //==============================================================
            STATE_CALC: begin
                // 计算：threshold = max_value × 77 / 256
                // 使用移位和加法近似：77 = 64 + 8 + 4 + 1
                threshold <= (max_value >> 2) + (max_value >> 4);  // ≈ 0.3125
                state     <= STATE_SCAN2;
                pixel_cnt <= 10'd0;
            end
            
            //==============================================================
            // 状态2：第二次扫描 - 二值化输出
            //==============================================================
            STATE_SCAN2: begin
                // 从缓存读取像素并二值化
                if (image_buf[pixel_cnt] > threshold) begin
                    pixel_out <= 1'b1;
                end else begin
                    pixel_out <= 1'b0;
                end
                pixel_valid_out <= 1'b1;
                
                // 像素计数
                if (pixel_cnt == IMG_SIZE - 1) begin
                    pixel_cnt  <= 10'd0;
                    state      <= STATE_DONE;
                    frame_done <= 1'b1;
                end else begin
                    pixel_cnt <= pixel_cnt + 10'd1;
                end
            end
            
            //==============================================================
            // 状态3：完成 - 等待下一帧
            //==============================================================
            STATE_DONE: begin
                pixel_valid_out <= 1'b0;
                frame_done      <= 1'b0;
                
                if (frame_start) begin
                    state     <= STATE_SCAN1;
                    pixel_cnt <= 10'd0;
                    max_value <= 8'd0;
                end
            end
            
            default: begin
                state <= STATE_SCAN1;
            end
        endcase
    end
end

endmodule

