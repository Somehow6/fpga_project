//****************************************Copyright (c)***********************************//
// Original source: www.yuanzige.com
// Support: www.openedv.com
// Taobao: http://openedv.taobao.com
// Focus on "Original Point Atomic" for ZYNQ & FPGA & STM32 & LINUX resources
// Copyright reserved
// Copyright(C) Original Point Atomic 2018-2028
// All rights reserved
//----------------------------------------------------------------------------------------
// File name:           hs_dual_da
// Last modified Date:  2019/07/31 17:04:35
// Last Version:        V2.0
// Descriptions:        Single channel DA output
//----------------------------------------------------------------------------------------
// Created by:          Original Point Atomic
// Created date:        2019/07/31 17:04:35
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module hs_dual_da(
    input                 sys_clk       ,  // System clock (20MHz from external PLL)
    input                 clk_50m       ,  // 50MHz clock for UART (from external PLL)
    input                 sys_rst_n     ,  // System reset (active low)
    input                 locked        ,  // PLL locked signal (from external PLL)
    input        [3:0]    key           ,  // Key input: key[0]=addr_step, key[1]=display toggle, key[2]=start UART TX
    input        [3:0]    filter_level  ,  // Filter level (0-9) from top module (displayed on digit 5)
    input        [1:0]    data_mode     ,  // Data mode (0=ADC, 1=Phase, 2=Debug) from top module (displayed on digit 6)
    input        [8:0]    phase_diff    ,  // Phase difference from phase detector (0-360 degrees)
    input                 phase_valid   ,  // Phase detection valid flag (1=valid, 0=no signal)
    // Auto frequency control pulses (CDC from 60MHz)
    input                 auto_step_up  ,  // +1 addr_step
    input                 auto_step_down,  // -1 addr_step
    // DA chip interface
    output                da_clk        ,  // DA clock
    output    [9:0]       da_data       ,  // DA data
    // UART interface
    input                 uart_rxd      ,  // UART RXD input
    output                uart_txd      ,  // UART TXD output
    // LED indicators
    output   reg [3:0]    led           ,  // led[0]=key pressed, led[1]=TX busy, led[3:2]=reserved
    // seg led interface
    output   [5:0]        seg_sel       ,
    output   [7:0]        seg_led       ,
    // Phase detector interface (for top-level connection)
    output       [15:0]   phase_acc     ,  // Phase accumulator output (16-bit)
    output                bit_sequence     // Bit sequence output for phase sync
);

//wire define
wire      [15:0]   rd_addr ;            // Sine wave ROM address (16-bit)
wire      [9:0]    rd_data ;            // Sine wave ROM data
wire               clk_20m ;            // 20MHz clock (from sys_clk input)
wire               rst_n   ;            // Reset signal (active low)
wire     [19:0]    addr_step;           // ADDR_STEP value for display
wire               uart_rx_done;        // UART reception complete
wire     [7:0]     uart_rx_data;        // UART received data
wire               uart_tx_busy;        // UART TX busy signal
wire     [7:0]     mnist_rd_data;       // MNIST ROM read data

// MNIST TX controller signals
wire     [16:0]    mnist_addr;          // ROM address from controller
wire               uart_tx_en_ctrl;     // UART TX enable from controller
wire     [7:0]     uart_tx_data_ctrl;   // UART TX data from controller
wire               led_key_pressed;     // Key press indicator
wire               led_tx_busy;         // TX busy indicator

// Bit sequence from controller
wire               bit_sequence_internal;  // Bit sequence for DA output (internal)

// Display mode control signals
reg        [1:0]   display_mode;        // 0=addr_step, 1=phase_diff, 2=phase_diff
wire               key1_short_press;    // Key[1] short press
wire               key1_long_press;     // Key[1] long press (unused)
wire     [15:0]    display_value;       // Selected display value (0-9999)

//*****************************************************
//**                    main code
//*****************************************************

// Combine system reset signal and PLL clock locked signal to generate new reset signal
assign  rst_n = sys_rst_n & locked;

// Clock assignment - sys_clk is now 20MHz from external unified PLL
assign  clk_20m = sys_clk;

//==============================================================================
// bit_sequence 导出为“实际生效的比特”
// 说明：
//   - 正弦模式(force_sine_en=1)：恒为1（持续输出正弦）
//   - ASK模式(force_sine_en=0)：等于内部比特 bit_sequence_internal
//   - 未启用输出(output_enable=0)：为0
// 作用：
//   - 顶层同步后的 bit_valid_sync 将准确反映“当前是否有有效驱动”
//   - 相位检测与锁相只会在 bit=1 时进行（ASK=1 或 正弦恒1）
//==============================================================================
assign  bit_sequence = output_enable ? (force_sine_en ? 1'b1 : bit_sequence_internal) : 1'b0;

//==============================================================================
// Key[1] Debounce Instance for Display Mode Toggle
//==============================================================================
key_debounce #(
    .CLK_FREQ      (20_000_000),
    .DEBOUNCE_TIME (20),
    .SHORT_TIME    (200),
    .LONG_TIME     (600)
) u_key1_debounce (
    .clk            (clk_20m),
    .rst_n          (rst_n),
    .key_in         (key[1]),
    .key_short_press(key1_short_press),
    .key_long_press (key1_long_press)
);

