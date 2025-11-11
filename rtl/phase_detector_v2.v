//****************************************Copyright (c)***********************************//
// File name:           phase_detector_v2
// Last modified Date:  2025/11/08
// Version:             V2.0
// Descriptions:        Enhanced phase detector with dynamic zero-point calibration
//                      Works in 60MHz clock domain for high time resolution
//                      Auto-adjusts to ADC signal bias/offset
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module phase_detector_v2(
    input                 clk_60m         ,  // 60MHz clock
    input                 rst_n           ,  // Reset signal (active low)
    
    // DA phase input (CDC synchronized from 20MHz domain)
    input        [15:0]   da_phase_sync   ,  // DA phase accumulator (16-bit, 0-65535)
    input                 bit_valid_sync  ,  // Bit=1 flag (synchronized from 20MHz)
    
    // ADC data input
    input        [11:0]   adc_data        ,  // ADC data (12-bit, 0-4095)
    input                 adc_data_valid  ,  // ADC data valid flag
    
    // Phase difference output
    output  reg  [8:0]    phase_diff      ,  // Phase difference (0-360 degrees)
    output  reg           phase_valid     ,  // Phase difference valid flag
    output  reg           phase_updated   ,  // Phase updated this cycle (pulse on zero-crossing)
    output       [7:0]    phase_diff_8bit ,  // 8-bit phase (0-255 for 0-360 deg)
    output       [11:0]   phase_diff_12bit,  // 12-bit phase (0-4095 for 0-360 deg) - latched at ZC
    output                phase_strobe    ,  // 1-cycle strobe at zero-crossing (for USB phase mode)
    output       [15:0]   phase_at_zc16   ,  // 16-bit DA phase captured at zero-crossing
    
    // Debug outputs
    output       [11:0]   adc_midpoint_out,  // Current dynamic midpoint
    output  reg  [15:0]   zero_cross_count,  // Zero-crossing counter (for debug)
    output  reg  [11:0]   adc_min         ,  // ADC minimum value (for debug)
    output  reg  [11:0]   adc_max            // ADC maximum value (for debug)
);

//==============================================================================
// Parameters
//==============================================================================
parameter ADC_MIDPOINT_DEFAULT = 12'd2048;  // Default 12-bit ADC midpoint (0V)
parameter CALIBRATION_SAMPLES = 64;         // Number of samples for calibration (must be power of 2)
// Schmitt and slope thresholds (in ADC codes/LSB)
parameter HYST_LSB            = 12'd16;     // H = 16 LSB
parameter SLOPE_MIN_LSB       = 12'd9;      // Smin = 9 LSB per sample

//==============================================================================
// Internal Signals - Zero-Crossing Detection
//==============================================================================
reg  [11:0]   adc_prev       ;  // Previous ADC sample
reg  [11:0]   adc_curr       ;  // Current ADC sample
wire          zero_crossing  ;  // Zero-crossing detected (negative to positive)
reg           zc_pulse       ;  // One-cycle pulse for zero crossing (Schmitt FSM)
reg           schmitt_armed  ;  // Armed when below (mid - HYST), waiting to cross above (mid + HYST)
reg  [7:0]    holdoff_cnt    ;  // Minimum spacing between crossings
reg  [15:0]   da_phase_captured;  // Captured DA phase at zero-crossing
reg  [8:0]    phase_diff_temp;  // Temporary phase difference calculation
reg  [11:0]   phase_diff_12bit_reg;  // Latched principal phase (12-bit) at zero-crossing

//==============================================================================
// Internal Signals - Dynamic Zero-Point Calibration
//==============================================================================
reg  [17:0]   adc_sum        ;  // Accumulator for sum (12-bit * 64 = 18-bit)
reg  [5:0]    sample_cnt     ;  // Sample counter (0-63)
reg  [11:0]   adc_midpoint   ;  // Dynamic midpoint (running average)
reg           calibration_done;  // Calibration completed flag

//==============================================================================
// Dynamic Zero-Point Calibration
// Continuously track the average value of ADC signal as the zero-reference
// This handles DC bias/offset in the ADC signal path
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        adc_sum         <= 18'd0;
        sample_cnt      <= 6'd0;
        adc_midpoint    <= ADC_MIDPOINT_DEFAULT;
        calibration_done <= 1'b0;
    end else if (adc_data_valid && bit_valid_sync) begin
        // Only calibrate when bit=1 (signal is present)
        if (sample_cnt < CALIBRATION_SAMPLES - 1) begin
            // Accumulate samples
            adc_sum    <= adc_sum + adc_data;
            sample_cnt <= sample_cnt + 1'b1;
        end else begin
            // Calculate new midpoint (average of 64 samples)
            // adc_midpoint = (adc_sum + adc_data) / 64
            adc_midpoint <= (adc_sum + adc_data) >> 6;  // Divide by 64
            
            // Reset accumulator for next window
            adc_sum    <= 18'd0;
            sample_cnt <= 6'd0;
            calibration_done <= 1'b1;
        end
    end
end

// Output the current midpoint for debug
assign adc_midpoint_out = adc_midpoint;

//==============================================================================
// ADC Min/Max Tracking (for debug)
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        adc_min <= 12'd4095;  // Initialize to max
        adc_max <= 12'd0;     // Initialize to min
    end else if (adc_data_valid) begin
        // Track minimum
        if (adc_data < adc_min)
            adc_min <= adc_data;
        
        // Track maximum
        if (adc_data > adc_max)
            adc_max <= adc_data;
    end
