//****************************************Copyright (c)***********************************//
// HDMI显示顶层模块（增强版）
// 功能：左右分屏显示
//   - 左半屏：原图 + OSD红框
//   - 右半屏：28×28二值图像放大显示
//****************************************************************************************//

module  hdmi_top(
    input           pixel_clk,
    input           pixel_clk_5x,    
    input           sys_rst_n,
   // HDMI接口
    output          tmds_clk_p,     // TMDS 时钟通道
    output          tmds_clk_n,
    output [2:0]    tmds_data_p,    // TMDS 数据通道
    output [2:0]    tmds_data_n,
    output          tmds_oen ,      // TMDS 输出使能
   // 用户接口（左半屏 - 原图）
    output          video_vs,       // HDMI场信号      
    output  [10:0]  pixel_xpos,     // 像素点横坐标
    output  [10:0]  pixel_ypos,     // 像素点纵坐标      
    input   [15:0]  data_in,        // 输入数据（来自DDR3）
    output          data_req,       // 数据请求信号
   // 28×28二值图像缓存接口（右半屏）
    input           binary_pixel,   // 二值像素输入
    input           binary_valid    // 二值像素有效
);

//==============================================================================
// 内部信号定义
//==============================================================================
wire          video_hs;
wire          video_de;
wire  [23:0]  video_rgb;
wire  [15:0]  video_rgb_565;

// OSD红框输出
wire [15:0]   left_pixel_osd;
wire          left_valid_osd;

// 右半屏显示信号
wire [10:0]   right_panel_x;
wire [10:0]   right_panel_y;
wire [15:0]   right_pixel;
wire          right_valid;

// 像素放大模块信号
wire [4:0]    buf_rd_x;
wire [4:0]    buf_rd_y;
wire          scaled_pixel;
wire          scaled_valid;

// 视频混合器输出
wire [15:0]   mixed_pixel;
wire          mixed_valid;

//==============================================================================
// 左半屏数据路径：原图 + OSD红框
//==============================================================================
osd_rectangle u_osd_rectangle (
    .pixel_clk      (pixel_clk      ),
    .rst_n          (sys_rst_n      ),
    .pixel_x        (pixel_xpos     ),
    .pixel_y        (pixel_ypos     ),
    .pixel_in       (data_in        ),
    .pixel_valid_in (data_req       ),
    .pixel_out      (left_pixel_osd ),
    .pixel_valid_out(left_valid_osd )
);

//==============================================================================
// 右半屏数据路径：28×28图像放大显示
//==============================================================================
// 计算右半屏的相对坐标
assign right_panel_x = (pixel_xpos >= 11'd512) ? (pixel_xpos - 11'd512) : 11'd0;
assign right_panel_y = pixel_ypos;

// 像素放大模块（28×28 → 280×280）
pixel_scaler u_pixel_scaler (
    .clk            (pixel_clk      ),
    .rst_n          (sys_rst_n      ),
    .display_x      (right_panel_x  ),
    .display_y      (right_panel_y  ),
    .display_valid  (data_req       ),
    .buf_rd_x       (buf_rd_x       ),
    .buf_rd_y       (buf_rd_y       ),
    .buf_rd_data    (binary_pixel   ),  // 直接连接输入的二值像素
    .scaled_pixel   (scaled_pixel   ),
    .scaled_valid   (scaled_valid   )
);

// 右半屏布局生成
right_panel_gen u_right_panel_gen (
    .pixel_clk      (pixel_clk      ),
    .rst_n          (sys_rst_n      ),
    .pixel_x        (right_panel_x  ),
    .pixel_y        (right_panel_y  ),
    .pixel_valid    (data_req       ),
    .binary_pixel   (scaled_pixel   ),
    .binary_valid   (scaled_valid   ),
    .panel_pixel    (right_pixel    ),
    .panel_valid    (right_valid    )
);

//==============================================================================
// 视频混合器：左右分屏合成
//==============================================================================
video_mixer u_video_mixer (
    .pixel_clk      (pixel_clk      ),
    .rst_n          (sys_rst_n      ),
    .pixel_x        (pixel_xpos     ),
    .pixel_y        (pixel_ypos     ),
    .left_pixel     (left_pixel_osd ),
    .left_valid     (left_valid_osd ),
    .right_pixel    (right_pixel    ),
    .right_valid    (right_valid    ),
    .mixed_pixel    (mixed_pixel    ),
    .mixed_valid    (mixed_valid    )
);

// 使用混合后的像素数据
assign video_rgb_565 = mixed_pixel;

//==============================================================================
// RGB565转RGB888（HDMI输出）
//==============================================================================
assign video_rgb = {video_rgb_565[15:11],3'b000,video_rgb_565[10:5],2'b00,
                    video_rgb_565[4:0],3'b000};  

//==============================================================================
// 视频驱动模块（生成时序信号）
//==============================================================================
video_driver u_video_driver(
    .pixel_clk      (pixel_clk      ),
    .sys_rst_n      (sys_rst_n      ),
    .video_hs       (video_hs       ),
    .video_vs       (video_vs       ),
    .video_de       (video_de       ),
    .video_rgb      (video_rgb_565  ),  // 内部使用，实际输出由混合器提供
    .data_req       (data_req       ),
    .pixel_xpos     (pixel_xpos     ),
    .pixel_ypos     (pixel_ypos     ),
    .pixel_data     (data_in        )  // 这个输出不再使用
);
       
//==============================================================================
// HDMI编码模块
//==============================================================================
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk      ),
    .pclk_x5        (pixel_clk_5x   ),
    .reset_n        (sys_rst_n      ),
    .video_din      (video_rgb      ),
    .video_hsync    (video_hs       ), 
    .video_vsync    (video_vs       ),
    .video_de       (video_de       ),
    .tmds_clk_p     (tmds_clk_p     ),
    .tmds_clk_n     (tmds_clk_n     ),
    .tmds_data_p    (tmds_data_p    ),
    .tmds_data_n    (tmds_data_n    ), 
    .tmds_oen       (tmds_oen       )
);

endmodule 