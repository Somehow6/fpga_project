//****************************************************************************************//
// File name:           phase_unwrapper
// Last modified Date:  2025/11/08
// Version:             V1.0
// Descriptions:        Phase unwrapping helper - converts principal phase [0..4095]
//                      into continuous unwrapped phase with turn counter.
//                      12-bit principal phase corresponds to [0..360) degrees.
//****************************************************************************************//
module phase_unwrapper(
    input                   clk,
    input                   rst_n,
    input           [11:0]  phase_principal,   // 0..4095 principal phase
    input                   phase_valid,       // strobe (e.g. at zero-crossing)
    output  reg  signed [15:0] rotation_count, // signed turn counter k
    output  reg  signed [31:0] phase_unwrapped // k*4096 + principal
);

// Previous principal phase to detect boundary crossing
reg [11:0] phase_prev;
// Signed difference between two consecutive principal phases
wire signed [12:0] diff = $signed({1'b0, phase_principal}) - $signed({1'b0, phase_prev});

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rotation_count  <= 16'sd0;
        phase_unwrapped <= 32'sd0;
        phase_prev      <= 12'd0;
    end else if (phase_valid) begin
        // Boundary crossing detection with ±180° threshold (±2048 in 12-bit space)
        if (diff > 13'sd2048)
            rotation_count <= rotation_count - 16'sd1; // wrapped negative (e.g., 100 -> 3900)
        else if (diff < -13'sd2048)
            rotation_count <= rotation_count + 16'sd1; // wrapped positive (e.g., 3900 -> 100)
        else
            rotation_count <= rotation_count;

        // Update unwrapped phase = k*4096 + principal
        phase_unwrapped <= $signed({rotation_count, 12'd0}) + $signed({20'd0, phase_principal});
        phase_prev      <= phase_principal;
    end
end

endmodule


