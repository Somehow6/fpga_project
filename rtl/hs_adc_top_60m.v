//****************************************Copyright (c)***********************************//
// File name:           hs_adc_top_60m
// Last modified Date:  2025/11/05
// Last Version:        V5.0 (FIFO版本 - 2MHz ADC采样)
// Descriptions:        12-bit single channel ADC top module - 60MHz统一时钟域+FIFO版本
//                      整合ADC采样、数据转换和FIFO缓冲
//                      处理3种测试模式（速率统一4 MB/s）：
//                        Mode 0: USB Test (8-bit counter, 4 MB/s, no header)
//                        Mode 1: ADC Test (12-bit test counter, 2MHz, with header)
//                        Mode 2: Normal (Real ADC 2MHz sampling, with header)
//
//                      **核心优势**: 
//                      - 单一60MHz时钟域，无CDC问题
//                      - 2MHz ADC采样，数据率4 MB/s（2MHz × 2字节）
//                      - 模式0/1/2速率完全匹配，便于对比测试
//                      - 同步FIFO解耦ADC和USB，无竞争条件
//                      - 状态机极简，易于调试
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module hs_adc_top_60m(
    input                clk_60m       ,  // 60MHz clock (from FT232H usb_clk_60m)
    input                rst_n         ,  // System reset (active low)
    input       [1:0]    test_mode     ,  // Test mode: 0=USB test, 1=ADC test, 2=Normal
    input       [3:0]    filter_level  ,  // Filter range level (0-9) from top module
    
    // CH2 ADC interface (12-bit single channel)
    input       [11:0]   ch2_data      ,  // CH2 ADC data input (D0-D11)
    input                ch2_otr       ,  // CH2 over-range indicator
    output               ch2_clk       ,  // CH2 ADC clock output (2MHz)
    
    // USB TX interface (FIFO read side)
    output      [7:0]    fifo_data_out ,  // FIFO read data to USB TX
    output               fifo_empty    ,  // FIFO empty flag to USB TX
    input                fifo_rd_en    ,  // FIFO read enable from USB TX
    
    // Debug/Status interface
    output               fifo_full     ,  // FIFO full flag for LED indicator
    
    // ADC data output for phase detector (filtered)
    output      [11:0]   adc_capture_data,  // Filtered ADC data (after adc_filter)
    output               adc_data_valid,     // Filtered ADC data valid flag
    
    // Phase data input (for USB transmission modes)
    input                key_phase_switch,   // Key[1] from top module (for data mode selection)
    input       [11:0]   phase_diff_12bit,   // 12-bit phase from phase_detector_v2 (0-4095 for 0-360 deg)
    input       [11:0]   adc_midpoint_in,    // Dynamic ADC midpoint from phase_detector_v2
    input       [15:0]   zero_cross_count_in,// Zero-crossing counter from phase_detector_v2
    input       [11:0]   adc_min_in,         // ADC minimum value from phase_detector_v2
    input       [11:0]   adc_max_in,         // ADC maximum value from phase_detector_v2
    input                phase_valid_in,     // Phase valid flag from phase_detector_v2 (kept for compatibility)
    input                phase_strobe_in,    // Phase strobe (1-cycle at zero-crossing) from phase_detector_v2
    input                phase_updated_in,   // Phase updated flag (pulse on zero-crossing)
    
    // Data mode output
    output      [1:0]    data_mode           // Data mode indicator (0=ADC, 1=Phase, 2=Debug)
);

//==============================================================================
// Internal Signals
//==============================================================================
// ADC capture outputs (raw, before filter)
wire [11:0] adc_raw_data       ;  // Raw data from adc_capture_60m
wire        adc_raw_valid      ;  // Raw data valid from adc_capture_60m
wire        adc_otr_flag       ;  // OTR flag from adc_capture_60m

// ADC filter outputs (filtered data)
wire [11:0] adc_filtered_data  ;  // Filtered ADC data (after adc_filter)
wire        adc_filtered_valid ;  // Filtered ADC data valid

