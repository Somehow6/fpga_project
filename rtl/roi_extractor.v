//****************************************Copyright (c)***********************************//
// ROI区域提取模块
// 功能：从1024×768图像中提取112×112的中心区域
// 输入：像素流 + 坐标
// 输出：ROI区域像素流
//****************************************************************************************//

module roi_extractor(
    input                 pixel_clk      ,  // 像素时钟
    input                 rst_n          ,  // 复位信号
    
    // 输入像素流
    input      [15:0]     pixel_in       ,  // RGB565输入像素
    input      [10:0]     pixel_x        ,  // 当前X坐标 (0-1023)
    input      [10:0]     pixel_y        ,  // 当前Y坐标 (0-767)
    input                 pixel_valid    ,  // 像素有效信号
    input                 frame_vsync    ,  // 帧同步信号
    
    // ROI输出像素流
    output reg [15:0]     roi_pixel      ,  // ROI区域像素
    output reg [6:0]      roi_x          ,  // ROI内部X坐标 (0-111)
    output reg [6:0]      roi_y          ,  // ROI内部Y坐标 (0-111)
    output reg            roi_valid      ,  // ROI像素有效
    output reg            roi_frame_done    // ROI一帧完成标志
);

//==============================================================================
// 参数定义 - ROI区域
//==============================================================================
localparam ROI_X_MIN = 11'd456;  // ROI左边界 (512-56)
localparam ROI_X_MAX = 11'd567;  // ROI右边界 (512+55)
localparam ROI_Y_MIN = 11'd328;  // ROI上边界 (384-56)
localparam ROI_Y_MAX = 11'd439;  // ROI下边界 (384+55)
localparam ROI_WIDTH  = 7'd112;  // ROI宽度
localparam ROI_HEIGHT = 7'd112;  // ROI高度

//==============================================================================
// 内部信号
//==============================================================================
reg in_roi_region;       // 当前像素是否在ROI区域内
reg roi_frame_active;    // ROI帧活动标志
reg [6:0] roi_x_cnt;     // ROI X计数器
reg [6:0] roi_y_cnt;     // ROI Y计数器

//==============================================================================
// 帧同步信号处理
//==============================================================================
reg frame_vsync_d1;
wire frame_start;

always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_vsync_d1 <= 1'b0;
    end else begin
        frame_vsync_d1 <= frame_vsync;
    end
end

assign frame_start = frame_vsync && !frame_vsync_d1;  // 帧开始上升沿

//==============================================================================
// ROI区域检测与计数
//==============================================================================
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        in_roi_region   <= 1'b0;
        roi_x_cnt       <= 7'd0;
        roi_y_cnt       <= 7'd0;
        roi_frame_active <= 1'b0;
        roi_frame_done  <= 1'b0;
    end else begin
        // 帧开始时复位
        if (frame_start) begin
            roi_frame_active <= 1'b0;
            roi_frame_done   <= 1'b0;
            roi_x_cnt        <= 7'd0;
            roi_y_cnt        <= 7'd0;
        end
        
        // 检测是否在ROI区域内
        if (pixel_valid) begin
            if ((pixel_x >= ROI_X_MIN) && (pixel_x <= ROI_X_MAX) &&
                (pixel_y >= ROI_Y_MIN) && (pixel_y <= ROI_Y_MAX)) begin
                in_roi_region <= 1'b1;
                roi_frame_active <= 1'b1;
                
                // 计算ROI内部坐标
                roi_x_cnt <= pixel_x - ROI_X_MIN;
                roi_y_cnt <= pixel_y - ROI_Y_MIN;
                
                // 检测ROI帧完成（最后一个像素）
                if ((pixel_x == ROI_X_MAX) && (pixel_y == ROI_Y_MAX)) begin
                    roi_frame_done <= 1'b1;
                end else begin
                    roi_frame_done <= 1'b0;
                end
            end else begin
                in_roi_region <= 1'b0;
                roi_frame_done <= 1'b0;
            end
        end else begin
            in_roi_region <= 1'b0;
            roi_frame_done <= 1'b0;
        end
    end
end

//==============================================================================
// ROI输出逻辑
//==============================================================================
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        roi_pixel <= 16'h0000;
        roi_x     <= 7'd0;
        roi_y     <= 7'd0;
        roi_valid <= 1'b0;
    end else begin
        if (in_roi_region && pixel_valid) begin
            roi_pixel <= pixel_in;
            roi_x     <= roi_x_cnt;
            roi_y     <= roi_y_cnt;
            roi_valid <= 1'b1;
        end else begin
            roi_pixel <= 16'h0000;
            roi_valid <= 1'b0;
        end
    end
end

endmodule

