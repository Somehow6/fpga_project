//****************************************Copyright (c)***********************************//
// 高斯滤波模块
// 功能：3×3高斯滤波器
// 卷积核：[1 2 1; 2 4 2; 1 2 1] / 16
// 使用行缓冲实现流式处理
//****************************************************************************************//

module gaussian_filter #(
    parameter IMG_WIDTH = 112  // 图像宽度（可配置：112或56）
)(
    input                 clk            ,  // 时钟
    input                 rst_n          ,  // 复位信号
    
    // 输入像素流
    input      [7:0]      pixel_in       ,  // 输入灰度像素
    input                 pixel_valid_in ,  // 输入有效信号
    input                 frame_start    ,  // 帧开始信号
    
    // 输出滤波后的像素
    output reg [7:0]      pixel_out      ,  // 输出灰度像素
    output reg            pixel_valid_out   // 输出有效信号
);

//==============================================================================
// 行缓冲 - 存储前2行数据
//==============================================================================
reg [7:0] line_buf0 [0:IMG_WIDTH-1];  // 第0行缓冲
reg [7:0] line_buf1 [0:IMG_WIDTH-1];  // 第1行缓冲
reg [7:0] cur_line  [0:IMG_WIDTH-1];  // 当前行缓冲

//==============================================================================
// 计数器
//==============================================================================
reg [7:0] col_cnt;      // 列计数器 (0~IMG_WIDTH-1)
reg [7:0] row_cnt;      // 行计数器
reg [1:0] line_valid;   // 行有效标志 (至少需要3行才能输出)

//==============================================================================
// 3×3窗口数据
//==============================================================================
reg [7:0] win00, win01, win02;  // 窗口第0行
reg [7:0] win10, win11, win12;  // 窗口第1行
reg [7:0] win20, win21, win22;  // 窗口第2行

//==============================================================================
// 帧开始处理
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        col_cnt    <= 8'd0;
        row_cnt    <= 8'd0;
        line_valid <= 2'd0;
    end else begin
        if (frame_start) begin
            col_cnt    <= 8'd0;
            row_cnt    <= 8'd0;
            line_valid <= 2'd0;
        end else if (pixel_valid_in) begin
            // 列计数
            if (col_cnt == IMG_WIDTH - 1) begin
                col_cnt <= 8'd0;
                row_cnt <= row_cnt + 8'd1;
                // 至少有3行数据后才开始输出
                if (line_valid < 2'd3) begin
                    line_valid <= line_valid + 2'd1;
                end
            end else begin
                col_cnt <= col_cnt + 8'd1;
            end
        end
    end
end

//==============================================================================
// 行缓冲更新与窗口数据提取
//==============================================================================
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < IMG_WIDTH; i = i + 1) begin
            line_buf0[i] <= 8'd0;
            line_buf1[i] <= 8'd0;
            cur_line[i]  <= 8'd0;
        end
        win00 <= 8'd0; win01 <= 8'd0; win02 <= 8'd0;
        win10 <= 8'd0; win11 <= 8'd0; win12 <= 8'd0;
        win20 <= 8'd0; win21 <= 8'd0; win22 <= 8'd0;
    end else begin
        if (pixel_valid_in) begin
            // 更新当前行缓冲
            cur_line[col_cnt] <= pixel_in;
            
            // 行结束时，将行缓冲向前推进
            if (col_cnt == IMG_WIDTH - 1) begin
                for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                    line_buf0[i] <= line_buf1[i];  // buf1 -> buf0
                    line_buf1[i] <= cur_line[i];   // cur  -> buf1
                end
            end
            
            // 构建3×3窗口（使用边界复制处理边缘）
            if (col_cnt == 0) begin
                // 第一列：左边界复制
                win00 <= line_buf0[0];
                win01 <= line_buf0[0];
                win02 <= line_buf0[1];
                
                win10 <= line_buf1[0];
                win11 <= line_buf1[0];
                win12 <= line_buf1[1];
                
                win20 <= cur_line[0];
                win21 <= pixel_in;
                win22 <= (col_cnt < IMG_WIDTH - 1) ? cur_line[1] : pixel_in;
            end else if (col_cnt == IMG_WIDTH - 1) begin
                // 最后一列：右边界复制
                win00 <= line_buf0[col_cnt-1];
                win01 <= line_buf0[col_cnt];
                win02 <= line_buf0[col_cnt];
                
                win10 <= line_buf1[col_cnt-1];
                win11 <= line_buf1[col_cnt];
                win12 <= line_buf1[col_cnt];
                
                win20 <= cur_line[col_cnt-1];
                win21 <= pixel_in;
                win22 <= pixel_in;
            end else begin
                // 中间列：正常窗口
                win00 <= line_buf0[col_cnt-1];
                win01 <= line_buf0[col_cnt];
                win02 <= line_buf0[col_cnt+1];
                
                win10 <= line_buf1[col_cnt-1];
                win11 <= line_buf1[col_cnt];
                win12 <= line_buf1[col_cnt+1];
                
                win20 <= cur_line[col_cnt-1];
                win21 <= pixel_in;
                win22 <= cur_line[col_cnt+1];
            end
        end
    end
end

//==============================================================================
// 高斯卷积计算
// 卷积核：[1 2 1; 2 4 2; 1 2 1] / 16
// 计算：sum = 1×p00 + 2×p01 + 1×p02 + 2×p10 + 4×p11 + 2×p12 + 1×p20 + 2×p21 + 1×p22
// 结果：result = sum >> 4 (除以16)
//==============================================================================
wire [11:0] conv_sum;  // 卷积和（最大值：16×255=4080）

assign conv_sum = 
    win00 + {win01, 1'b0} + win02 +
    {win10, 1'b0} + {win11, 2'b00} + {win12, 1'b0} +
    win20 + {win21, 1'b0} + win22;

//==============================================================================
// 输出寄存器（添加1拍延迟用于时序优化）
//==============================================================================
reg [7:0] conv_result;
reg pixel_valid_d1;
reg pixel_valid_d2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_result     <= 8'd0;
        pixel_valid_d1  <= 1'b0;
        pixel_valid_d2  <= 1'b0;
        pixel_out       <= 8'd0;
        pixel_valid_out <= 1'b0;
    end else begin
        // 第1级流水线：卷积计算
        conv_result    <= conv_sum[11:4];  // 除以16（右移4位）
        pixel_valid_d1 <= (pixel_valid_in && (line_valid >= 2'd2));
        
        // 第2级流水线：输出
        pixel_out       <= conv_result;
        pixel_valid_out <= pixel_valid_d1;
    end
end

endmodule