// FIFO write side (from adc_to_usb_60m)
wire [7:0]  fifo_din         ;  // FIFO write data
wire        fifo_wr_en       ;  // FIFO write enable
wire        fifo_full_internal;  // FIFO full flag (internal)

// Key debounce signals
wire        key_short_press  ;  // Key[1] short press (for data mode cycling)
wire        key_long_press   ;  // Key[1] long press (unused)

// Data mode selection (3-state)
reg  [1:0]  data_mode_reg    ;  // 0=ADC data, 1=Phase data, 2=Debug packet

// Connect internal signals to outputs (use filtered data)
assign adc_capture_data = adc_filtered_data;
assign adc_data_valid   = adc_filtered_valid;
assign fifo_full        = fifo_full_internal;
assign data_mode        = data_mode_reg;

//*****************************************************
//**                    main code
//*****************************************************

//==============================================================================
// Key Debounce Module for Data Source Selection (60MHz clock domain)
// Key[1] toggles between ADC data mode and Phase data mode
//==============================================================================
key_debounce #(
    .CLK_FREQ       (60_000_000),  // 60MHz clock
    .DEBOUNCE_TIME  (20),          // 20ms debounce
    .SHORT_TIME     (200),         // 200ms short press
    .LONG_TIME      (600)          // 600ms long press
) u_key_phase_switch (
    .clk            (clk_60m          ),  // 60MHz clock
    .rst_n          (rst_n            ),  // System reset
    .key_in         (key_phase_switch ),  // Key[1] input
    .key_short_press(key_short_press  ),  // Short press output
    .key_long_press (key_long_press   )   // Long press output (unused)
);

//==============================================================================
// Data Mode Selection Logic (Key[1] Short Press)
// Cycle through three modes: ADC (0) -> Phase (1) -> Debug (2) -> ADC (0)
// Default: ADC data mode (safe default, no impact on existing functionality)
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n)
        data_mode_reg <= 2'd0;  // Default: ADC mode (CRITICAL for safety)
    else if (key_short_press) begin
        // Two-state toggle: 0 <-> 1 (remove mode 2 from cycle)
        if (data_mode_reg == 2'd0)
            data_mode_reg <= 2'd1;
        else
            data_mode_reg <= 2'd0;
    end
end

//==============================================================================
// ADC Capture Module (60MHz clock domain)
// Handles ADC data capture with 2MHz sampling clock (60MHz / 30)
// In Mode 1: outputs test counter instead of real ADC data
// In Mode 2: outputs real ADC data
// In Mode 0: bypassed (not used, USB test counter in adc_to_usb_60m)
//==============================================================================
adc_capture_60m #(
    .DIV_N(2),                // 60MHz/2 = 30MHz 采样
    .VALID_PULSE_CYCLES(2)    // 每半周期各1拍有效（30MHz场景足够）
) u_adc_capture_60m (
    .clk_60m       (clk_60m                     ),  // 60MHz clock
    .rst_n         (rst_n                       ),  // Reset
    .adc_test_mode (test_mode[0]                ),  // Test mode: Mode 1 enables counter
    // ADC interface
    .adc_data      (ch2_data                    ),  // ADC data input
    .adc_otr       (ch2_otr                     ),  // OTR flag
    .adc_clk       (ch2_clk                     ),  // 2MHz ADC clock output
    // Data output (raw, before filter)
    .capture_data  (adc_raw_data                ),  // Raw captured data (12-bit)
    .data_valid    (adc_raw_valid               ),  // Raw data valid (180ns wide)
    .otr_flag      (adc_otr_flag                )   // OTR flag
);

