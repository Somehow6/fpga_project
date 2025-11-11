//****************************************Copyright (c)***********************************//
// 像素放大模块
// 功能：将28×28二值图像放大10倍显示为280×280
// 使用最近邻插值算法
//****************************************************************************************//

module pixel_scaler(
    input                 clk            ,  // 时钟
    input                 rst_n          ,  // 复位信号
    
    // 输入：显示坐标（右半屏内的相对坐标）
    input      [10:0]     display_x      ,  // 显示X坐标 (0~511)
    input      [10:0]     display_y      ,  // 显示Y坐标 (0~767)
    input                 display_valid  ,  // 坐标有效信号
    
    // 输入：28×28缓存读取接口
    output reg [4:0]      buf_rd_x       ,  // 缓存读X坐标 (0~27)
    output reg [4:0]      buf_rd_y       ,  // 缓存读Y坐标 (0~27)
    input                 buf_rd_data    ,  // 缓存读数据（1bit）
    
    // 输出：放大后的像素
    output reg            scaled_pixel   ,  // 放大后的像素（0或1）
    output reg            scaled_valid      // 输出有效信号
);

//==============================================================================
// 参数定义
//==============================================================================
localparam SCALE_FACTOR = 4'd10;       // 放大倍数
localparam IMG_SIZE     = 5'd28;       // 原图尺寸
localparam SCALED_SIZE  = 9'd280;      // 放大后尺寸 (28×10)

// 居中显示位置计算
// 右半屏：512×768
// 280×280居中：X_offset=(512-280)/2=116, Y_offset=(768-280)/2=244
localparam X_OFFSET = 11'd116;
localparam Y_OFFSET = 11'd244;

//==============================================================================
// 坐标转换
// 1. 判断是否在显示区域内
// 2. 计算原图坐标（除以10）
//==============================================================================
wire in_display_area;
wire [10:0] rel_x, rel_y;  // 相对于显示区域的坐标

assign rel_x = display_x - X_OFFSET;
assign rel_y = display_y - Y_OFFSET;

assign in_display_area = (display_x >= X_OFFSET) && (display_x < X_OFFSET + SCALED_SIZE) &&
                         (display_y >= Y_OFFSET) && (display_y < Y_OFFSET + SCALED_SIZE);

//==============================================================================
// 坐标映射：除以10（使用移位近似）
// 10 ≈ 8 + 2，但这里直接用除法更准确
// 实际实现：使用查找表或简化计算
//==============================================================================
wire [4:0] src_x, src_y;

// 简化：使用右移和减法近似除以10
// x/10 ≈ (x×26)>>8 或使用专用除法器
// 这里为清晰起见，使用除法（综合工具会优化）
assign src_x = rel_x / SCALE_FACTOR;
assign src_y = rel_y / SCALE_FACTOR;

//==============================================================================
// 输出逻辑（添加流水线）
//==============================================================================
reg in_area_d1;
reg [4:0] src_x_d1, src_y_d1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf_rd_x     <= 5'd0;
        buf_rd_y     <= 5'd0;
        in_area_d1   <= 1'b0;
        src_x_d1     <= 5'd0;
        src_y_d1     <= 5'd0;
        scaled_pixel <= 1'b0;
        scaled_valid <= 1'b0;
    end else begin
        // 第1级流水线：计算源坐标并发起读请求
        if (display_valid) begin
            if (in_display_area) begin
                buf_rd_x   <= (src_x < IMG_SIZE) ? src_x : (IMG_SIZE - 1);
                buf_rd_y   <= (src_y < IMG_SIZE) ? src_y : (IMG_SIZE - 1);
                in_area_d1 <= 1'b1;
                src_x_d1   <= src_x;
                src_y_d1   <= src_y;
            end else begin
                in_area_d1 <= 1'b0;
            end
        end else begin
            in_area_d1 <= 1'b0;
        end
        
        // 第2级流水线：读取数据并输出
        if (in_area_d1) begin
            scaled_pixel <= buf_rd_data;
            scaled_valid <= 1'b1;
        end else begin
            scaled_pixel <= 1'b0;  // 区域外显示黑色
            scaled_valid <= 1'b0;
        end
    end
end

endmodule