//==============================================================================
// Key[2] Debounce Instance for ASK/Sine 选择
//   - 短按：输出 ASK（启用输出，使用 bit_sequence_internal）
//   - 长按：输出 正弦（启用输出，恒为1）
//   两个动作互相独立，按下即生效为对应模式
//==============================================================================
wire key2_short_press;
wire key2_long_press;
key_debounce #(
    .CLK_FREQ      (20_000_000),
    .DEBOUNCE_TIME (20),
    .SHORT_TIME    (200),
    .LONG_TIME     (600)
) u_key2_debounce (
    .clk            (clk_20m),
    .rst_n          (rst_n),
    .key_in         (key[2]),
    .key_short_press(key2_short_press),
    .key_long_press (key2_long_press)
);

// 模式选择：0=ASK(按原bit_sequence_internal), 1=Force sine(恒为1)
reg force_sine_en;
// 输出使能：0=关闭输出(0V)，1=开启输出
reg output_enable;
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        force_sine_en  <= 1'b1;      // 默认：选择正弦
        output_enable  <= 1'b0;      // 默认：未开始输出
    end else begin
        // 短按：选择 ASK，并启用输出
        if (key2_short_press) begin
            output_enable <= 1'b1;
            force_sine_en <= 1'b0;   // ASK
        end
        // 长按：选择 正弦，并启用输出
        if (key2_long_press) begin
            output_enable <= 1'b1;
            force_sine_en <= 1'b1;   // SINE
        end
    end
end

// Key[3] 长按微正弦功能移除；bit=0时统一按固定512（mini_sine_en=0）

