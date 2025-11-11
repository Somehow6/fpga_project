//****************************************Copyright (c)***********************************//
// Original source: www.yuanzige.com
// Support: www.openedv.com
// Taobao: http://openedv.taobao.com
// Focus on "Original Point Atomic" for ZYNQ & FPGA & STM32 & LINUX resources
// Copyright reserved
// Copyright(C) Original Point Atomic 2018-2028
// All rights reserved
//----------------------------------------------------------------------------------------
// File name:           mnist_tx_controller
// Created by:          Original Point Atomic
// Created date:        2024/12/01
// Version:             V1.0
// Descriptions:        MNIST ROM bit sequence generator and UART TX controller
//
// Features:
// - Read MNIST ROM data and generate bit sequences (200us per bit)
// - Send each bit via UART synchronized with bit generation (200us intervals)
// - Key trigger with debounce
// - LED status indication
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module mnist_tx_controller #(
    parameter PAUSE_DURATION_US = 32'd0      // Pause duration in microseconds (0 = no pause)
)(
    input                clk            ,  // System clock (20MHz)
    input                rst_n          ,  // System reset (active low)
    input                key             ,  // Key input for start trigger
    // ROM interface
    output  reg [16:0]   rom_addr        ,  // ROM address (0~97999)
    input       [7:0]    rom_data        ,  // ROM data
    // Bit sequence output for DA
    output  reg          bit_output      ,  // Bit sequence for DA output
    // UART TX interface (for verification)
    output  reg          uart_tx_en      ,  // UART TX enable
    output  reg [7:0]    uart_tx_data    ,  // UART TX data
    input                uart_tx_busy    ,  // UART TX busy status
    // LED status indication
    output  reg          led_key_pressed ,  // Key press indicator
    output  reg          led_tx_busy       // TX busy indicator
);

//==============================================================================
// Parameter Definition
//==============================================================================
localparam IDLE    = 2'b00;
localparam SENDING = 2'b01;
localparam DONE    = 2'b10;
localparam PAUSING = 2'b11;             // Pause state between images

localparam BIT_DURATION = 16'd4000;     // Each bit duration (4000 cycles @ 20MHz = 200us)
localparam BITS_PER_BYTE = 4'd8;        // 8 bits per byte
localparam ROM_BYTE_DEPTH = 17'd98000;  // ROM depth in bytes
localparam BITS_PER_IMAGE = 16'd784;    // 784 bits per image (28x28 pixels)
localparam CLK_FREQ_MHZ = 32'd20;       // Clock frequency in MHz
localparam PAUSE_CYCLES = PAUSE_DURATION_US * CLK_FREQ_MHZ;  // Pause duration in clock cycles

//==============================================================================
// Signal Definition
//==============================================================================
// Key debounce signals
reg  [23:0]   key_debounce_cnt;    // Debounce counter (0.5s @ 20MHz = 10M)
reg           key_pressed;         // Key pressed flag
reg           key_last;            // Key last state

// Bit sequence generation signals
reg  [15:0]   bit_duration_cnt;    // Bit duration counter (0~BIT_DURATION-1)
reg  [3:0]    bit_position;        // Current bit position in byte (0~7)
reg  [7:0]    shift_reg;           // Shift register for current byte (MSB first)
reg           has_byte;            // Indicates shift_reg holds a valid byte
reg  [16:0]   rom_index;           // Next ROM address to request (0~ROM_BYTE_DEPTH-1)
reg           last_byte_active;    // Flag that current active byte is the last one

// Image pause control signals
reg  [15:0]   bit_count;           // Bit counter within current image (0~783)
reg  [31:0]   pause_cnt;           // Pause counter for inter-image pause

// TX control signals
reg  [1:0]    tx_state;            // TX state machine

//==============================================================================
// Start Trigger (external debounced short pulse)
// key 为单拍高脉冲：此处直接透传为 key_pressed
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_pressed <= 1'b0;
    end else begin
        key_pressed <= key;
    end
end

