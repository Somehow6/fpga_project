//****************************************Copyright (c)***********************************//
// File name:           key_debounce
// Last modified Date:  2025/11/04
// Last Version:        V1.0
// Descriptions:        Unified key debounce and short/long press detection module
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module key_debounce #(
    parameter CLK_FREQ      = 20_000_000,  // Clock frequency in Hz
    parameter DEBOUNCE_TIME = 20,          // Debounce time in ms
    parameter SHORT_TIME    = 200,         // Short press threshold in ms
    parameter LONG_TIME     = 600          // Long press threshold in ms
)(
    input                clk            ,  // Clock signal
    input                rst_n          ,  // Reset signal, active low
    input                key_in         ,  // Raw key input (active low)
    
    output reg           key_short_press,  // Short press pulse (one cycle)
    output reg           key_long_press    // Long press pulse (one cycle)
);

//==============================================================================
// Parameter Calculation
//==============================================================================
localparam DEBOUNCE_CNT = CLK_FREQ / 1000 * DEBOUNCE_TIME;  // Debounce cycles
localparam SHORT_CNT    = CLK_FREQ / 1000 * SHORT_TIME;     // Short press cycles
localparam LONG_CNT     = CLK_FREQ / 1000 * LONG_TIME;      // Long press cycles

//==============================================================================
// Internal Signals
//==============================================================================
reg [1:0]  key_sync;           // Two-stage synchronizer
reg        key_state;          // Debounced key state (0=pressed, 1=released)
reg        key_state_last;     // Previous key state
reg [31:0] press_cnt;          // Press duration counter
reg        long_press_flag;    // Flag to prevent multiple long press detection

//==============================================================================
// Two-Stage Synchronizer
// Purpose: Prevent metastability from asynchronous key input
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        key_sync <= 2'b11;  // Released state (active low key)
    else
        key_sync <= {key_sync[0], key_in};
end

//==============================================================================
// Debounce Logic
// Implements a simple counter-based debounce
//==============================================================================
reg [31:0] debounce_cnt;
reg        key_stable;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        debounce_cnt <= 32'd0;
        key_state <= 1'b1;  // Released
        key_stable <= 1'b0;
    end else begin
        key_stable <= 1'b0;  // Default: no stable transition
        
        if (key_sync[1] == key_state) begin
            // Key state matches current state, reset counter
            debounce_cnt <= 32'd0;
        end else begin
            // Key state changed, start counting
            debounce_cnt <= debounce_cnt + 1'b1;
            
            if (debounce_cnt >= DEBOUNCE_CNT) begin
                // Debounce period passed, accept new state
                key_state <= key_sync[1];
                key_stable <= 1'b1;
                debounce_cnt <= 32'd0;
            end
        end
    end
end

//==============================================================================
// Press Duration Counter and Detection Logic
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        press_cnt <= 32'd0;
        key_state_last <= 1'b1;
        key_short_press <= 1'b0;
        key_long_press <= 1'b0;
        long_press_flag <= 1'b0;
    end else begin
        key_state_last <= key_state;
        key_short_press <= 1'b0;  // Default: clear pulse
        key_long_press <= 1'b0;   // Default: clear pulse
        
        // Detect press/release edges
        if (!key_state && key_state_last) begin
            // Falling edge: key just pressed (stable)
            press_cnt <= 32'd0;
            long_press_flag <= 1'b0;
        end
        else if (!key_state && !key_state_last) begin
            // Key is being held down
            if (press_cnt < LONG_CNT + 1)
                press_cnt <= press_cnt + 1'b1;
            
            // Detect long press threshold
            if (press_cnt == LONG_CNT && !long_press_flag) begin
                key_long_press <= 1'b1;  // Generate long press pulse
                long_press_flag <= 1'b1; // Prevent multiple triggers
            end
        end
        else if (key_state && !key_state_last) begin
            // Rising edge: key released (stable)
            // Check if it was a short press
            if (press_cnt >= DEBOUNCE_CNT && press_cnt < SHORT_CNT && !long_press_flag) begin
                key_short_press <= 1'b1;  // Generate short press pulse
            end
            press_cnt <= 32'd0;
            long_press_flag <= 1'b0;
        end
    end
end

endmodule