//==============================================================================
// Display Mode Toggle Logic (Key[1] short press)
// Cycle: 0=addr_step -> 1=phase -> 2=phase -> 0
//==============================================================================
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n)
        display_mode <= 2'd0;  // Default: show addr_step
    else if (key1_short_press) begin
        if (display_mode == 2'd2)
            display_mode <= 2'd0;       // 2 -> 0
        else
            display_mode <= display_mode + 2'd1; // 0->1, 1->2
    end
end

//==============================================================================
// Display Value Selection
// Mode 0: show addr_step (0-9999) - real-time update
// Mode 1: show phase_diff (0-360 degrees), or 999 if invalid - 0.3s refresh rate
//==============================================================================
// Phase display update rate limiter (0.3 seconds)
localparam PHASE_UPDATE_CYCLES = 6_000_000;  // 20MHz × 0.3s = 6,000,000 cycles
reg [22:0] phase_update_cnt;  // Counter for 0.3s (needs 23 bits for 6M)
reg        phase_update_tick;  // Update tick (one cycle pulse)
reg [15:0] phase_display_latched;  // Latched phase value (updated every 0.3s)

// Generate 0.3s update tick
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        phase_update_cnt  <= 23'd0;
        phase_update_tick <= 1'b0;
    end else begin
        if (phase_update_cnt >= PHASE_UPDATE_CYCLES - 1) begin
            phase_update_cnt  <= 23'd0;
            phase_update_tick <= 1'b1;  // Generate pulse
        end else begin
            phase_update_cnt  <= phase_update_cnt + 23'd1;
            phase_update_tick <= 1'b0;
        end
    end
end

// Latch phase value every 0.3s
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        phase_display_latched <= 16'd999;
    end else begin
        if (phase_update_tick) begin
            // Update latched value every 0.3s
            if (phase_valid)
                phase_display_latched <= {7'd0, phase_diff};
            else
                phase_display_latched <= 16'd999;
        end
    end
end

// Always display addr_step (real-time)
assign display_value = addr_step[15:0];
    
// ROM module
rom_1024x10b  u_rom_1024x10b(
    .addra     (rd_addr ),
    .clka      (clk_20m ),
    .douta     (rd_data )
    );
blk_mem_gen_0 u_blk_mem_gen_0(
    .addra     (mnist_addr     ),
    .clka      (clk_20m        ),
    .ena       (1'b1           ),
    .douta     (mnist_rd_data  )
);
// DA data transmit module
da_wave_send u_da_wave_send(
    .clk         (clk_20m               ),
    .rst_n       (rst_n                 ),
    .key         (key[0]                ),  // Key[0] for addr_step control
    .auto_step_up   (auto_step_up       ),  // Auto +1 step
    .auto_step_down (auto_step_down     ),  // Auto -1 step
    // Sine wave ROM interface
    .rd_data     (rd_data               ),
    .rd_addr     (rd_addr               ),  // 16-bit address
    // Bit sequence input from controller
    .bit_input   (output_enable ? (force_sine_en ? 1'b1 : bit_sequence_internal) : 1'b0 ),
    // Mini sine enable for bit=0
    .mini_sine_en( 1'b0                 ),
    .da_clk      (da_clk                ),
    .da_data     (da_data               ),
    .addr_step   (addr_step             ),
    // Phase accumulator output
    .phase_acc   (phase_acc             )   // 16-bit phase for phase detector
    );

//==============================================================================
// Segment LED Display Data Preparation
// Display format: [Digit6][Digit5][Digit4][Digit3][Digit2][Digit1][Digit0]
//   Digit 6 (leftmost):  data_mode (0=ADC, 1=Phase, 2=Debug)
//   Digit 5:             filter_level (0-9)
//   Digit 3-0:           addr_step OR phase_diff (toggled by key[1])
//                        - Mode 0: addr_step (0-9999)
//                        - Mode 1: phase_diff (0-360 degrees)
// 
// CRITICAL: seg_led module converts the entire 20-bit value to decimal,
//           so we must use DECIMAL offset!
//   Format: MFdddd where:
//     M = data_mode (0/1/2)
//     F = filter_level (0-9)
//     dddd = display_value (addr_step or phase_diff, 0-9999)
//==============================================================================
wire [19:0] mode_offset;
wire [19:0] filter_offset;
wire [15:0] display_value_limited;
wire [19:0] seg_display_data;

// Limit display_value to 4 digits (0-9999)
assign display_value_limited = (display_value > 16'd9999) ? 16'd9999 : display_value;

// Calculate decimal offset based on data_mode (multiply by 100000)
// Displays data mode (0/1/2) on digit 6
assign mode_offset = ({18'd0, data_mode} * 20'd100000);

// Calculate decimal offset based on filter_level (multiply by 10000)
// Displays filter level (0-9) on digit 5
assign filter_offset = ({16'd0, filter_level} * 20'd10000);

// Final display value: mode_offset + filter_offset + display_value_limited
// display_value is either addr_step (mode 0) or phase_diff (mode 1)
assign seg_display_data = mode_offset + filter_offset + {4'd0, display_value_limited};

// seg led display
seg_led u_seg_led(
    .clk         (clk_20m           ),
    .rst_n       (rst_n             ),
    .data        (seg_display_data  ),  // Show data_mode (digit 6) + filter_level (digit 5) + addr_step or phase_diff (digits 0-3)
    .point       (6'b110000         ),  // Force display digit 6 (data_mode) and digit 5 (filter_level)
    .en          (1'b1              ),  // Enable display
    .sign        (1'b0              ),  // No sign display
    .seg_sel     (seg_sel           ),
    .seg_led     (seg_led           )
);

// UART RX instance (use clk_50m from external PLL)
uart_rx #(
    .CLK_FREQ(50000000),
    .UART_BPS(115200)
) u_uart_rx (
    .clk          (clk_50m     ),
    .rst_n        (rst_n       ),
    .uart_rxd     (uart_rxd    ),
    .uart_rx_done (uart_rx_done),
    .uart_rx_data (uart_rx_data)
    );

// UART TX instance (send bit data from controller synchronized with bit generation)
uart_tx #(
    .CLK_FREQ(20000000),
    .UART_BPS(115200)
) u_uart_tx (
    .clk          (clk_20m            ),
    .rst_n        (rst_n              ),
    .uart_tx_en   (uart_tx_en_ctrl    ),
    .uart_tx_data (uart_tx_data_ctrl  ),
    .uart_txd     (uart_txd           ),
    .uart_tx_busy (uart_tx_busy       )
);

// MNIST TX controller instance
mnist_tx_controller u_mnist_tx_controller(
    .clk             (clk_20m               ),
    .rst_n           (rst_n                 ),
    .key             (key2_short_press      ),
    // ROM interface
    .rom_addr        (mnist_addr            ),
    .rom_data        (mnist_rd_data         ),
    // Bit sequence output for DA
    .bit_output      (bit_sequence_internal ),
    // UART TX interface (for verification)
    .uart_tx_en      (uart_tx_en_ctrl       ),
    .uart_tx_data    (uart_tx_data_ctrl     ),
    .uart_tx_busy    (uart_tx_busy          ),
    // LED status indication
    .led_key_pressed (led_key_pressed       ),
    .led_tx_busy     (led_tx_busy           )
);

//==============================================================================
// LED Indicator Assignment
//==============================================================================
always @(posedge clk_20m or negedge rst_n) begin
    if (!rst_n) begin
        led <= 4'b0000;
    end else begin
        led[0] <= led_key_pressed;   // Key press indicator
        led[1] <= led_tx_busy;       // TX busy indicator
        led[2] <= 1'b0;              // Reserved (display mode removed)
        led[3] <= output_enable;     // 输出指示：1=已开始输出
    end
end

endmodule