//==============================================================================
// Bit Sequence Generation and TX Control State Machine
//==============================================================================
// States: IDLE, SENDING, DONE
wire bit_tick = (bit_duration_cnt == BIT_DURATION - 1);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_state <= IDLE;
        bit_duration_cnt <= 16'd0;
        bit_position <= 4'd0;
        rom_index <= 17'd0;
        shift_reg <= 8'd0;
        has_byte <= 1'b0;
        bit_output <= 1'b0;
        rom_addr <= 17'd0;
        last_byte_active <= 1'b0;
        uart_tx_en <= 1'b0;
        uart_tx_data <= 8'd0;
        bit_count <= 16'd0;
        pause_cnt <= 32'd0;
    end else begin
        case (tx_state)
            IDLE: begin
                uart_tx_en <= 1'b0;
                bit_output <= 1'b0;
                if (key_pressed) begin
                    rom_index <= 17'd0;     // prefetch index
                    rom_addr  <= 17'd0;     // request first byte
                    bit_position <= 4'd0;
                    bit_duration_cnt <= 16'd0;
                    has_byte <= 1'b0;
                    last_byte_active <= 1'b0;
                    bit_count <= 16'd0;     // reset bit counter
                    tx_state <= SENDING;
                end
            end

            SENDING: begin
                // Bit duration counter
                if (bit_tick) begin
                    bit_duration_cnt <= 16'd0;

                    // Check if completed an image and need to pause
                    if (bit_count >= BITS_PER_IMAGE && PAUSE_CYCLES > 0) begin
                        // Enter pause state after 784 bits
                        tx_state <= PAUSING;
                        pause_cnt <= 32'd0;
                        bit_output <= 1'b0;
                        bit_count <= 16'd0;
                    end else begin
                        // Load new byte from ROM or shift existing byte
                        if (!has_byte) begin
                            // Load new byte from ROM
                            bit_output <= rom_data[7];
                            shift_reg  <= {rom_data[6:0], 1'b0};
                            bit_position <= 4'd1;
                            has_byte <= 1'b1;
                            // 装载后立即计数（不延后一拍）
                            bit_count <= (bit_count == BITS_PER_IMAGE - 1) ? 16'd0 : (bit_count + 1'b1);
                            
                            // Update ROM address for next byte
                            if (rom_index >= ROM_BYTE_DEPTH - 1) begin
                                last_byte_active <= 1'b1;
                            end else begin
                                last_byte_active <= 1'b0;
                                rom_index <= rom_index + 1'b1;
                                rom_addr  <= rom_index + 1'b1;
                            end
                        end else begin
                            // Shift out next bit
                            bit_output <= shift_reg[7];
                            shift_reg  <= {shift_reg[6:0], 1'b0};
                            bit_count <= (bit_count == BITS_PER_IMAGE - 1) ? 16'd0 : (bit_count + 1'b1);
                            
                            if (bit_position >= BITS_PER_BYTE - 1) begin
                                // Byte complete
                                bit_position <= 4'd0;
                                has_byte <= 1'b0;
                                if (last_byte_active) begin
                                    tx_state <= DONE;
                                end
                            end else begin
                                bit_position <= bit_position + 1'b1;
                            end
                        end
                    end
                end else begin
                    bit_duration_cnt <= bit_duration_cnt + 1'b1;
                end

                // UART TX control (send bit as byte) - 连续发送，无帧间暂停
                if (bit_tick && !uart_tx_busy) begin
                    uart_tx_en   <= 1'b1;
                    uart_tx_data <= {7'b0, bit_output};
                end else begin
                    uart_tx_en <= 1'b0;
                end
            end

            PAUSING: begin
                // Pause between images - output stays low, no UART transmission
                uart_tx_en <= 1'b0;
                bit_output <= 1'b0;
                
                if (pause_cnt >= PAUSE_CYCLES - 1) begin
                    // Pause complete, return to SENDING state
                    tx_state <= SENDING;
                    pause_cnt <= 32'd0;
                end else begin
                    pause_cnt <= pause_cnt + 1'b1;
                end
            end

            DONE: begin
                uart_tx_en <= 1'b0;
                bit_output <= 1'b0;  // 发�?�完成后bit保持�??0
                // 保持在DONE状�?�，如果再次按键则重新开�??
                if (key_pressed) begin
                    tx_state <= IDLE;
                end
            end

            default: begin
                tx_state <= IDLE;
            end
        endcase
    end
end

//==============================================================================
// LED Indicator Logic
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_key_pressed <= 1'b0;
        led_tx_busy <= 1'b0;
    end else begin
        led_key_pressed <= key_pressed;                              // Key press indicator
        led_tx_busy <= (tx_state == SENDING) || (tx_state == PAUSING);  // Busy indicator (sending or pausing)
    end
end

endmodule
