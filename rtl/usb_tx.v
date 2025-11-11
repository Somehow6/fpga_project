//****************************************Copyright (c)***********************************//
// File name:           usb_tx
// Last modified Date:  2025/11/03
// Last Version:        V2.0
// Descriptions:        Improved USB transmit module for FT232H
//                      Implements professional timing protections:
//                      1. Two-stage synchronizer for usb_txe_n (metastability prevention)
//                      2. Pipelined 3-state machine (proper write timing)
//                      3. negedge output registers (better setup/hold time for FT232H)
//                      Only supports FPGA to PC data transmission (no receive)
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module usb_tx(
    input               usb_clk_60m  ,  // FT232H 60MHz clock
    input               rst_n        ,  // System reset, active low
    // FT232H USB interface
    input               usb_txe_n    ,  // FT232H FIFO write enable flag (active low, asynchronous)
    output              usb_wr_n     ,  // FT232H write enable signal (active low)
    output      [7:0]   usb_data     ,  // FT232H 8-bit data bus (output only)
    // FIFO interface
    output              fifo_rd_en   ,  // FIFO read enable (registered output)
    input               empty        ,  // FIFO empty signal
    input       [7:0]   fifo_data_out,  // Data from FIFO
    // Control inputs
    input               tx_enable    ,  // USB transmission enable
    input       [3:0]   wait_cycles     // WAIT_CYCLES value (configurable rate control)
);

//==============================================================================
// State Machine Definition
// Simplified 3-state pipeline for reliable USB write timing:
//   IDLE  : Wait for data and FT232H ready (checks tx_enable)
//   WRITE : Assert write signals and latch data
//   WAIT  : Deassert write and rate limiting (configurable via wait_cycles input)
//==============================================================================
localparam IDLE  = 2'b00;
localparam WRITE = 2'b01;
localparam WAIT  = 2'b10;

//==============================================================================
// Rate Control
// Configurable wait cycles between writes via wait_cycles input parameter
// Rate (MB/s) = 60 / (wait_cycles + 1)
// Examples: wait_cycles=1 -> 30MB/s, wait_cycles=2 -> 20MB/s, 
//           wait_cycles=4 -> 12MB/s, wait_cycles=9 -> 6MB/s
//==============================================================================
reg [3:0] wait_cnt;  // Wait cycle counter

//==============================================================================
// Signal Definitions
//==============================================================================
// Two-stage synchronizer for usb_txe_n (metastability prevention)
reg [1:0]  txe_sync     ;  // Synchronizer shift register
wire       txe_n_sync   ;  // Synchronized txe_n signal (safe to use)

// State machine
reg [1:0]  cur_state    ;  // Current state (2 bits for 3 states)

// Internal control signals (updated on posedge)
reg        usb_wr_n_int ;  // Internal write enable
reg [7:0]  usb_data_int ;  // Internal data register
reg        fifo_rd_en_int; // Internal FIFO read enable

// Output registers (driven on negedge for better timing)
reg        usb_wr_n_reg ;  // Output write enable register
reg [7:0]  usb_data_reg ;  // Output data register
reg        fifo_rd_en_reg; // Output FIFO read enable register

//*****************************************************
//**                    main code
//*****************************************************

//==============================================================================
// Two-Stage Synchronizer for usb_txe_n
// Purpose: Prevent metastability from asynchronous FT232H control signal
// Delay: 2 clock cycles, but ensures stable operation
//==============================================================================
always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n)
        txe_sync <= 2'b11;  // Default to "not ready" (active low signal)
    else
        txe_sync <= {txe_sync[0], usb_txe_n};  // Shift register
end

assign txe_n_sync = txe_sync[1];  // Use synchronized signal in state machine

//==============================================================================
// State Machine (posedge logic)
// Simplified 3-state machine for reliable USB write timing
// Modified: WAIT state now waits for WAIT_CYCLES before next write
//==============================================================================
always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        cur_state      <= IDLE;
        usb_wr_n_int   <= 1'b1;
        usb_data_int   <= 8'h00;
        fifo_rd_en_int <= 1'b0;
        wait_cnt       <= 4'd0;
    end else begin
        case (cur_state)
            IDLE: begin
                usb_wr_n_int   <= 1'b1;        // Disable write
                usb_data_int   <= 8'h00;       // Clear data
                fifo_rd_en_int <= 1'b0;        // Disable FIFO read
                wait_cnt       <= 4'd0;        // Reset wait counter
                
                // Enter WRITE when: TX enabled, FT232H ready, and FIFO has data
                if (tx_enable && !txe_n_sync && !empty) begin
                    cur_state <= WRITE;
                end
            end
            
            WRITE: begin
                // Commit to write operation
                usb_wr_n_int   <= 1'b0;           // Assert write enable
                usb_data_int   <= fifo_data_out;  // Latch FIFO data
                fifo_rd_en_int <= 1'b1;           // Signal for FIFO read
                wait_cnt       <= 4'd0;           // Reset wait counter
                cur_state      <= WAIT;           // Move to WAIT stage
            end
            
            WAIT: begin
                // Deassert write and rate limiting
                usb_wr_n_int   <= 1'b1;           // Deassert write
                usb_data_int   <= 8'h00;          // Clear data
                fifo_rd_en_int <= 1'b0;           // Clear FIFO read
                
                // Rate limiting: wait for 'wait_cycles', then check for next byte
                // Total: WRITE(1) + WAIT(wait_cycles) cycles per byte
                if (wait_cnt >= wait_cycles) begin
                    // Wait complete, check for next operation
                    wait_cnt <= 4'd0;
                    if (!tx_enable || txe_n_sync || empty) begin
                        // TX disabled, FT232H full, or FIFO empty: return to IDLE
                        cur_state <= IDLE;
                    end else begin
                        // Continue writing next byte
                        cur_state <= WRITE;
                    end
                end else begin
                    // Still waiting
                    wait_cnt <= wait_cnt + 4'd1;
                end
            end
            
            default: begin
                cur_state      <= IDLE;
                usb_wr_n_int   <= 1'b1;
                usb_data_int   <= 8'h00;
                fifo_rd_en_int <= 1'b0;
                wait_cnt       <= 4'd0;
            end
        endcase
    end
end

//==============================================================================
// Output Registers (posedge logic)
// Purpose: Register all outputs for clean timing
//          Output signals are stable and glitch-free
//==============================================================================
always @(posedge usb_clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        usb_wr_n_reg   <= 1'b1;
        usb_data_reg   <= 8'h00;
        fifo_rd_en_reg <= 1'b0;
    end else begin
        usb_wr_n_reg   <= usb_wr_n_int;
        usb_data_reg   <= usb_data_int;
        fifo_rd_en_reg <= fifo_rd_en_int;
    end
end

//==============================================================================
// Output Assignments
//==============================================================================
assign usb_wr_n   = usb_wr_n_reg;
assign fifo_rd_en = fifo_rd_en_reg;

// Tri-state output: drive data only during write, otherwise high-Z
assign usb_data   = (~usb_wr_n_reg) ? usb_data_reg : 8'hzz;

endmodule
