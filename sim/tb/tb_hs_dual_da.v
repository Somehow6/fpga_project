`timescale 1ns / 1ps        // Time unit / Time precision

module tb_hs_dual_da();

// Parameter define
parameter  CLK_PERIOD = 20;     // Clock period: 20ns (50MHz) - matches hardware input to PLL
parameter  SIM_TIME   = 100000000;  // Simulation time: 10ms (extended for UART testing)

// Reg define
reg     sys_clk;
reg     sys_rst_n;
reg     [3:0] key;              // Extended to 4 bits
reg     uart_rxd;               // UART RX input

// Wire define - Output signals for observation
wire    da_clk;
wire    [9:0] da_data;
wire    uart_txd;               // UART TX output
wire    [3:0] led;              // LED indicators
wire    [5:0] seg_sel;          // Segment LED select
wire    [7:0] seg_led;          // Segment LED data

// Signal initialization
initial begin
    sys_clk = 1'b0;
    sys_rst_n = 1'b0;
    key = 4'b1111;              // All keys released (active low assumption)
    uart_rxd = 1'b1;            // UART RX idle (high)



    #200                        // Hold reset for 200ns
    sys_rst_n = 1'b1;

    // Test sequence
    #100000;                   // Wait 1ms after reset


    // Test key[2] to start MNIST bit sequence TX
    key[2] = 1'b0;              // Press key[2] to start MNIST TX (active low)
    #200000;                    // Hold for 200us
    key[2] = 1'b1;              // Release key[2]

    #20000000;                   // Wait 2ms to observe bit sequence start



end

// Generate clock (20MHz)
always #(CLK_PERIOD/2) sys_clk = ~sys_clk;

// Monitor output signals
initial begin
    $monitor("Time=%0t us | da_data=%h | uart_txd=%b | led=%b",
             $time/1000, da_data, uart_txd, led);
end

// DUT instantiation
hs_dual_da u_hs_dual_da(
    .sys_clk          (sys_clk        ),
    .sys_rst_n        (sys_rst_n      ),
    .key              (key            ),      // 4-bit key input
    // DA chip interface
    .da_clk           (da_clk         ),
    .da_data          (da_data        ),
    // UART interface
    .uart_rxd         (uart_rxd       ),
    .uart_txd         (uart_txd       ),
    // LED indicators
    .led              (led            ),
    // Segment LED interface
    .seg_sel          (seg_sel        ),
    .seg_led          (seg_led        )
);

endmodule