//==============================================================================
// ADC Filter Module (60MHz clock domain)
// Filters ADC data to remove out-of-range noise spikes
// Adjustable filter range (1-9): ±1.5V to ±2.5V (default=Level 5 → ±2.0V)
//==============================================================================
adc_filter u_adc_filter (
    .clk_60m       (clk_60m                     ),  // 60MHz clock
    .rst_n         (rst_n                       ),  // Reset
    .filter_level  (filter_level                ),  // Filter range level (0-9)
    // Raw ADC data input
    .adc_data_in   (adc_raw_data                ),  // Raw ADC data
    .adc_valid_in  (adc_raw_valid               ),  // Raw data valid
    // Filtered ADC data output
    .adc_data_out  (adc_filtered_data           ),  // Filtered ADC data
    .adc_valid_out (adc_filtered_valid          )   // Filtered data valid (1-cycle delay)
);

//==============================================================================
// ADC to USB Data Converter (60MHz clock domain)
// Converts 12-bit ADC data to 8-bit bytes and writes to FIFO
// Handles:
//   - Mode 0: USB test counter (8-bit counter, 4 MB/s, no header)
//   - Mode 1/2: 12-bit data serialization (2MHz × 2B = 4 MB/s, with header)
//   - Data mode 0: ADC data (test_mode controls ADC/test counter)
//   - Data mode 1: 12-bit phase data (4 MB/s, continuous)
//   - Data mode 2: Debug packet (13 bytes, 1kHz)
//==============================================================================
adc_to_usb_60m u_adc_to_usb_60m (
    .clk            (clk_60m                    ),  // 60MHz clock
    .rst_n          (rst_n                      ),  // Reset
    .test_mode      (test_mode                  ),  // Test mode control (0=USB test, 1=ADC test, 2=Normal)
    // ADC interface (filtered data)
    .adc_data       (adc_filtered_data          ),  // 12-bit ADC data (filtered)
    .adc_data_valid (adc_filtered_valid         ),  // Data valid flag (filtered)
    .adc_otr_flag   (adc_otr_flag               ),  // OTR flag (for monitoring)
    // Data mode and phase/debug data interface
    .data_mode      (data_mode_reg              ),  // Data mode: 0=ADC, 1=Phase, 2=Debug
    .phase_diff_12bit(phase_diff_12bit          ),  // 12-bit phase (0-4095)
    .adc_midpoint   (adc_midpoint_in            ),  // Dynamic ADC midpoint
    .zero_cross_count(zero_cross_count_in       ),  // Zero-crossing counter
    .adc_min        (adc_min_in                 ),  // ADC minimum value
    .adc_max        (adc_max_in                 ),  // ADC maximum value
    .phase_strobe   (phase_strobe_in            ),  // Phase strobe for Mode 1 transmit
    // FIFO write interface
    .fifo_din       (fifo_din                   ),  // FIFO write data
    .fifo_wr_en     (fifo_wr_en                 ),  // FIFO write enable
    .fifo_full      (fifo_full_internal         )   // FIFO full flag
);

//==============================================================================
// Synchronous FIFO (Common Clock)
// Instance: fifo_generator_1 (1024 depth x 8 bit)
// Configuration:
//   - Type: Common Clock (synchronous FIFO)
//   - Width: 8 bits
//   - Depth: 1024 (sufficient for rate mismatch buffering)
//   - Read Mode: Standard FIFO
//
// Purpose: Decouple ADC write side (adc_to_usb_60m) from USB read side (usb_tx)
//   - Absorbs burst speed differences
//   - Eliminates race conditions
//   - Simplifies state machine logic
//==============================================================================
fifo_generator_1 u_fifo_adc_usb (
    .clk    (clk_60m            ),  // 60MHz common clock
    .srst   (~rst_n             ),  // Synchronous reset (active high)
    // Write side (from adc_to_usb_60m)
    .din    (fifo_din           ),  // Write data [7:0]
    .wr_en  (fifo_wr_en         ),  // Write enable
    .full   (fifo_full_internal ),  // Full flag
    // Read side (to usb_tx)
    .dout   (fifo_data_out      ),  // Read data [7:0]
    .rd_en  (fifo_rd_en         ),  // Read enable
    .empty  (fifo_empty         )   // Empty flag
);

endmodule
