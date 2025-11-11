//****************************************Copyright (c)***********************************//
// 最大池化模块
// 功能：2×2最大池化（降采样）
// 输入：N×N图像
// 输出：(N/2)×(N/2)图像
// 使用行缓冲实现流式处理
//****************************************************************************************//

module max_pooling #(
    parameter IN_WIDTH = 112  // 输入图像宽度（可配置：112或56）
)(
    input                 clk            ,  // 时钟
    input                 rst_n          ,  // 复位信号
    
    // 输入像素流
    input      [7:0]      pixel_in       ,  // 输入灰度像素
    input                 pixel_valid_in ,  // 输入有效信号
    input                 frame_start    ,  // 帧开始信号
    
    // 输出池化后的像素
    output reg [7:0]      pixel_out      ,  // 输出灰度像素
    output reg            pixel_valid_out   // 输出有效信号
);

//==============================================================================
// 参数计算
//==============================================================================
localparam OUT_WIDTH = IN_WIDTH / 2;  // 输出宽度 = 输入宽度 / 2

//==============================================================================
// 行缓冲 - 存储前一行数据
//==============================================================================
reg [7:0] line_buf [0:IN_WIDTH-1];  // 前一行缓冲

//==============================================================================
// 计数器
//==============================================================================
reg [7:0] col_cnt;      // 输入列计数器 (0~IN_WIDTH-1)
reg [7:0] row_cnt;      // 输入行计数器
reg       row_even;     // 当前行是否为偶数行（0,2,4...）
reg       col_even;     // 当前列是否为偶数列（0,2,4...）

//==============================================================================
// 2×2窗口数据
//==============================================================================
reg [7:0] win00;  // 上一行，前一列
reg [7:0] win01;  // 上一行，当前列
reg [7:0] win10;  // 当前行，前一列
reg [7:0] win11;  // 当前行，当前列

//==============================================================================
// 帧开始处理
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        col_cnt  <= 8'd0;
        row_cnt  <= 8'd0;
        row_even <= 1'b1;  // 第0行为偶数行
    end else begin
        if (frame_start) begin
            col_cnt  <= 8'd0;
            row_cnt  <= 8'd0;
            row_even <= 1'b1;
        end else if (pixel_valid_in) begin
            // 列计数
            if (col_cnt == IN_WIDTH - 1) begin
                col_cnt  <= 8'd0;
                row_cnt  <= row_cnt + 8'd1;
                row_even <= ~row_even;  // 切换奇偶行
            end else begin
                col_cnt <= col_cnt + 8'd1;
            end
        end
    end
end

// 列奇偶判断
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        col_even <= 1'b1;
    end else begin
        if (frame_start || col_cnt == IN_WIDTH - 1) begin
            col_even <= 1'b1;  // 行首为偶数列
        end else if (pixel_valid_in) begin
            col_even <= ~col_even;
        end
    end
end

//==============================================================================
// 行缓冲更新与窗口数据提取
//==============================================================================
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < IN_WIDTH; i = i + 1) begin
            line_buf[i] <= 8'd0;
        end
        win00 <= 8'd0;
        win01 <= 8'd0;
        win10 <= 8'd0;
        win11 <= 8'd0;
    end else begin
        if (pixel_valid_in) begin
            // 行结束时，更新行缓冲
            if (col_cnt == IN_WIDTH - 1) begin
                // 注意：这里在行结束时才整体更新，实际应该逐像素更新
                // 为了简化，使用另一种方式
            end
            
            // 构建2×2窗口
            win00 <= line_buf[col_cnt];     // 上一行，当前列
            win01 <= line_buf[col_cnt];     // 上一行，当前列（暂存）
            win10 <= (col_cnt > 0) ? line_buf[col_cnt-1] : line_buf[0];  // 临时
            win11 <= pixel_in;               // 当前行，当前列
            
            // 更新行缓冲
            line_buf[col_cnt] <= pixel_in;
        end
    end
end

//==============================================================================
// 更简洁的实现：使用状态机
//==============================================================================
reg [7:0] pixel_buf [0:1];  // 缓存当前行的2个像素
reg       buf_valid;        // 缓存有效标志
reg [7:0] line_pixel_prev;  // 上一行前一个像素

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_buf[0]    <= 8'd0;
        pixel_buf[1]    <= 8'd0;
        buf_valid       <= 1'b0;
        line_pixel_prev <= 8'd0;
    end else begin
        if (frame_start) begin
            buf_valid <= 1'b0;
        end else if (pixel_valid_in) begin
            if (!col_even) begin
                // 奇数列：缓存当前像素
                pixel_buf[1] <= pixel_in;
                buf_valid    <= 1'b1;
            end else begin
                // 偶数列：保存到buf[0]
                pixel_buf[0] <= pixel_in;
                buf_valid    <= 1'b0;
            end
        end
    end
end

//==============================================================================
// 最大值计算
// 在偶数行的奇数列时，计算2×2窗口的最大值
//==============================================================================
wire [7:0] max_01, max_23, max_final;
reg [7:0] pool_result;
reg pool_valid;

// 第一级：比较上下两对
assign max_01 = (line_buf[col_cnt-1] > line_buf[col_cnt]) ? line_buf[col_cnt-1] : line_buf[col_cnt];
assign max_23 = (pixel_buf[0] > pixel_buf[1]) ? pixel_buf[0] : pixel_buf[1];

// 第二级：比较两组的最大值
assign max_final = (max_01 > max_23) ? max_01 : max_23;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pool_result     <= 8'd0;
        pool_valid      <= 1'b0;
        pixel_out       <= 8'd0;
        pixel_valid_out <= 1'b0;
    end else begin
        // 在奇数列且为偶数行时输出（完成2×2窗口采集）
        if (pixel_valid_in && !col_even && !row_even && buf_valid) begin
            pool_result <= max_final;
            pool_valid  <= 1'b1;
        end else begin
            pool_valid <= 1'b0;
        end
        
        // 输出寄存器
        pixel_out       <= pool_result;
        pixel_valid_out <= pool_valid;
    end
end

endmodule

