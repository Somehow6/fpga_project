//////////////////////////////////////////////////////////////////////////////////
// Module Name:  uart_rx
// Project:      High Speed Dual DA System
// Description:  UART Receiver Module
//
// Features:
// - Standard UART reception protocol
// - 8 data bits, no parity, 1 stop bit
// - Asynchronous signal synchronization
// - Start bit detection and validation
// - Configurable baud rate (default 115200)
//
// Parameters:
// - CLK_FREQ: System clock frequency (default 50MHz)
// - UART_BPS: UART baud rate (default 115200)
//
// Ports:
// - clk:         System clock input
// - rst_n:       Active low reset
// - uart_rxd:    UART receive input
// - uart_rx_done: Reception complete signal
// - uart_rx_data: 8-bit received data
//
// Author:       Yuanzige
// Created:      2023-02-16
// Version:      V1.0
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

module uart_rx(
    input               clk         ,  // System clock
    input               rst_n       ,  // Active low reset
    input               uart_rxd    ,  // UART receive input
    output  reg         uart_rx_done,  // Reception complete signal
    output  reg  [7:0]  uart_rx_data   // 8-bit received data
);

//==============================================================================
// Parameter Definitions
//==============================================================================
parameter CLK_FREQ = 50000000;               // System clock frequency (50MHz)
parameter UART_BPS = 115200  ;               // UART baud rate (115200 bps)
localparam BAUD_CNT_MAX = CLK_FREQ/UART_BPS; // Clock cycles per baud period

//==============================================================================
// Register Declarations
//==============================================================================
reg          uart_rxd_d0;  // Input synchronizer stage 1
reg          uart_rxd_d1;  // Input synchronizer stage 2
reg          uart_rxd_d2;  // Input synchronizer stage 3
reg          rx_flag    ;  // Reception in progress flag
reg  [3:0 ]  rx_cnt     ;  // Bit counter (0-9: start, 8 data, stop)
reg  [15:0]  baud_cnt   ;  // Baud rate counter
reg  [7:0 ]  rx_data_t  ;  // Receive data buffer

//==============================================================================
// Wire Declarations
//==============================================================================
wire        start_en;    // Start bit detection enable

//==============================================================================
// Main Logic Implementation
//==============================================================================
//==============================================================================
// Start Bit Detection
//==============================================================================
// Detect falling edge on UART RXD (start of transmission) when not already receiving
assign start_en = uart_rxd_d2 & (~uart_rxd_d1) & (~rx_flag);

//==============================================================================
// Input Signal Synchronization
//==============================================================================
// Synchronize asynchronous UART RXD signal to avoid metastability
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_rxd_d0 <= 1'b0;
        uart_rxd_d1 <= 1'b0;
        uart_rxd_d2 <= 1'b0;
    end
    else begin
        uart_rxd_d0 <= uart_rxd;
        uart_rxd_d1 <= uart_rxd_d0;
        uart_rxd_d2 <= uart_rxd_d1;
    end
end

//==============================================================================
// Reception Control Flag
//==============================================================================
// Control reception process start and completion
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_flag <= 1'b0;
    else if(start_en)    // Start bit detected and not currently receiving
        rx_flag <= 1'b1; // Start reception process
    else if((rx_cnt == 4'd9) && (baud_cnt == BAUD_CNT_MAX/2 - 1'b1))
        rx_flag <= 1'b0; // Stop reception after stop bit
    else
        rx_flag <= rx_flag;
end

//==============================================================================
// Baud Rate Generator
//==============================================================================
// Generate timing for UART bit periods during reception
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 16'd0;
    else if(rx_flag) begin     // During reception
        if(baud_cnt < BAUD_CNT_MAX - 1'b1)
            baud_cnt <= baud_cnt + 16'b1;
        else
            baud_cnt <= 16'd0; // Wrap around for next bit period
    end
    else
        baud_cnt <= 16'd0;     // Idle state
end

//==============================================================================
// Bit Counter
//==============================================================================
// Count received bits: 0=start, 1-8=data, 9=stop
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_cnt <= 4'd0;
    else if(rx_flag) begin                  // During reception
        if(baud_cnt == BAUD_CNT_MAX - 1'b1) // End of current bit period
            rx_cnt <= rx_cnt + 1'b1;        // Move to next bit
        else
            rx_cnt <= rx_cnt;
    end
    else
        rx_cnt <= 4'd0;                     // Idle state
end        

//==============================================================================
// Data Reception and Sampling
//==============================================================================
// Sample UART RXD signal at the middle of each bit period for reliable data capture
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_data_t <= 8'b0;
    else if(rx_flag) begin                           // During reception
        if(baud_cnt == BAUD_CNT_MAX/2 - 1'b1) begin  // Sample in middle of bit period
           case(rx_cnt)
               4'd1 : rx_data_t[0] <= uart_rxd_d2;   // LSB first
               4'd2 : rx_data_t[1] <= uart_rxd_d2;
               4'd3 : rx_data_t[2] <= uart_rxd_d2;
               4'd4 : rx_data_t[3] <= uart_rxd_d2;
               4'd5 : rx_data_t[4] <= uart_rxd_d2;
               4'd6 : rx_data_t[5] <= uart_rxd_d2;
               4'd7 : rx_data_t[6] <= uart_rxd_d2;
               4'd8 : rx_data_t[7] <= uart_rxd_d2;   // MSB last
               default : ;
            endcase
        end
        else
            rx_data_t <= rx_data_t;
    end
    else
        rx_data_t <= 8'b0;
end

//==============================================================================
// Reception Complete and Data Output
//==============================================================================
// Generate reception complete signal and output received data after stop bit
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_rx_done <= 1'b0;
        uart_rx_data <= 8'b0;
    end
    else if(rx_cnt == 4'd9 && baud_cnt == BAUD_CNT_MAX/2 - 1'b1) begin
        uart_rx_done <= 1'b1     ;  // Pulse done signal
        uart_rx_data <= rx_data_t;  // Output received byte
    end
    else begin
        uart_rx_done <= 1'b0;
        uart_rx_data <= uart_rx_data;
    end
end

endmodule