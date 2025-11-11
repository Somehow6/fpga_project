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
    input                 sys_clk    ,  // System clock (20MHz from external PLL)
    input                 clk_50m    ,  // 50MHz clock for UART (from external PLL)
    input                 sys_rst_n  ,  // System reset (active low)
    input                 locked     ,  // PLL locked signal (from external PLL)
    input        [3:0]    key        ,  // Key input: key[0]=decrease, key[1]=increase addr_step, key[2]=start UART TX
    // DA chip interface
    output                da_clk     ,  // DA clock
    output    [9:0]       da_data    ,  // DA data
    // UART interface
    input                 uart_rxd   ,  // UART RXD input
    output                uart_txd   ,  // UART TXD output
    // LED indicators
    output   reg [3:0]    led        ,  // led[0]=key pressed, led[1]=TX busy, led[3:2]=reserved
    // seg led interface
    output   [5:0]        seg_sel   ,
    output   [7:0]        seg_led
);

//wire define
wire      [14:0]   rd_addr ;            // Sine wave ROM address
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
wire               bit_sequence;        // Bit sequence for DA output

//*****************************************************
//**                    main code
//*****************************************************

// Combine system reset signal and PLL clock locked signal to generate new reset signal
assign  rst_n = sys_rst_n & locked;

// Clock assignment - sys_clk is now 20MHz from external unified PLL
assign  clk_20m = sys_clk;
    
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
    .clk         (clk_20m       ),
    .rst_n       (rst_n         ),
    .key         (key[1:0]      ),
    // Sine wave ROM interface
    .rd_data     (rd_data       ),
    .rd_addr     (rd_addr       ),
    // Bit sequence input from controller
    .bit_input   (bit_sequence  ),
    .da_clk      (da_clk        ),
    .da_data     (da_data       ),
    .addr_step   (addr_step     )
    );

// seg led display
seg_led u_seg_led(
    .clk         (clk_20m ),
    .rst_n       (rst_n   ),
    .data        (addr_step),        // 20-bit input: show ADDR_STEP value
    .point       (6'b000000),        // No decimal point (integer display)
    .en          (1'b1     ),        // Enable display
    .sign        (1'b0     ),        // No sign display
    .seg_sel     (seg_sel  ),
    .seg_led     (seg_led  )
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
    .clk             (clk_20m          ),
    .rst_n           (rst_n            ),
    .key             (key[2]           ),
    // ROM interface
    .rom_addr        (mnist_addr       ),
    .rom_data        (mnist_rd_data    ),
    // Bit sequence output for DA
    .bit_output      (bit_sequence     ),
    // UART TX interface (for verification)
    .uart_tx_en      (uart_tx_en_ctrl  ),
    .uart_tx_data    (uart_tx_data_ctrl),
    .uart_tx_busy    (uart_tx_busy     ),
    // LED status indication
    .led_key_pressed (led_key_pressed  ),
    .led_tx_busy     (led_tx_busy      )
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
        led[3:2] <= 2'b00;           // Reserved
    end
end

endmodule