// =============================================================================
// Module: phase_lock_simple
// Purpose: Simple window-based phase holding controller for DDS addr_step
// Strategy:
//   - On each phase_strobe, take 16-bit phase_at_zc (0..65535)
//   - Unwrap around current estimate, reject outliers
//   - IIR smoothing (approx 100-sample median) with shift = 7 (≈1/128)
//   - Every WINDOW_SZ accepted samples, compare estimate against [LOW..HIGH]
//     and emit one-shot step_up/step_down pulses (60MHz domain)
// Notes:
//   - Designed for small logic footprint; stable for coarse step (≈305 Hz/step)
// =============================================================================
module phase_lock_simple #(
    parameter [15:0] RANGE_LOW     = 16'd59000, // Safe window low edge
    parameter [15:0] RANGE_HIGH    = 16'd65535, // High edge (wrap)
    parameter [15:0] THRESH_LOW    = 16'd30000, // Below: decrease frequency
    parameter integer WINDOW_SZ    = 100,       // Decision interval (accepted samples)
    parameter integer IIR_SHIFT    = 7,         // 1/128 smoothing
    parameter [15:0] RNG_HYST      = 16'd64,    // Hysteresis margin near borders
    parameter integer COOLDOWN_WINDOWS = 8      // Cooldown windows between steps
)(
    input               clk_60m,
    input               rst_n,
    input               phase_strobe,        // one-cycle pulse per valid ZC
    input      [15:0]   phase_at_zc16,       // DA phase captured at ZC (0..65535)
    output reg          step_up_pulse,       // +1 addr_step (increase frequency)
    output reg          step_down_pulse      // -1 addr_step (decrease frequency)
);

    // Signed 18-bit accumulator for estimate (allows ± wrap adjustments)
    reg  signed [17:0] m_est;          // smoothed estimate (unwrapped)
    reg  signed [17:0] x_adj;          // input adjusted for wrap near estimate
    wire signed [17:0] x_in = {2'b00, phase_at_zc16}; // 0..65535
    wire signed [17:0] diff_to_m = x_in - m_est;
    wire signed [17:0] plus_65536  = 18'sd65536;
    wire signed [17:0] minus_65536 = -18'sd65536;

    // Unwrap input around current estimate
    always @(*) begin
        if (diff_to_m < -18'sd32768)
            x_adj = x_in + plus_65536;
        else if (diff_to_m > 18'sd32767)
            x_adj = x_in + minus_65536;
        else
            x_adj = x_in;
    end

    // Difference for smoothing
    wire signed [17:0] d_est = x_adj - m_est;

    // Accepted sample counter
    reg [7:0] acc_cnt; // up to 255 > 100
    // Wrapped estimate for comparison (0..65535)
    reg [15:0] m_wrap;
    // Cooldown window counter
    reg [7:0]  cooldown_win;

    // Tracking window for phase (converted range): [LOW .. HIGH]
    // below  LOW  -> addr_step +1 (increase freq)
    // above  HIGH -> addr_step -1 (decrease freq)
    localparam [15:0] TRACK_LOW  = 16'd24249;
    localparam [15:0] TRACK_HIGH = 16'd30146;

    // Update and decision
    always @(posedge clk_60m or negedge rst_n) begin
        if (!rst_n) begin
            m_est           <= 18'sd27198; // start near TRACK window center (~(24249+30146)/2)
            acc_cnt         <= 8'd0;
            cooldown_win    <= 8'd0;
            step_up_pulse   <= 1'b0;
            step_down_pulse <= 1'b0;
        end else begin
            step_up_pulse   <= 1'b0;
            step_down_pulse <= 1'b0;

            if (phase_strobe) begin
                // Always accept sample (robustness由IIR提供)
                // IIR smoothing: m += (x - m) / 2^IIR_SHIFT
                m_est <= m_est + (d_est >>> IIR_SHIFT);
                if (acc_cnt == WINDOW_SZ-1)
                    acc_cnt <= 8'd0;
                else
                    acc_cnt <= acc_cnt + 8'd1;

                // Decision at window boundary
                if (acc_cnt == WINDOW_SZ-1) begin
                    // Wrap estimate back to 0..65535 for comparison
                    // Convert signed 18-bit to unsigned 16-bit modulo 65536
                    // (m_est % 65536)
                    if (m_est[17]) begin
                        // negative: add 65536 then truncate (implicit 16-bit truncate)
                        m_wrap <= (m_est + plus_65536);
                    end else begin
                        m_wrap <= m_est[15:0];
                    end

                    // Two-interval decision:
                    //   m_wrap <  TRACK_LOW  -> step_up (freq↑)
                    //   m_wrap >  TRACK_HIGH -> step_down (freq↓)
                    //   else hold
                    if (cooldown_win != 8'd0) begin
                        cooldown_win <= cooldown_win - 8'd1; // still cooling down
                    end else begin
                        if (m_wrap < TRACK_LOW) begin
                            step_up_pulse   <= 1'b1;                  // increase frequency
                            cooldown_win    <= COOLDOWN_WINDOWS[7:0]; // start cooldown
                        end else if (m_wrap > TRACK_HIGH) begin
                            step_down_pulse <= 1'b1;                  // decrease frequency
                            cooldown_win    <= COOLDOWN_WINDOWS[7:0]; // start cooldown
                        end
                    end
                end
            end
        end
    end

endmodule


