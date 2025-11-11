//****************************************Copyright (c)***********************************//
// Integrated DDS and HDMI Camera Project
// Combines hs_dual_da (DDS output) with ov5640_hdmi (Camera + HDMI display)
// Uses unified clock management from external PLL
//****************************************************************************************//

module hs_dual_da_hdmi_top(
    // System clock and reset
    input                 sys_clk      ,  // System clock 50MHz
    input                 sys_rst_n    ,  // System reset (active low)
    
    //========== DDS Module Interfaces ==========
    input        [3:0]    key          ,  // Key inputs
    // DA chip interface
    output                da_clk       ,  // DA clock
    output    [9:0]       da_data      ,  // DA data
    // UART interface
    input                 uart_rxd     ,  // UART RX
    output                uart_txd     ,  // UART TX
    // LED and segment display
    output       [3:0]    led          ,  // LED indicators
    output       [5:0]    seg_sel      ,  // Segment select
    output       [7:0]    seg_led      ,  // Segment LED
    
    //========== Camera Interfaces (COMMENTED OUT FOR USB DEBUG) ==========
    /*
    input                 cam_pclk     ,  // Camera pixel clock
    input                 cam_vsync    ,  // Camera vsync
    input                 cam_href     ,  // Camera href
    input   [7:0]         cam_data     ,  // Camera data
    output                cam_rst_n    ,  // Camera reset
    output                cam_pwdn     ,  // Camera power down
    output                cam_scl      ,  // Camera I2C clock
    inout                 cam_sda      ,  // Camera I2C data
    */
    
    //========== DDR3 Interfaces (COMMENTED OUT FOR USB DEBUG) ==========
    /*
    inout   [15:0]        ddr3_dq      ,  // DDR3 data
    inout   [1:0]         ddr3_dqs_n   ,  // DDR3 DQS negative
    inout   [1:0]         ddr3_dqs_p   ,  // DDR3 DQS positive
    output  [13:0]        ddr3_addr    ,  // DDR3 address
    output  [2:0]         ddr3_ba      ,  // DDR3 bank
    output                ddr3_ras_n   ,  // DDR3 RAS
    output                ddr3_cas_n   ,  // DDR3 CAS
    output                ddr3_we_n    ,  // DDR3 WE
    output                ddr3_reset_n ,  // DDR3 reset
    output  [0:0]         ddr3_ck_p    ,  // DDR3 clock positive
    output  [0:0]         ddr3_ck_n    ,  // DDR3 clock negative
    output  [0:0]         ddr3_cke     ,  // DDR3 clock enable
    output  [0:0]         ddr3_cs_n    ,  // DDR3 chip select
    output  [1:0]         ddr3_dm      ,  // DDR3 data mask
    output  [0:0]         ddr3_odt     ,  // DDR3 ODT
    */
    
    //========== HDMI Interfaces (COMMENTED OUT FOR USB DEBUG) ==========
    /*
    output                tmds_clk_p   ,  // TMDS clock positive
    output                tmds_clk_n   ,  // TMDS clock negative
    output  [2:0]         tmds_data_p  ,  // TMDS data positive
    output  [2:0]         tmds_data_n  ,  // TMDS data negative
    output                tmds_oen     ,  // TMDS output enable
    */
    
    //========== ADC Interfaces (CH2) ==========
    input   [11:0]        ch2_data     ,  // CH2 ADC data input (D0-D11)
    input                 ch2_otr      ,  // CH2 over-range indicator
    output                ch2_clk      ,  // CH2 ADC clock output
    
    //========== USB2.0 Interfaces (FT232H) ==========
    input                 usb_clk_60m  ,  // FT232H 60MHz clock output
    input                 usb_txe_n    ,  // FT232H FIFO writable flag (active low)
    output                usb_wr_n     ,  // FT232H write enable (active low)
    output                usb_siwu_n   ,  // FT232H send immediate / wake up
    inout   [7:0]         usb_data        // FT232H 8-bit bidirectional data bus
);

