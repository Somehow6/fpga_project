//****************************************Copyright (c)***********************************//
// 右半屏布局生成模块
// 功能：生成右半屏显示内容（背景+放大的28×28图像）
// 布局：深灰色背景 + 中心280×280放大图像
//****************************************************************************************//

module right_panel_gen(
    input                 pixel_clk      ,  // 像素时钟
    input                 rst_n          ,  // 复位信号
    
    // 输入：当前像素坐标（右半屏内的相对坐标）
    input      [10:0]     pixel_x        ,  // X坐标 (0~511，相对于右半屏)
    input      [10:0]     pixel_y        ,  // Y坐标 (0~767)
    input                 pixel_valid    ,  // 坐标有效信号
    
    // 输入：28×28图像缓存接口
    input                 binary_pixel   ,  // 二值像素（来自pixel_scaler）
    input                 binary_valid   ,  // 二值像素有效
    
    // 输出：右半屏像素
    output reg [15:0]     panel_pixel    ,  // RGB565像素
    output reg            panel_valid       // 输出有效信号
);

//==============================================================================
// 颜色定义（RGB565格式）
//==============================================================================
localparam COLOR_BG_DARK   = 16'h2104;  // 深灰色背景：RGB(32,32,32)
localparam COLOR_WHITE     = 16'hFFFF;  // 白色（二值图像的1）
localparam COLOR_BLACK     = 16'h0000;  // 黑色（二值图像的0）

//==============================================================================
// 显示区域定义
// 280×280图像居中显示在512×768区域
// X_offset = (512-280)/2 = 116
// Y_offset = (768-280)/2 = 244
//==============================================================================
localparam IMG_X_START = 11'd116;
localparam IMG_X_END   = 11'd395;  // 116+280-1
localparam IMG_Y_START = 11'd244;
localparam IMG_Y_END   = 11'd523;  // 244+280-1

//==============================================================================
// 区域判断
//==============================================================================
wire in_image_area;

assign in_image_area = (pixel_x >= IMG_X_START) && (pixel_x <= IMG_X_END) &&
                       (pixel_y >= IMG_Y_START) && (pixel_y <= IMG_Y_END);

//==============================================================================
// 像素输出逻辑
//==============================================================================
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        panel_pixel <= COLOR_BG_DARK;
        panel_valid <= 1'b0;
    end else begin
        if (pixel_valid) begin
            if (in_image_area && binary_valid) begin
                // 图像区域：根据二值像素输出黑白
                panel_pixel <= binary_pixel ? COLOR_WHITE : COLOR_BLACK;
            end else begin
                // 背景区域：深灰色
                panel_pixel <= COLOR_BG_DARK;
            end
            panel_valid <= 1'b1;
        end else begin
            panel_valid <= 1'b0;
        end
    end
end

endmodule

