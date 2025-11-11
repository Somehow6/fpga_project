//****************************************Copyright (c)***********************************//
// Original source: www.yuanzige.com
// Support: www.openedv.com
// Taobao: http://openedv.taobao.com
// Focus on "Original Point Atomic" for ZYNQ & FPGA & STM32 & LINUX resources
// Copyright reserved
// Copyright(C) Original Point Atomic 2018-2028
// All rights reserved
//----------------------------------------------------------------------------------------
// File name:           da_wave_send
// Last modified Date:  2019/07/31 17:04:35
// Last Version:        V1.0
// Descriptions:        DA data transmission module
//----------------------------------------------------------------------------------------
// Created by:          Original Point Atomic
// Created date:        2019/07/31 17:04:35
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module da_wave_send(
    input                 clk         ,  // Clock
    input                 rst_n       ,  // Reset signal, active low
    input                 key         ,  // Key input: short press=decrease, long press=increase addr_step
    input                 auto_step_up,   // Auto +1 step (one-shot pulse)
    input                 auto_step_down, // Auto -1 step (one-shot pulse)

    // Sine wave ROM interface (original functionality)
    input        [9:0]    rd_data     ,  // Sine wave ROM data
    output  reg  [15:0]   rd_addr     ,  // Sine wave ROM address (16-bit for 2^16 depth)

    // Bit sequence input from controller
    input                 bit_input   ,  // Bit sequence from controller
    // Mini sine enable: when bit_input==0, output mini sine (±64 LSB) if enabled
    input                 mini_sine_en,
    // DA chip interface
    output                da_clk      ,  // DAC clock output
    output       [9:0]    da_data     ,  // DA data output
    // display ADDR_STEP value for seg_led
    output       [19:0]   addr_step   ,
    // Phase accumulator output for phase detector
    output       [15:0]   phase_acc      // Current phase accumulator value (16-bit)
    );

//parameter
// No parameters needed for simplified version


//==============================================================================
// Internal Signals
//==============================================================================
// Frequency calculation formula: f_out = (f_clk × addr_step) / 2^16 = (20MHz × addr_step) / 65536
// When addr_step=705: f_out = (20,000,000 × 705) / 65536 = 215.1 kHz
// Frequency resolution: Δf = 20MHz / 65536 = 305.2 Hz per step
// (Each unit change in addr_step results in ~305.2 Hz frequency change)
reg    [15:0]   addr_step_reg = 16'd705; // Dynamic address increment step (1-9999), default 705

// Key detection signals from debounce module
wire            key_short_press;  // Short press: decrease addr_step
wire            key_long_press;   // Long press: increase addr_step

//*****************************************************
//**                    main code
//*****************************************************

//==============================================================================
// Key Debounce Instance
//==============================================================================
key_debounce #(
    .CLK_FREQ      (20_000_000),
    .DEBOUNCE_TIME (20),
    .SHORT_TIME    (200),
    .LONG_TIME     (600)
) u_key_debounce (
    .clk            (clk),
    .rst_n          (rst_n),
    .key_in         (key),
    .key_short_press(key_short_press),
    .key_long_press (key_long_press)
);

assign  da_clk = ~clk;
// DA data output: use bit_input for bit sequence, rd_data for sine wave
// DA voltage mapping: 0=-5V, 512=0V, 1023=+5V
// bit_input==1: 输出完整正弦 rd_data
// bit_input==0: mini_sine_en==1 输出同相位微小正弦(目标±64LSB)，否则输出512
wire [9:0] center       = 10'd512;
wire [9:0] delta_abs    = (rd_data >= center) ? (rd_data - center) : (center - rd_data);
wire [9:0] delta_div8   = delta_abs >> 3;                   // 约等于幅度缩小到 1/8
wire [9:0] amp_limited  = (delta_div8 > 10'd64) ? 10'd64 : delta_div8; // 限幅到 ±64
wire [9:0] mini_sine    = (rd_data >= center) ? (center + amp_limited) : (center - amp_limited);
assign da_data = bit_input ? rd_data : (mini_sine_en ? mini_sine : 10'd512);
assign  addr_step = {4'd0, addr_step_reg};  // Output 16-bit addr_step_reg as 20-bit value
assign  phase_acc = rd_addr;  // Export current phase accumulator for phase detection

// Sine wave ROM address increment (16-bit phase accumulator)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rd_addr <= 16'd0;
    else begin
        rd_addr <= rd_addr + addr_step_reg;
    end
end

//==============================================================================
// ADDR_STEP Control Logic
// Short press: decrease addr_step by 1 (minimum: 1)
// Long press: increase addr_step by 1 (maximum: 9999, for 4-digit display)
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_step_reg <= 16'd705;     // Initialize to default value (215 kHz)
    end else begin
        if (key_short_press || auto_step_down) begin
            // Short press: decrease
            if (addr_step_reg > 16'd1)
                        addr_step_reg <= addr_step_reg - 16'd1;
        end
        else if (key_long_press || auto_step_up) begin
            // Long press: increase
            if (addr_step_reg < 16'd9999)
                        addr_step_reg <= addr_step_reg + 16'd1;
        end
    end
end

endmodule