//==============================================================================
// Clock and Reset Signal Definitions
//==============================================================================
wire         clk_20m        ;  // 20MHz for DDS and ADC (ADC internally divides to 10MHz)
wire         clk_50m        ;  // 50MHz for camera and UART
wire         clk_200m       ;  // 200MHz for DDR3
wire         pixel_clk      ;  // HDMI pixel clock (65MHz for 1024x768 @ 60Hz)
wire         pixel_clk_5x   ;  // HDMI serialization clock (325MHz, 5x pixel clock)
wire         locked         ;  // PLL locked signal
wire         rst_n          ;  // Global reset

//==============================================================================
// Filter Level Control
// 9 adjustable levels (1-9) controlled by key[3]:
//   Level 1: ±1.5V filter range (narrowest)
//   Level 5: ±2.0V filter range (default)
//   Level 9: ±2.5V filter range (widest)
// Filter is applied inside hs_adc_top_60m → adc_filter
//==============================================================================
reg [3:0]  filter_level = 4'd5;    // Filter level: 1-9 (default 5 = ±2.0V)

// Test mode fixed to Mode 2 (Normal ADC mode)
wire [1:0] test_mode = 2'b10;      // Fixed: Mode 2 (Normal ADC sampling)

//==============================================================================
// USB Speed Control (wait_cycles adjustment)
//==============================================================================
reg        usb_tx_enable = 1'b1;   // USB transmission enable (always enabled)
reg [1:0]  wait_cycles_sel = 2'd2; // USB speed selector (0-3), default=2 (12MB/s)
wire [3:0] wait_cycles_value;      // WAIT_CYCLES value for usb_tx

