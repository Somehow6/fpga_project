//****************************************Copyright (c)***********************************//
// 视频混合器模块
// 功能：将左右两路视频流混合输出到HDMI
// 左半屏(0-511)：原图 + OSD红框
// 右半屏(512-1023)：预处理结果显示
//****************************************************************************************//

module video_mixer(
    input                 pixel_clk      ,  // 像素时钟 (65MHz)
    input                 rst_n          ,  // 复位信号
    
    // 当前像素坐标
    input      [10:0]     pixel_x        ,  // 0-1023
    input      [10:0]     pixel_y        ,  // 0-767
    
    // 左半屏输入 (原图+OSD)
    input      [15:0]     left_pixel     ,  // RGB565像素
    input                 left_valid     ,  // 左路数据有效
    
    // 右半屏输入 (处理结果)
    input      [15:0]     right_pixel    ,  // RGB565像素
    input                 right_valid    ,  // 右路数据有效
    
    // 混合输出
    output reg [15:0]     mixed_pixel    ,  // 混合后的RGB565像素
    output reg            mixed_valid       // 输出有效信号
);

//==============================================================================
// 参数定义
//==============================================================================
localparam SCREEN_WIDTH  = 11'd1024;  // 屏幕宽度
localparam SPLIT_X       = 11'd512;   // 分屏位置

//==============================================================================
// 视频混合逻辑
//==============================================================================
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        mixed_pixel <= 16'h0000;
        mixed_valid <= 1'b0;
    end else begin
        // 根据X坐标选择左右路
        if (pixel_x < SPLIT_X) begin
            // 左半屏：显示原图
            mixed_pixel <= left_pixel;
            mixed_valid <= left_valid;
        end else begin
            // 右半屏：显示处理结果
            mixed_pixel <= right_pixel;
            mixed_valid <= right_valid;
        end
    end
end

endmodule