end

//==============================================================================
// Zero-Crossing Detection (Schmitt + slope guard, with dynamic midpoint)
// 说明：使用“武装-触发”状态机，允许跨多拍穿越带区，避免单拍必须跨越2*H的不现实约束
//==============================================================================
assign zero_crossing = zc_pulse;

localparam [7:0] HOLD_OFF_SAMPLES = 8'd20;  // 最小间隔：20拍（≈1/8周期 @30MHz, 215kHz）

always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        zc_pulse      <= 1'b0;
        schmitt_armed <= 1'b0;
        holdoff_cnt   <= 8'd0;
    end else begin
        zc_pulse <= 1'b0; // default

        // Holdoff倒计时
        if (holdoff_cnt != 8'd0)
            holdoff_cnt <= holdoff_cnt - 8'd1;

        if (adc_data_valid && bit_valid_sync && calibration_done) begin
            // 进入武装态：落到下阈值以下
            if (adc_curr < (adc_midpoint - HYST_LSB))
                schmitt_armed <= 1'b1;

            // 触发：从下阈值武装后，跨越上阈值，且斜率足够，且没有holdoff
            if (schmitt_armed &&
                (adc_curr >= (adc_midpoint + HYST_LSB)) &&
                (adc_curr > adc_prev) &&
                ((adc_curr - adc_prev) >= SLOPE_MIN_LSB) &&
                (holdoff_cnt == 8'd0)) begin
                zc_pulse      <= 1'b1;
                schmitt_armed <= 1'b0;         // 触发后解除武装
                holdoff_cnt   <= HOLD_OFF_SAMPLES;
            end
        end
    end
end

//==============================================================================
// Zero-Crossing Counter (for debug)
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        zero_cross_count <= 16'd0;
    end else if (zero_crossing) begin
        zero_cross_count <= zero_cross_count + 1'b1;
    end
end

//==============================================================================
// ADC Data Sampling
// Store previous and current ADC samples for edge detection
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        adc_prev <= ADC_MIDPOINT_DEFAULT;
        adc_curr <= ADC_MIDPOINT_DEFAULT;
    end else if (adc_data_valid) begin
        adc_prev <= adc_curr;
        adc_curr <= adc_data;
    end
end

//==============================================================================
// Phase Capture and Calculation
// When zero-crossing is detected:
//   1. Capture DA phase accumulator value
//   2. Convert 16-bit phase (0-65535) to angle (0-360 degrees)
//   3. Update phase_diff output
//
// Formula: angle = (phase_acc * 360) / 65536
//        = (phase_acc * 45) >> 13  (optimized for hardware)
//
// When bit_valid_sync=0 (no signal): hold previous phase_diff value
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        da_phase_captured <= 16'd0;
        phase_diff        <= 9'd0;
        phase_valid       <= 1'b0;
        phase_updated     <= 1'b0;
        phase_diff_12bit_reg <= 12'd0;
    end else begin
        if (zero_crossing) begin
            // Zero-crossing detected: capture phase and calculate angle
            da_phase_captured <= da_phase_sync;
            // Latch 12-bit principal phase at zero-crossing
            phase_diff_12bit_reg <= da_phase_sync[15:4];
            
            // Calculate phase angle: (phase * 360) / 65536
            // Use approximation: (phase * 45) >> 13
            // Result range: 0-360 degrees (9-bit is sufficient, max 511)
            phase_diff_temp = (da_phase_sync * 16'd45) >> 13;
            
            // Clip to 0-360 range (should not exceed, but safety check)
            if (phase_diff_temp > 9'd360)
                phase_diff <= 9'd360;
            else
                phase_diff <= phase_diff_temp;
            
            phase_valid   <= 1'b1;
            phase_updated <= 1'b1;
        end else if (bit_valid_sync) begin
            // Bit=1 but no zero-crossing: keep searching
            phase_valid   <= phase_valid;    // Hold previous valid flag
            phase_updated <= 1'b0;
        end else begin
            // Bit=0 (no signal): hold previous phase_diff, mark as not recently updated
            phase_valid   <= phase_valid;    // Keep valid flag
            phase_updated <= 1'b0;           // Mark as not updated this cycle
        end
    end
end

//==============================================================================
// 8-bit Phase Output for USB Transmission
// Maps 0-360 degrees to 0-255 (8-bit)
// Formula: phase_diff_8bit = (phase_diff * 256) / 360
//==============================================================================
assign phase_diff_8bit = (phase_diff > 9'd360) ? 8'd255 :  // Clip to max
                         ((phase_diff * 10'd256) / 10'd360); // Direct division for accuracy

//==============================================================================
// 12-bit Phase Output (latched at zero-crossing)
// 使用零交叉事件处锁存的 DA 相位高12位（0..4095 ↔ 0..360°）
//==============================================================================
assign phase_diff_12bit = phase_diff_12bit_reg;

//==============================================================================
// Phase Strobe Output
// 说明：使用内部单拍标志 phase_updated 作为对外strobe信号
//==============================================================================
assign phase_strobe = phase_updated;
assign phase_at_zc16 = da_phase_captured;

endmodule

