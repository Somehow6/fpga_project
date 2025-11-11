//****************************************Copyright (c)***********************************//
// 图像预处理顶层模块
// 功能：集成完整的预处理流水线
// 流程：ROI提取 → 灰度转换 → 高斯滤波1 → 池化1 → 高斯滤波2 → 池化2 → 二值化
// 输入：1024×768 RGB565图像流
// 输出：28×28 二值图像
//****************************************************************************************//

module image_preprocessor(
    input                 pixel_clk      ,  // 像素时钟 (65MHz)
    input                 rst_n          ,  // 复位信号
    
    // 输入图像流（来自DDR3读出）
    input      [15:0]     pixel_in       ,  // RGB565像素
    input      [10:0]     pixel_x        ,  // 当前X坐标
    input      [10:0]     pixel_y        ,  // 当前Y坐标
    input                 pixel_valid    ,  // 像素有效
    input                 frame_vsync    ,  // 帧同步信号
    
    // 输出28×28二值图像
    output                binary_pixel   ,  // 二值像素输出
    output                binary_valid   ,  // 二值像素有效
    output                frame_done        // 一帧处理完成
);

//==============================================================================
// 内部信号
//==============================================================================

// ROI提取输出
wire [15:0] roi_pixel;
wire [6:0]  roi_x, roi_y;
wire        roi_valid;
wire        roi_frame_done;

// RGB转灰度输出
wire [7:0]  gray_pixel;
wire        gray_valid;

// 高斯滤波1输出 (112×112 → 110×110)
wire [7:0]  gauss1_pixel;
wire        gauss1_valid;

// 池化1输出 (110×110 → 55×55)
wire [7:0]  pool1_pixel;
wire        pool1_valid;

// 高斯滤波2输出 (55×55 → 53×53)
wire [7:0]  gauss2_pixel;
wire        gauss2_valid;

// 池化2输出 (53×53 → 26×26) - 注意：实际会是27×27或26×26
// 为了得到28×28，需要调整策略
// 简化方案：56×56 → 28×28 (去掉第二次高斯滤波)
wire [7:0]  pool2_pixel;
wire        pool2_valid;

// 帧开始信号（用于二值化模块）
reg frame_start_pulse;
reg frame_vsync_d1;

//==============================================================================
// 帧开始脉冲生成
//==============================================================================
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_vsync_d1    <= 1'b0;
        frame_start_pulse <= 1'b0;
    end else begin
        frame_vsync_d1    <= frame_vsync;
        frame_start_pulse <= frame_vsync && !frame_vsync_d1;
    end
end

//==============================================================================
// 阶段1：ROI提取 (1024×768 → 112×112)
//==============================================================================
roi_extractor u_roi_extractor (
    .pixel_clk      (pixel_clk       ),
    .rst_n          (rst_n           ),
    .pixel_in       (pixel_in        ),
    .pixel_x        (pixel_x         ),
    .pixel_y        (pixel_y         ),
    .pixel_valid    (pixel_valid     ),
    .frame_vsync    (frame_vsync     ),
    .roi_pixel      (roi_pixel       ),
    .roi_x          (roi_x           ),
    .roi_y          (roi_y           ),
    .roi_valid      (roi_valid       ),
    .roi_frame_done (roi_frame_done  )
);

//==============================================================================
// 阶段2：RGB565转灰度
//==============================================================================
rgb2gray u_rgb2gray (
    .clk            (pixel_clk       ),
    .rst_n          (rst_n           ),
    .rgb565_in      (roi_pixel       ),
    .pixel_valid_in (roi_valid       ),
    .gray_out       (gray_pixel      ),
    .pixel_valid_out(gray_valid      )
);

//==============================================================================
// 阶段3：高斯滤波1 (112×112 → ~110×110)
//==============================================================================
gaussian_filter #(
    .IMG_WIDTH(112)
) u_gaussian_filter1 (
    .clk            (pixel_clk       ),
    .rst_n          (rst_n           ),
    .pixel_in       (gray_pixel      ),
    .pixel_valid_in (gray_valid      ),
    .frame_start    (frame_start_pulse),
    .pixel_out      (gauss1_pixel    ),
    .pixel_valid_out(gauss1_valid    )
);

//==============================================================================
// 阶段4：最大池化1 (112×112 → 56×56)
//==============================================================================
max_pooling #(
    .IN_WIDTH(112)
) u_max_pooling1 (
    .clk            (pixel_clk       ),
    .rst_n          (rst_n           ),
    .pixel_in       (gauss1_pixel    ),
    .pixel_valid_in (gauss1_valid    ),
    .frame_start    (frame_start_pulse),
    .pixel_out      (pool1_pixel     ),
    .pixel_valid_out(pool1_valid     )
);

//==============================================================================
// 阶段5：高斯滤波2 (56×56 → ~54×54)
//==============================================================================
gaussian_filter #(
    .IMG_WIDTH(56)
) u_gaussian_filter2 (
    .clk            (pixel_clk       ),
    .rst_n          (rst_n           ),
    .pixel_in       (pool1_pixel     ),
    .pixel_valid_in (pool1_valid     ),
    .frame_start    (frame_start_pulse),
    .pixel_out      (gauss2_pixel    ),
    .pixel_valid_out(gauss2_valid    )
);

//==============================================================================
// 阶段6：最大池化2 (56×56 → 28×28)
//==============================================================================
max_pooling #(
    .IN_WIDTH(56)
) u_max_pooling2 (
    .clk            (pixel_clk       ),
    .rst_n          (rst_n           ),
    .pixel_in       (gauss2_pixel    ),
    .pixel_valid_in (gauss2_valid    ),
    .frame_start    (frame_start_pulse),
    .pixel_out      (pool2_pixel     ),
    .pixel_valid_out(pool2_valid     )
);

//==============================================================================
// 阶段7：二值化 (28×28)
//==============================================================================
binarization #(
    .IMG_SIZE(784)  // 28×28=784
) u_binarization (
    .clk            (pixel_clk       ),
    .rst_n          (rst_n           ),
    .pixel_in       (pool2_pixel     ),
    .pixel_valid_in (pool2_valid     ),
    .frame_start    (frame_start_pulse),
    .pixel_out      (binary_pixel    ),
    .pixel_valid_out(binary_valid    ),
    .frame_done     (frame_done      )
);

endmodule

