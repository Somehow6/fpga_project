//****************************************Copyright (c)***********************************//
// File name:           phase_detector
// Last modified Date:  2025/11/05
// Version:             V1.0
// Descriptions:        Phase detector for DA/ADC phase lock tracking
//                      Works in 60MHz clock domain for high time resolution
//                      Detects zero-crossing of ADC signal and calculates phase difference
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module phase_detector(
    input                 clk_60m         ,  // 60MHz clock
    input                 rst_n           ,  // Reset signal (active low)
    
    // DA phase input (CDC synchronized from 20MHz domain)
    input        [15:0]   da_phase_sync   ,  // DA phase accumulator (16-bit, 0-65535)
    input                 bit_valid_sync  ,  // Bit=1 flag (synchronized from 20MHz)
    
    // ADC data input
    input        [11:0]   adc_data        ,  // ADC data (12-bit, 0-4095, midpoint=2048)
    input                 adc_data_valid  ,  // ADC data valid flag
    
    // Phase difference output
    output  reg  [8:0]    phase_diff      ,  // Phase difference (0-360 degrees)
    output  reg           phase_valid     ,  // Phase difference valid flag
    output       [7:0]    phase_diff_8bit    // 8-bit phase (0-255 for 0-360 deg, for USB transmission)
);

//==============================================================================
// Parameters
//==============================================================================
parameter ADC_MIDPOINT = 12'd2048;  // 12-bit ADC midpoint (0V reference)

//==============================================================================
// Internal Signals
//==============================================================================
reg  [11:0]   adc_prev       ;  // Previous ADC sample
reg  [11:0]   adc_curr       ;  // Current ADC sample
wire          zero_crossing  ;  // Zero-crossing detected (negative to positive)
reg  [15:0]   da_phase_captured;  // Captured DA phase at zero-crossing
reg           phase_updated  ;  // Flag: phase was updated in this cycle
reg  [8:0]    phase_diff_temp;  // Temporary phase difference calculation

//==============================================================================
// Zero-Crossing Detection
// Detect ADC signal transition from negative to positive (crossing midpoint)
// Zero-crossing: (prev < midpoint) AND (curr >= midpoint)
//==============================================================================
assign zero_crossing = (adc_prev < ADC_MIDPOINT) && (adc_curr >= ADC_MIDPOINT) && adc_data_valid && bit_valid_sync;

//==============================================================================
// ADC Data Sampling
// Store previous and current ADC samples for edge detection
//==============================================================================
always @(posedge clk_60m or negedge rst_n) begin
    if (!rst_n) begin
        adc_prev <= ADC_MIDPOINT;
        adc_curr <= ADC_MIDPOINT;
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
//        = (phase_acc * 360) >> 16
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
    end else begin
        if (zero_crossing) begin
            // Zero-crossing detected: capture phase and calculate angle
            da_phase_captured <= da_phase_sync;
            
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
// Use fixed-point multiplication to avoid precision loss:
//   = (phase_diff << 8) / 360
//   ≈ (phase_diff * 256 * 91) / 32768  (91/128 ≈ 256/360)
// Simplified: (phase_diff * 91) >> 7  (right shift 7 instead of 8 for better precision)
//==============================================================================
// Direct calculation with better precision
assign phase_diff_8bit = (phase_diff > 9'd360) ? 8'd255 :  // Clip to max
                         ((phase_diff * 10'd256) / 10'd360); // Direct division for accuracy

endmodule

