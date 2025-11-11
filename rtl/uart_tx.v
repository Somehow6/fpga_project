//////////////////////////////////////////////////////////////////////////////////
// Module Name:  uart_tx
// Project:      High Speed Dual DA System
// Description:  UART Transmitter Module
//
// Features:
// - Standard UART transmission protocol
// - 8 data bits, no parity, 1 stop bit
// - Configurable baud rate (default 115200)
// - Busy status indication
//
// Parameters:
// - CLK_FREQ: System clock frequency (default 50MHz)
// - UART_BPS: UART baud rate (default 115200)
//
// Ports:
// - clk:        System clock input
// - rst_n:      Active low reset
// - uart_tx_en: Transmit enable signal
// - uart_tx_data: 8-bit data to transmit
// - uart_txd:   UART transmit output
// - uart_tx_busy: Transmission busy status
//
// Author:       Yuanzige
// Created:      2023-02-16
// Version:      V1.0
//////////////////////////////////////////////////////////////////////////////////

module uart_tx(
    input               clk         , // System clock
    input               rst_n       , // Active low reset
    input               uart_tx_en  , // Transmit enable
    input     [7:0]     uart_tx_data, // 8-bit data to transmit
    output  reg         uart_txd    , // UART transmit output
    output  reg         uart_tx_busy  // Transmission busy status
);

//==============================================================================
// Parameter Definitions
//==============================================================================
parameter CLK_FREQ = 20000000;               // System clock frequency (20MHz)
parameter UART_BPS = 115200  ;               // UART baud rate (115200 bps)
localparam BAUD_CNT_MAX = CLK_FREQ/UART_BPS; // Clock cycles per baud period

//==============================================================================
// Register Declarations
//==============================================================================
reg  [7:0]  tx_data_t;  // Transmit data buffer
reg  [3:0]  tx_cnt   ;  // Bit counter (0-9: start bit, 8 data bits, stop bit)
reg  [15:0] baud_cnt ;  // Baud rate counter

//==============================================================================
// Main Logic Implementation
//==============================================================================

//==============================================================================
// Transmit Control and Data Buffering
//==============================================================================
// Capture transmit data and set busy flag when transmit enable is asserted
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_data_t <= 8'b0;
        uart_tx_busy <= 1'b0;
    end
    else if(uart_tx_en) begin
        tx_data_t <= uart_tx_data;  // Latch transmit data
        uart_tx_busy <= 1'b1;       // Set busy flag
    end
    else if(tx_cnt == 4'd9 && baud_cnt == BAUD_CNT_MAX - 1) begin
        tx_data_t <= 8'b0;          // Clear transmit buffer
        uart_tx_busy <= 1'b0;       // Clear busy flag when transmission complete
    end
    else begin
        tx_data_t <= tx_data_t;
        uart_tx_busy <= uart_tx_busy;
    end
end

//==============================================================================
// Baud Rate Generator
//==============================================================================
// Generate baud timing for serial transmission
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 16'd0;
    else if(uart_tx_en)
        baud_cnt <= 16'd0;          // Reset counter when starting transmission
    else if(uart_tx_busy) begin
        if(baud_cnt < BAUD_CNT_MAX - 1'b1)
            baud_cnt <= baud_cnt + 16'b1;
        else
            baud_cnt <= 16'd0;      // Wrap around for next bit period
    end
    else
        baud_cnt <= 16'd0;          // Idle state
end

//==============================================================================
// Bit Counter
//==============================================================================
// Count transmitted bits: 0=start, 1-8=data, 9=stop
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tx_cnt <= 4'd0;
    else if(uart_tx_en)
        tx_cnt <= 16'd0;            // Reset counter for new transmission
    else if(uart_tx_busy) begin
        if(baud_cnt == BAUD_CNT_MAX - 1'b1) // End of current bit period
            tx_cnt <= tx_cnt + 1'b1;        // Move to next bit
        else
            tx_cnt <= tx_cnt;
    end
    else
        tx_cnt <= 4'd0;             // Idle state
end

//==============================================================================
// UART Transmit Output Logic
//==============================================================================
// Generate UART transmit signal based on bit counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        uart_txd <= 1'b1;           // Idle high
    else if(uart_tx_busy) begin
        case(tx_cnt)
            4'd0 : uart_txd <= 1'b0        ; // Start bit (logic 0)
            4'd1 : uart_txd <= tx_data_t[0]; // Data bit 0 (LSB)
            4'd2 : uart_txd <= tx_data_t[1]; // Data bit 1
            4'd3 : uart_txd <= tx_data_t[2]; // Data bit 2
            4'd4 : uart_txd <= tx_data_t[3]; // Data bit 3
            4'd5 : uart_txd <= tx_data_t[4]; // Data bit 4
            4'd6 : uart_txd <= tx_data_t[5]; // Data bit 5
            4'd7 : uart_txd <= tx_data_t[6]; // Data bit 6
            4'd8 : uart_txd <= tx_data_t[7]; // Data bit 7 (MSB)
            4'd9 : uart_txd <= 1'b1        ; // Stop bit (logic 1)
            default : uart_txd <= 1'b1;
        endcase
    end
    else
        uart_txd <= 1'b1;            // Idle high when not transmitting
end

endmodule