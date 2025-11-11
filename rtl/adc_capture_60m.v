//****************************************Copyright (c)***********************************//
// File name:           adc_capture_60m
// Last modified Date:  2025/11/08
// Last Version:        V5.0 (Parametric divider: 2MHz / 20MHz / 60MHz)
// Descriptions:        12-bit single channel ADC data capture module (CH2)
//                      使用60MHz统一时钟域，参数化分频：
//                        - DIV_N=30 → 2MHz
//                        - DIV_N=3  → 20MHz
//                        - DIV_N=1  → 60MHz直通
//                      Data rate: Fs × 2 bytes/sample
//
//                      **核心优势**: 
//                      - 单时钟域，无CDC时序问题
//                      - 可在2MHz/20MHz/60MHz之间切换
//                      - data_valid默认3个60MHz周期，捕获窗口稳定
//                      - 逻辑简洁，可靠性高
//
//                      **DEBUG MODE**: Set adc_test_mode = 1 to replace ADC data with
//                      test counter, keeping all timing logic intact for debugging
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module adc_capture_60m#(
    // 分频参数：DIV_N=30(2MHz) / 3(20MHz) / 1(直通60MHz)
    parameter integer DIV_N = 30,
    // data_valid 脉宽（单位：clk_60m周期，推荐=3）
    parameter integer VALID_PULSE_CYCLES = 3
)(
    input                clk_60m       ,  // 60MHz system clock (from FT232H)
    input                rst_n         ,  // System reset (active low)
    input                adc_test_mode ,  // Test mode: 1=counter, 0=real ADC
    // ADC interface
    input       [11:0]   adc_data      ,  // 12-bit ADC data input (D0-D11)
    input                adc_otr       ,  // ADC over-range indicator
    output               adc_clk       ,  // ADC chip clock output (2MHz)
    // Data output interface
    output  reg [11:0]   capture_data  ,  // Captured 12-bit data
    output  reg          data_valid    ,  // Data valid flag (3 cycles wide, 180ns)
    output  reg          otr_flag         // Over-range flag
);

//==============================================================================
// Clock Divider (Parametric)
// Counter cycles: 0 .. (DIV_N-1) -> 0 ...
// ADC clock high when cnt >= HALF_N (近似50%占空比；DIV_N==1时直通)
//==============================================================================
reg [15:0] clk_div_cnt  ;  // Clock divider counter (supports large DIV_N)
reg [11:0] test_counter ;  // Test counter for debug mode (0-4095, 12-bit)
wire       clk_div      ;  // Divided/forwarded clock

// Elaborated-time constants
localparam integer HALF_N   = (DIV_N>>1);
localparam integer V0_IDX   = (DIV_N==1) ? 0 : HALF_N;
localparam integer V1_IDX   = (DIV_N==1) ? 0 : ((HALF_N + 1) % DIV_N);
localparam integer V2_IDX   = (DIV_N==1) ? 0 : ((HALF_N + 2) % DIV_N);
localparam integer CAP_IDX  = (DIV_N==1) ? 0 : ((HALF_N + DIV_N - 1) % DIV_N); // rising-edge-1
// For DIV_N==2 (30MHz): sample on next clk after adc_clk posedge -> use HALF_N
localparam integer SAMPLE_IDX = (DIV_N==2) ? HALF_N : CAP_IDX;
localparam integer INCR_IDX = (DIV_N==1) ? 0 : ((HALF_N + 4) % DIV_N);         // after valid

//*****************************************************
//**                    main code
//*****************************************************

//==============================================================================
// Clock divider counter
// 0 .. DIV_N-1
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n)
        clk_div_cnt <= 16'd0;
    else if (clk_div_cnt == (DIV_N-1))
        clk_div_cnt <= 16'd0;
    else
        clk_div_cnt <= clk_div_cnt + 16'd1;
end

//==============================================================================
// Generate ADC clock
// DIV_N==1: forward 60MHz directly; else: divided clock with ~50% duty
//==============================================================================
assign clk_div = (clk_div_cnt >= HALF_N) ? 1'b1 : 1'b0;
assign adc_clk = (DIV_N==1) ? clk_60m : clk_div;

//==============================================================================
// Test Counter: Increments AFTER capturing
// Increment at INCR_IDX (during adc_clk high phase, after data_valid ends)
// This ensures stable data when data_valid is asserted
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n)
        test_counter <= 12'd0;
    else if (adc_test_mode && (clk_div_cnt == INCR_IDX))
        test_counter <= test_counter + 12'd1;
end

//==============================================================================
// Data capture logic with EXTENDED data_valid (parametric)
//
// 通用（DIV_N>=3）：
//   - 在 CAP_IDX (=HALF_N-1) 采样数据（上升沿前一个计数，保证建立时间）
//   - data_valid 在 V0_IDX/V1_IDX/V2_IDX 三个计数为高（默认3拍）
// DIV_N==1（直通60MHz）：
//   - 在 negedge clk_60m 采样数据（与ADC在posedge更新错相半拍，提升时序裕量）
//   - data_valid 每拍为高（每拍有效）
//==============================================================================
// data_valid 生成（沿用posedge）
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        data_valid <= 1'b0;
    end else begin
        if (DIV_N==1) begin
            data_valid <= 1'b1;                   // 每拍有效（直通）
        end else begin
            if ((clk_div_cnt == V0_IDX) ||
                ((VALID_PULSE_CYCLES > 1) && (clk_div_cnt == V1_IDX)) ||
                ((VALID_PULSE_CYCLES > 2) && (clk_div_cnt == V2_IDX)))
                data_valid <= 1'b1;
            else
                data_valid <= 1'b0;
        end
    end
end

// 采样数据与OTR：根据DIV_N用generate区分时序
generate
if (DIV_N==1) begin : g_cap_negedge_60m
    // 60MHz直通：在negedge采样，避开ADC在posedge更新的边沿
    always @(negedge clk_60m or negedge rst_n) begin
        if (!rst_n) begin
            capture_data <= 12'd0;
            otr_flag     <= 1'b0;
        end else begin
            if (adc_test_mode)
                capture_data <= test_counter;     // TEST: stable
            else
                capture_data <= adc_data;         // NORMAL: real ADC data
            otr_flag <= adc_otr;
        end
    end
end else begin : g_cap_posedge_div
    // 分频模式：按计数点在posedge采样
    always @(posedge clk_60m or negedge rst_n) begin
        if (!rst_n) begin
            capture_data <= 12'd0;
            otr_flag     <= 1'b0;
        end else begin
            if (clk_div_cnt == SAMPLE_IDX) begin
                if (adc_test_mode)
                    capture_data <= test_counter;     // TEST: stable
                else
                    capture_data <= adc_data;         // NORMAL: real ADC data
                otr_flag <= adc_otr;
            end
        end
    end
end
endgenerate

endmodule


