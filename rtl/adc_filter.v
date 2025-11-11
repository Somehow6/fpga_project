// =============================================================================
// Module Name  : adc_filter
// Description  : ADC signal filter with adjustable voltage range clamping
//                - 9 adjustable filter levels (1-9): ±1.5V to ±2.5V
//                - Clamps ADC values outside selected range to last valid value
//                - Adds 1 clock cycle delay to output
//                - Handles consecutive out-of-range samples
// Author       : Auto-generated
// Date         : 2025-11-07
// =============================================================================

module adc_filter(
    input  wire         clk_60m      ,  // 60MHz clock
    input  wire         rst_n        ,  // Active low reset
    input  wire [3:0]   filter_level ,  // Filter range level (1-9): 1=±1.5V, 9=±2.5V
    
    // ADC input interface (raw data from hs_adc_top_60m)
    input  wire [11:0]  adc_data_in  ,  // Raw ADC data (0-4095 for ±5V)
    input  wire         adc_valid_in ,  // Raw ADC data valid flag
    
    // Filtered output interface
    output reg  [11:0]  adc_data_out ,  // Filtered ADC data (range clamped)
    output reg          adc_valid_out   // Filtered ADC data valid flag (1-cycle delay)
);

    // =========================================================================
    // Parameter Definitions
    // =========================================================================
    
    // ADC voltage to code value mapping for ±5V range (0-4095):
    //   ADC_CODE = (V_IN + 5V) / 10V × 4095
    //   
    //   For ±5V ADC: 0V → 2048 (midpoint)
    //   
    // Filter level to voltage range mapping (1..9 only):
    //   Level 1: ±1.5V   → Half-width ≈ 615  → [1433, 2663]
    //   Level 5: ±2.0V   → Half-width ≈ 819  → [1229, 2867] (default)
    //   Level 9: ±2.5V   → Half-width ≈ 1023 → [1025, 3071]
    //   
    // Formula: Half-width = 615 + (level-1) × 51
    //          ADC_MIN = 2048 - Half-width
    //          ADC_MAX = 2048 + Half-width
    
    localparam [11:0] ADC_CENTER    = 12'd2048;  // 0V center point
    localparam [11:0] HALFWIDTH_BASE = 12'd615;  // Base half-width for level 1 (±1.5V)
    localparam [11:0] HALFWIDTH_STEP = 12'd51;   // Half-width increment per level (~0.125V)
    localparam [11:0] ADC_INIT       = 12'd2048; // 0V initial value
    
    // =========================================================================
    // Internal Signals
    // =========================================================================
    
    reg [11:0]  last_valid_value;    // Cache for last valid ADC value
    reg [11:0]  adc_data_temp;       // Temporary data after range check
    reg         adc_valid_temp;      // Temporary valid after range check
    
    // Dynamic threshold calculation
    reg [11:0]  adc_min_threshold;   // Minimum threshold (dynamic)
    reg [11:0]  adc_max_threshold;   // Maximum threshold (dynamic)
    wire [11:0] half_width;          // Current half-width based on filter_level
    wire [11:0] level_index;         // (level-1), clamp to 0 when level=0 for safety
    
    // Calculate half-width: 615 + (level-1) × 51
    assign level_index = ({8'd0, filter_level} == 12'd0) ? 12'd0
                                                         : ({8'd0, filter_level} - 12'd1);
    assign half_width  = HALFWIDTH_BASE + (level_index * HALFWIDTH_STEP);
    
    // =========================================================================
    // Dynamic Threshold Calculation
    // =========================================================================
    
    // Calculate thresholds based on filter_level
    // ADC_MIN = 2048 - half_width
    // ADC_MAX = 2048 + half_width
    always @(*) begin
        adc_min_threshold = ADC_CENTER - half_width;
        adc_max_threshold = ADC_CENTER + half_width;
    end
    
    // =========================================================================
    // Range Check and Value Caching Logic
    // =========================================================================
    
    // Combinational logic: Check if input is in valid range
    // - If in range: Use input value and update cache
    // - If out of range: Use cached value (do not update cache)
    always @(*) begin
        if (adc_valid_in) begin
            // Check if ADC value is within [adc_min_threshold, adc_max_threshold]
            if ((adc_data_in >= adc_min_threshold) && (adc_data_in <= adc_max_threshold)) begin
                // In range: Output current value
                adc_data_temp  = adc_data_in;
            end else begin
                // Out of range: Output last valid value (cache)
                adc_data_temp  = last_valid_value;
            end
            adc_valid_temp = 1'b1;  // Valid flag passes through
        end else begin
            // Input not valid: Pass through invalid state
            adc_data_temp  = 12'd0;
            adc_valid_temp = 1'b0;
        end
    end
    
    // =========================================================================
    // Sequential Logic: Cache Update and Output Register (1-cycle delay)
    // =========================================================================
    
    always @(posedge clk_60m or negedge rst_n) begin
        if (!rst_n) begin
            last_valid_value <= ADC_INIT;  // Initialize to 0V (2048)
            adc_data_out     <= ADC_INIT;  // Initialize output to 0V
            adc_valid_out    <= 1'b0;      // Invalid on reset
        end else begin
            // Update output (1 clock cycle delay)
            adc_data_out  <= adc_data_temp;
            adc_valid_out <= adc_valid_temp;
            
            // Update cache: Only when input is valid AND in range
            if (adc_valid_in && 
                (adc_data_in >= adc_min_threshold) && 
                (adc_data_in <= adc_max_threshold)) begin
                last_valid_value <= adc_data_in;  // Update cache with valid value
            end
            // Note: If out of range or invalid, cache remains unchanged
        end
    end
    
endmodule

