//****************************************Copyright (c)***********************************//
// OSD矩形框绘制模块
// 功能：在原图上叠加红色ROI边框
// ROI区域：112×112像素，中心位置(512, 384)
// 边框范围：x∈[456,567], y∈[328,439]
//****************************************************************************************//

module osd_rectangle(
    input                 pixel_clk      ,  // 像素时钟（保留未用，便于接口统一）
    input                 rst_n          ,  // 复位信号（未用）
    
    // 当前像素坐标
    input      [10:0]     pixel_x        ,  // 当前X坐标 (0-1023)
    input      [10:0]     pixel_y        ,  // 当前Y坐标 (0-767)
    
    // 输入像素
    input      [15:0]     pixel_in       ,  // RGB565输入像素
    input                 pixel_valid_in ,  // 输入有效信号
    
    // 输出像素（叠加红框后）
    output     [15:0]     pixel_out      ,  // RGB565输出像素（组合）
    output                pixel_valid_out   // 输出有效信号（直通）
);

//==============================================================================
// 参数定义 - ROI区域
//==============================================================================
// ROI中心：(512, 384)
// ROI尺寸：112×112
// ROI左上角：(456, 328) = (512-56, 384-56)
// ROI右下角：(567, 439) = (512+55, 384+55)
localparam ROI_X_MIN = 11'd456;  // ROI左边界
localparam ROI_X_MAX = 11'd567;  // ROI右边界
localparam ROI_Y_MIN = 11'd328;  // ROI上边界
localparam ROI_Y_MAX = 11'd439;  // ROI下边界
localparam BORDER_WIDTH = 2'd2;  // 边框宽度（像素）

// 红色（RGB565格式：5位R, 6位G, 5位B）
localparam RED_COLOR = 16'hF800;  // 最大红色：11111_000000_00000

//==============================================================================
// 边框检测逻辑（组合）
//==============================================================================
wire in_roi_region;      // 是否在ROI区域内
wire is_border;          // 是否在边框上

// 判断是否在ROI矩形内部
assign in_roi_region = (pixel_x >= ROI_X_MIN) && (pixel_x <= ROI_X_MAX) &&
                       (pixel_y >= ROI_Y_MIN) && (pixel_y <= ROI_Y_MAX);

// 判断是否在边框上（外边界或内边界的BORDER_WIDTH像素范围内）
assign is_border = in_roi_region && (
    // 左边框
    (pixel_x >= ROI_X_MIN && pixel_x < ROI_X_MIN + BORDER_WIDTH) ||
    // 右边框
    (pixel_x > ROI_X_MAX - BORDER_WIDTH && pixel_x <= ROI_X_MAX) ||
    // 上边框
    (pixel_y >= ROI_Y_MIN && pixel_y < ROI_Y_MIN + BORDER_WIDTH) ||
    // 下边框
    (pixel_y > ROI_Y_MAX - BORDER_WIDTH && pixel_y <= ROI_Y_MAX)
);

//==============================================================================
// 像素输出（组合）
//==============================================================================
assign pixel_out      = is_border ? RED_COLOR : pixel_in;
assign pixel_valid_out= pixel_valid_in;  // 直通

endmodule

