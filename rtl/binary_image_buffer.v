//****************************************Copyright (c)***********************************//
// 28×28二值图像缓存模块
// 功能：存储28×28=784bit二值图像，供HDMI显示读取
// 使用BRAM实现双端口访问
//****************************************************************************************//

module binary_image_buffer(
    input                 clk            ,  // 时钟
    input                 rst_n          ,  // 复位信号
    
    // 写端口（预处理结果输入）
    input                 wr_en          ,  // 写使能
    input      [9:0]      wr_addr        ,  // 写地址 (0~783)
    input                 wr_data        ,  // 写数据（1bit）
    input                 wr_frame_done  ,  // 写入一帧完成
    
    // 读端口（HDMI显示读取）
    input      [4:0]      rd_x           ,  // 读X坐标 (0~27)
    input      [4:0]      rd_y           ,  // 读Y坐标 (0~27)
    output reg            rd_data           // 读数据（1bit）
);

//==============================================================================
// BRAM存储（784bit = 98字节）
// 使用字节寻址，每个字节存储8个像素
//==============================================================================
reg [7:0] image_mem [0:97];  // 98个字节，存储784bit

//==============================================================================
// 写地址计算
//==============================================================================
wire [6:0] wr_byte_addr;  // 字节地址 (0~97)
wire [2:0] wr_bit_pos;    // 字节内位位置 (0~7)

assign wr_byte_addr = wr_addr[9:3];  // 除以8
assign wr_bit_pos   = wr_addr[2:0];  // 模8

//==============================================================================
// 写入逻辑
//==============================================================================
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 98; i = i + 1) begin
            image_mem[i] <= 8'h00;
        end
    end else begin
        if (wr_en) begin
            // 更新对应位
            if (wr_data) begin
                image_mem[wr_byte_addr][wr_bit_pos] <= 1'b1;
            end else begin
                image_mem[wr_byte_addr][wr_bit_pos] <= 1'b0;
            end
        end
    end
end

//==============================================================================
// 读地址计算
//==============================================================================
wire [9:0] rd_addr;        // 线性地址
wire [6:0] rd_byte_addr;   // 字节地址
wire [2:0] rd_bit_pos;     // 位位置

assign rd_addr      = rd_y * 5'd28 + rd_x;  // y×28+x
assign rd_byte_addr = rd_addr[9:3];
assign rd_bit_pos   = rd_addr[2:0];

//==============================================================================
// 读取逻辑
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_data <= 1'b0;
    end else begin
        // 从BRAM读取对应位
        rd_data <= image_mem[rd_byte_addr][rd_bit_pos];
    end
end

endmodule