// Map wait_cycles_sel to actual WAIT_CYCLES value
assign wait_cycles_value = (wait_cycles_sel == 2'd0) ? 4'd1 :  // 30 MB/s
                           (wait_cycles_sel == 2'd1) ? 4'd2 :  // 20 MB/s
                           (wait_cycles_sel == 2'd2) ? 4'd4 :  // 12 MB/s (default)
                                                       4'd9;    // 6 MB/s

//==============================================================================
// USB Data Path Signals (60MHz unified clock domain)
//==============================================================================
wire  [7:0]  fifo_data_out  ;  // Data from FIFO to usb_tx
wire         fifo_empty     ;  // FIFO empty flag
wire         fifo_rd_en     ;  // FIFO read enable (from usb_tx, registered)
wire         fifo_full      ;  // FIFO full flag (for LED indicator)

//==============================================================================
// LED Internal Signals
//==============================================================================
wire [3:0]   led_internal       ;  // LED from hs_dual_da module

//==============================================================================
// Phase Detector Signals
//==============================================================================
// DA phase and bit sequence (20MHz domain)
wire [15:0]  phase_acc_20m      ;  // Phase accumulator from DA (20MHz, 16-bit)
wire         bit_seq_20m        ;  // Bit sequence from DA (20MHz)

// CDC synchronized signals (60MHz domain)
reg  [15:0]  phase_acc_60m_sync1;  // First sync stage (16-bit)
reg  [15:0]  phase_acc_60m_sync2;  // Second sync stage (16-bit)
reg          bit_seq_60m_sync1  ;  // First sync stage
reg          bit_seq_60m_sync2  ;  // Second sync stage

// ADC capture signals (60MHz domain) - Filtered by hs_adc_top_60m internally
wire [11:0]  adc_capture_data   ;  // ADC filtered data from hs_adc_top_60m
wire         adc_data_valid     ;  // ADC filtered valid flag
// Alias with explicit filtered naming for clarity
wire [11:0]  adc_filtered_data  = adc_capture_data;
wire         adc_filtered_valid = adc_data_valid;

// Phase detector outputs (60MHz domain)
wire [8:0]   phase_diff         ;  // Phase difference (0-360 degrees)
wire         phase_strobe       ;  // 1-cycle strobe at zero-crossing
wire         phase_valid        ;  // Phase valid flag
wire [7:0]   phase_diff_8bit    ;  // 8-bit phase (0-255 for 0-360 deg, for USB transmission)
wire [11:0]  phase_diff_12bit   ;  // 12-bit phase (0-4095 for 0-360 deg, higher precision)

// Phase detector V2 debug outputs (60MHz domain)
wire [11:0]  phase_adc_midpoint ;  // Dynamic ADC midpoint from phase detector V2
wire [15:0]  phase_zero_cross_cnt;  // Zero-crossing counter from phase detector V2
wire [11:0]  phase_adc_min      ;  // ADC minimum value from phase detector V2
wire [11:0]  phase_adc_max      ;  // ADC maximum value from phase detector V2
wire [15:0]  phase_at_zc16      ;  // 16-bit DA phase captured at ZC

// Data mode signal (60MHz domain)
wire [1:0]   data_mode_60m      ;  // Data mode from hs_adc_top_60m (0=ADC, 1=Phase, 2=Debug)

// Phase difference CDC synchronized signals (60MHz → 20MHz)
reg  [8:0]   phase_diff_20m_sync1;  // First sync stage
reg  [8:0]   phase_diff_20m_sync2;  // Second sync stage

// Data mode CDC synchronized signals (60MHz → 20MHz)
reg  [1:0]   data_mode_20m_sync1;   // First sync stage
reg  [1:0]   data_mode_20m_sync2;   // Second sync stage

// Auto step pulses (20MHz domain), driven later by 60MHz controller via CDC
wire         auto_step_up_20m;
wire         auto_step_down_20m;

//==============================================================================
// Reset Signal Generation
//==============================================================================
assign rst_n = sys_rst_n & locked;

//==============================================================================
// Key Debounce Instances
//==============================================================================
// Key[3] short press: cycle filter_level (0 -> 1 -> ... -> 9 -> 0)
wire key3_short_press;
wire key3_long_press;

key_debounce u_key3_debounce (
    .clk            (clk_20m          ),  // 20MHz clock
    .rst_n          (rst_n            ),  // Reset
    .key_in         (key[3]           ),  // Key input
    .key_short_press(key3_short_press ),  // Short press output
    .key_long_press (key3_long_press  )   // Long press output
);

//==============================================================================
// Filter Level Switching Logic (Key[3] short press)
// Cycle through 10 levels: 0 -> 1 -> ... -> 9 -> 0
//==============================================================================
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n)
        filter_level <= 4'd5;  // Default to Level 5 (±2.0V)
    else if (key3_short_press) begin
        if (filter_level == 4'd9)
            filter_level <= 4'd1;          // Wrap around: 9 -> 1
        else if (filter_level == 4'd0)
            filter_level <= 4'd1;          // Guard: 0 -> 1
        else
            filter_level <= filter_level + 4'd1;  // Increment: 1->2->...->9
    end
end

//==============================================================================
// Key[3] 长按：锁相开关切换（20MHz域寄存），默认开启
// 并去掉原Key3长按的USB速率切换以避免冲突
//==============================================================================
reg phase_lock_en_20m;
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        wait_cycles_sel  <= 2'd2;    // USB速率保持默认
        phase_lock_en_20m <= 1'b1;   // 默认开启锁相
    end else begin
        if (key3_long_press)
            phase_lock_en_20m <= ~phase_lock_en_20m;
    end
end

//==============================================================================
// CDC Synchronizers (20MHz → 60MHz)
// Double-register synchronization for crossing clock domains
//==============================================================================
// DA phase accumulator synchronizer (16-bit)
always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        phase_acc_60m_sync1 <= 16'd0;
        phase_acc_60m_sync2 <= 16'd0;
    end else begin
        phase_acc_60m_sync1 <= phase_acc_20m;
        phase_acc_60m_sync2 <= phase_acc_60m_sync1;
    end
end

// Bit sequence synchronizer
always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        bit_seq_60m_sync1 <= 1'b0;
        bit_seq_60m_sync2 <= 1'b0;
    end else begin
        bit_seq_60m_sync1 <= bit_seq_20m;
        bit_seq_60m_sync2 <= bit_seq_60m_sync1;
    end
end

// Filter level synchronizer (4-bit)
reg [3:0] filter_level_60m_sync1;
reg [3:0] filter_level_60m_sync2;
// phase_lock_en 同步到60MHz
reg phase_lock_en_60m_sync1;
reg phase_lock_en_60m_sync2;

always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        filter_level_60m_sync1 <= 4'd5;
        filter_level_60m_sync2 <= 4'd5;
        phase_lock_en_60m_sync1 <= 1'b1;
        phase_lock_en_60m_sync2 <= 1'b1;
    end else begin
        filter_level_60m_sync1 <= filter_level;
        filter_level_60m_sync2 <= filter_level_60m_sync1;
        phase_lock_en_60m_sync1 <= phase_lock_en_20m;
        phase_lock_en_60m_sync2 <= phase_lock_en_60m_sync1;
    end
end

//==============================================================================
// CDC Synchronizers (60MHz → 20MHz)
// Phase difference and data mode synchronization for display
//==============================================================================
// Phase difference synchronizer
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        phase_diff_20m_sync1 <= 9'd0;
        phase_diff_20m_sync2 <= 9'd0;
    end else begin
        phase_diff_20m_sync1 <= phase_diff;
        phase_diff_20m_sync2 <= phase_diff_20m_sync1;
    end
end

// Data mode synchronizer
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        data_mode_20m_sync1 <= 2'd0;
        data_mode_20m_sync2 <= 2'd0;
    end else begin
        data_mode_20m_sync1 <= data_mode_60m;
        data_mode_20m_sync2 <= data_mode_20m_sync1;
    end
end

//==============================================================================
// Unified Clock Management
// NOTE: This PLL IP core needs to be generated in Vivado with the following configuration:
//   - IP Name: clk_wiz_0
//   - Input Clock: 50MHz (sys_clk)
//   - Output Clocks:
//     * clk_out1: 200MHz   (for DDR3 reference)
//     * clk_out2: 50MHz    (for Camera config and UART)
//     * clk_out3: 20MHz    (for DDS and ADC base clock)
//     * clk_out4: 65MHz    (for HDMI pixel clock, 1024x768 @ 60Hz)
//     * clk_out5: 325MHz   (for HDMI serialization, 5x pixel clock)
//   Note: ADC uses clk_out3 (20MHz) with internal /2 divider to generate 10MHz
//==============================================================================
clk_wiz_0 u_clk_wiz_0 (
    .clk_in1        (sys_clk      ),  // 50MHz input
    .clk_out1       (clk_200m     ),  // 200MHz output (DDR3)
    .clk_out2       (clk_50m      ),  // 50MHz output (UART/I2C)
    .clk_out3       (clk_20m      ),  // 20MHz output (DDS + ADC)
    .clk_out4       (pixel_clk    ),  // 65MHz output (1024x768 @ 60Hz)
    .clk_out5       (pixel_clk_5x ),  // 325MHz output (5x pixel clock)
    .locked         (locked       )   // PLL locked output
);

//==============================================================================
// DDS Module Instance
// Handles DA waveform output, MNIST data transmission, UART, and display
// Now also displays filter_level (digit 5) and data_mode (digit 6)
//==============================================================================
hs_dual_da u_hs_dual_da (
    .sys_clk        (clk_20m                ),  // 20MHz clock
    .clk_50m        (clk_50m                ),  // 50MHz for UART RX
    .sys_rst_n      (rst_n                  ),
    .locked         (locked                 ),
    .key            (key                    ),
    .filter_level   (filter_level           ),  // Filter level for segment display (digit 5)
    .data_mode      (data_mode_20m_sync2    ),  // Data mode for segment display (digit 6, CDC synchronized)
    // DA interface
    .da_clk         (da_clk                 ),
    .da_data        (da_data                ),
    // UART interface
    .uart_rxd       (uart_rxd               ),
    .uart_txd       (uart_txd               ),
    // LED and display
    .led            (led_internal           ),  // Connect to internal signal
    .seg_sel        (seg_sel                ),
    .seg_led        (seg_led                ),
    // Phase detector interface
    .phase_acc      (phase_acc_20m          ),  // Phase accumulator output (16-bit)
    .bit_sequence   (bit_seq_20m            ),  // Bit sequence output
    .phase_diff     (phase_diff_20m_sync2   ),  // Phase difference input (0-360 degrees)
    .phase_valid    (bit_seq_20m            ),  // Use bit_sequence as validity indicator
    // Auto step control (from 60MHz controller via CDC)
    .auto_step_up   (auto_step_up_20m       ),
    .auto_step_down (auto_step_down_20m     )
);

//==============================================================================
// OV5640 Camera + HDMI Display Module Instance
// Handles camera capture, DDR3 frame buffer, and HDMI output
// COMMENTED OUT FOR FAST SYNTHESIS DURING USB DEBUG
//==============================================================================
/*
ov5640_hdmi u_ov5640_hdmi (
    .sys_rst_n      (rst_n        ),
    .locked         (locked       ),
    // Clock inputs
    .clk_200m       (clk_200m     ),
    .clk_50m        (clk_50m      ),
    .pixel_clk      (pixel_clk    ),
    .pixel_clk_5x   (pixel_clk_5x ),
    // Camera interface
    .cam_pclk       (cam_pclk     ),
    .cam_vsync      (cam_vsync    ),
    .cam_href       (cam_href     ),
    .cam_data       (cam_data     ),
    .cam_rst_n      (cam_rst_n    ),
    .cam_pwdn       (cam_pwdn     ),
    .cam_scl        (cam_scl      ),
    .cam_sda        (cam_sda      ),
    // DDR3 interface
    .ddr3_dq        (ddr3_dq      ),
    .ddr3_dqs_n     (ddr3_dqs_n   ),
    .ddr3_dqs_p     (ddr3_dqs_p   ),
    .ddr3_addr      (ddr3_addr    ),
    .ddr3_ba        (ddr3_ba      ),
    .ddr3_ras_n     (ddr3_ras_n   ),
    .ddr3_cas_n     (ddr3_cas_n   ),
    .ddr3_we_n      (ddr3_we_n    ),
    .ddr3_reset_n   (ddr3_reset_n ),
    .ddr3_ck_p      (ddr3_ck_p    ),
    .ddr3_ck_n      (ddr3_ck_n    ),
    .ddr3_cke       (ddr3_cke     ),
    .ddr3_cs_n      (ddr3_cs_n    ),
    .ddr3_dm        (ddr3_dm      ),
    .ddr3_odt       (ddr3_odt     ),
    // HDMI interface
    .tmds_clk_p     (tmds_clk_p   ),
    .tmds_clk_n     (tmds_clk_n   ),
    .tmds_data_p    (tmds_data_p  ),
    .tmds_data_n    (tmds_data_n  ),
    .tmds_oen       (tmds_oen     )
);
*/

//==============================================================================
// ADC Top Module Instance (60MHz unified clock domain)
// Handles:
//   - Mode 0: USB test counter (8-bit counter, 10 MB/s rate-limited, no header)
//   - Mode 1: ADC test counter (12-bit counter → 2 bytes, with header)
//   - Mode 2: Real ADC sampling (12-bit data → 2 bytes, with header)
// Data flow: ADC capture → adc_to_usb_60m → Sync FIFO → usb_tx
// All in 60MHz clock domain, no CDC issues
//==============================================================================
hs_adc_top_60m u_hs_adc_top_60m (
    .clk_60m         (usb_clk_60m              ),  // 60MHz clock (from FT232H)
    .rst_n           (rst_n                    ),  // Global reset
    .test_mode       (test_mode                ),  // Test mode: Fixed to Mode 2 (Normal)
    .filter_level    (filter_level_60m_sync2   ),  // Filter range control (CDC synchronized)
    // CH2 ADC interface
    .ch2_data        (ch2_data                 ),  // CH2 ADC data input [11:0]
    .ch2_otr         (ch2_otr                  ),  // CH2 over-range indicator
    .ch2_clk         (ch2_clk                  ),  // CH2 ADC clock output (2MHz)
    // USB TX interface (FIFO read side)
    .fifo_data_out   (fifo_data_out            ),  // FIFO read data to USB TX
    .fifo_empty      (fifo_empty               ),  // FIFO empty flag to USB TX
    .fifo_rd_en      (fifo_rd_en               ),  // FIFO read enable from USB TX
    // Debug/Status interface
    .fifo_full       (fifo_full                ),  // FIFO full flag for LED indicator
    // ADC data output (filtered)
    .adc_capture_data(adc_capture_data         ),  // ADC filtered data [11:0]
    .adc_data_valid  (adc_data_valid           ),  // ADC filtered valid flag
    // Phase and debug data interface
    .key_phase_switch(key[1]                   ),  // Key[1] input for data mode cycling
    .phase_diff_12bit(phase_diff_12bit         ),  // 12-bit phase input (0-4095)
    .adc_midpoint_in (phase_adc_midpoint       ),  // Dynamic ADC midpoint from phase_detector_v2
    .zero_cross_count_in(phase_zero_cross_cnt  ),  // Zero-crossing counter from phase_detector_v2
    .adc_min_in      (phase_adc_min            ),  // ADC minimum value from phase_detector_v2
    .adc_max_in      (phase_adc_max            ),  // ADC maximum value from phase_detector_v2
    .phase_valid_in  (phase_valid              ),  // Phase valid flag from phase_detector_v2
    .phase_strobe_in (phase_strobe             ),  // Phase strobe from phase_detector_v2
    // Data mode output
    .data_mode       (data_mode_60m            )   // Data mode output (2-bit: 0=ADC, 1=Phase, 2=Debug)
);

//==============================================================================
// Phase Detector V2 Module (60MHz clock domain)
// Enhanced version with dynamic zero-point calibration and debug outputs
// Features:
//   - Auto-adjusts to ADC signal bias/offset (64-sample running average)
//   - Tracks ADC min/max values for signal quality analysis
//   - Zero-crossing counter for frequency verification
//   - Dynamic midpoint output for debugging
//   - 12-bit phase output for higher precision (16x better than 8-bit)
//==============================================================================
phase_detector_v2 u_phase_detector (
    .clk_60m         (usb_clk_60m              ),  // 60MHz clock
    .rst_n           (rst_n                    ),  // Global reset
    // DA phase input (CDC synchronized from 20MHz)
    .da_phase_sync   (phase_acc_60m_sync2      ),  // DA phase (16-bit, synchronized)
    .bit_valid_sync  (bit_seq_60m_sync2        ),  // Bit=1 flag (synchronized)
    // ADC data input (filtered by hs_adc_top_60m)
    .adc_data        (adc_filtered_data        ),  // ADC data (12-bit, filtered)
    .adc_data_valid  (adc_filtered_valid       ),  // ADC data valid flag (filtered)
    // Phase difference output
    .phase_diff      (phase_diff               ),  // Phase difference (0-360 degrees)
    .phase_valid     (phase_valid              ),  // Phase valid flag
    .phase_diff_8bit (phase_diff_8bit          ),  // 8-bit phase (0-255 for USB transmission)
    .phase_diff_12bit(phase_diff_12bit         ),  // 12-bit phase (0-4095 for higher precision)
    .phase_strobe    (phase_strobe             ),  // Strobe at zero-crossing
    .phase_at_zc16   (phase_at_zc16            ),  // 16-bit phase at ZC
    // Debug outputs (V2 new features)
    .adc_midpoint_out(phase_adc_midpoint       ),  // Dynamic ADC midpoint (12-bit)
    .zero_cross_count(phase_zero_cross_cnt     ),  // Zero-crossing counter (16-bit)
    .adc_min         (phase_adc_min            ),  // ADC minimum value (12-bit)
    .adc_max         (phase_adc_max            )   // ADC maximum value (12-bit)
);

//==============================================================================
// Simple Phase Lock Controller and CDC (placed after phase detector)
//==============================================================================
wire step_up_60m;
wire step_down_60m;

phase_lock_simple u_phase_lock_simple (
    .clk_60m         (usb_clk_60m    ),
    .rst_n           (rst_n          ),
    .phase_strobe    (phase_strobe   ),
    .phase_at_zc16   (phase_at_zc16  ),
    .step_up_pulse   (step_up_60m    ),
    .step_down_pulse (step_down_60m  )
);

// Toggle-based CDC to 20MHz
reg inc_toggle_60m, dec_toggle_60m;
// 使用 Key3 长按控制的锁相开关门控步进
wire phase_lock_enable = phase_lock_en_60m_sync2;
always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        inc_toggle_60m <= 1'b0;
        dec_toggle_60m <= 1'b0;
    end else begin
        if (phase_lock_enable && step_up_60m)   inc_toggle_60m <= ~inc_toggle_60m;
        if (phase_lock_enable && step_down_60m) dec_toggle_60m <= ~dec_toggle_60m;
    end
end

reg inc_t_sync1, inc_t_sync2;
reg dec_t_sync1, dec_t_sync2;
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        inc_t_sync1 <= 1'b0; inc_t_sync2 <= 1'b0;
        dec_t_sync1 <= 1'b0; dec_t_sync2 <= 1'b0;
    end else begin
        inc_t_sync1 <= inc_toggle_60m; inc_t_sync2 <= inc_t_sync1;
        dec_t_sync1 <= dec_toggle_60m; dec_t_sync2 <= dec_t_sync1;
    end
end

assign auto_step_up_20m   = inc_t_sync2 ^ inc_t_sync1;
assign auto_step_down_20m = dec_t_sync2 ^ dec_t_sync1;

//==============================================================================
// USB Transmit Module (60MHz clock domain)
// Reads data from FIFO and sends to FT232H with configurable rate control
//==============================================================================
usb_tx u_usb_tx (
    .usb_clk_60m    (usb_clk_60m          ),  // USB clock from FT232H (60MHz)
    .rst_n          (rst_n                ),  // Global reset
    // FT232H interface
    .usb_txe_n      (usb_txe_n            ),  // FT232H writable flag (active low)
    .usb_wr_n       (usb_wr_n             ),  // FT232H write enable (active low)
    .usb_data       (usb_data             ),  // 8-bit data bus
    // FIFO read interface
    .fifo_rd_en     (fifo_rd_en           ),  // FIFO read enable
    .empty          (fifo_empty           ),  // FIFO empty flag
    .fifo_data_out  (fifo_data_out        ),  // Data from FIFO
    // Control inputs
    .tx_enable      (usb_tx_enable        ),  // USB transmission enable
    .wait_cycles    (wait_cycles_value    )   // WAIT_CYCLES value (configurable: 30/20/12/6 MB/s)
);

//==============================================================================// LED Output Assignment
// LED[3]: FIFO full indicator
// LED[2:0]: from hs_dual_da module
//==============================================================================
assign led = {fifo_full, led_internal[2:0]};

//==============================================================================
// USB Control Signals
//==============================================================================
assign usb_siwu_n = 1'b1;  // Disable send immediate / wake up

endmodule


