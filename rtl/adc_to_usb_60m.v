//****************************************Copyright (c)***********************************//
// File name:           adc_to_usb_60m
// Last modified Date:  2025/11/05
// Last Version:        V6.0 (模式2分帧版本 - 4MB/s速率匹配)
// Descriptions:        ADC to USB data converter - FIFO写接口版本
//                      Converts 12-bit ADC data into two 8-bit bytes for USB transmission
//                      Byte1: adc_data[11:4] (high 8 bits)
//                      Byte2: {4'b0000, adc_data[3:0]} (low 4 bits, zero-padded)
//                      
//                      **核心优势**: 
//                      - 60MHz统一时钟域，无CDC问题
//                      - 写入同步FIFO，解耦生产者消费者
//                      - 模式0/1/2速率完全匹配（4 MB/s）
//                      - 模式2支持分帧传输（每帧260字节：帧头2B + 数据256B + 帧尾2B）
//                      - 状态机清晰，易于理解和调试
//                      - 支持3种测试模式
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module adc_to_usb_60m#(
    // 每N个零交叉输出一次相位（默认1：每周期输出一次，≈0.43MB/s）
    parameter integer PHASE_DECIM_N = 1,
    // 调试包发送间隔（clk_60m周期），默认1ms=60000
    parameter integer DEBUG_PKT_INTERVAL = 60000,
    // ADC抽取因子：60MHz → 2MHz = 30
    parameter integer ADC_DECIM_N = 30,
    // 预滤波可选打一拍寄存（默认关闭）
    parameter integer PREF_PIPE_REG = 0
)(
    input                clk           ,  // 60MHz clock (from FT232H)
    input                rst_n         ,  // System reset (active low)
    input       [1:0]    test_mode     ,  // Test mode: 0=USB test, 1=ADC test, 2=Normal
    // ADC interface
    input       [11:0]   adc_data      ,  // 12-bit ADC data (or test counter)
    input                adc_data_valid,  // ADC data valid flag (180ns wide)
    input                adc_otr_flag  ,  // ADC over-range flag (for monitoring)
    // Data mode and phase/debug data interface
    input       [1:0]    data_mode     ,  // Data mode: 0=ADC, 1=Phase, 2=Debug
    input       [11:0]   phase_diff_12bit, // 12-bit phase (0-4095 for 0-360 deg)
    input       [11:0]   adc_midpoint  ,  // Dynamic ADC midpoint (from phase_detector_v2)
    input       [15:0]   zero_cross_count, // Zero-crossing counter (from phase_detector_v2)
    input       [11:0]   adc_min       ,  // ADC minimum value (from phase_detector_v2)
    input       [11:0]   adc_max       ,  // ADC maximum value (from phase_detector_v2)
    input                phase_strobe  ,  // Phase strobe (1-cycle at zero-crossing)
    // FIFO write interface
    output reg  [7:0]    fifo_din      ,  // FIFO write data
    output reg           fifo_wr_en    ,  // FIFO write enable
    input                fifo_full        // FIFO full flag
);

//==============================================================================
// Data mode behavior:
//   data_mode = 0 (ADC Mode):
//     Uses test_mode to select ADC data source:
//       test_mode 0: USB test counter (8-bit, 4 MB/s, no header)
//       test_mode 1: ADC test counter (12-bit, 4 MB/s, with ONE-TIME header)
//       test_mode 2: Real ADC data (12-bit, 4 MB/s, with FRAME structure)
//
//   data_mode = 1 (Phase Mode):
//     按零交叉事件输出12位相位（可按PHASE_DECIM_N抽取），无分帧
//     速率：≈(215k / PHASE_DECIM_N) samples/s（≈0.43MB/s @PHASE_DECIM_N=1）
//     格式：两字节：[high 8-bit] [low 4-bit + padding]
//
//   data_mode = 2 (Debug Packet Mode):
//     Sends 13-byte debug packet at 1kHz rate (13 KB/s)
//     Packet format:
//       [0-1]   Header: 0xAA 0x55
//       [2-3]   Phase (12-bit): [high 8] [low 4 + padding]
//       [4-5]   Midpoint (12-bit): [high 8] [low 4 + padding]
//       [6-7]   Min (12-bit): [high 8] [low 4 + padding]
//       [8-9]   Max (12-bit): [high 8] [low 4 + padding]
//       [10-11] Zero-cross count (16-bit): [high 8] [low 8]
//       [12]    Checksum (8-bit): sum of all bytes [7:0]
//==============================================================================

//==============================================================================
// Frame Structure Configuration (Mode 2 only)
// Each frame: [Header 2B] + [Data 256B = 128 samples × 2B] + [Trailer 2B] = 260B
// Mode 0/1: No framing (continuous data)
//==============================================================================
parameter START_HEADER1   = 8'hAA;    // Frame header byte 1
parameter START_HEADER2   = 8'h55;    // Frame header byte 2
parameter FRAME_TRAILER1  = 8'h55;    // Frame trailer byte 1
parameter FRAME_TRAILER2  = 8'hAA;    // Frame trailer byte 2
parameter SAMPLES_PER_FRAME = 7'd128; // 128 samples per frame (Mode 2 only)

//localparam define
localparam IDLE     = 3'b000;         // Idle state (waiting for data)
localparam HEADER1  = 3'b001;         // Write frame header byte 1
localparam HEADER2  = 3'b010;         // Write frame header byte 2
localparam BYTE1    = 3'b011;         // Write high byte (bits [11:4])
localparam BYTE2    = 3'b100;         // Write low byte (bits [3:0] with padding)
localparam TRAILER1 = 3'b101;         // Write frame trailer byte 1 (Mode 2 only)
localparam TRAILER2 = 3'b110;         // Write frame trailer byte 2 (Mode 2 only)

//reg define
reg [2:0]  cur_state      ;           // Current state
reg [2:0]  next_state     ;           // Next state
reg [11:0] adc_data_reg   ;           // Register holding captured ADC data
reg        header_sent    ;           // Flag: header has been sent (Mode 1 only, will be removed)
reg        data_captured  ;           // Flag: data has been captured and ready to write
reg [11:0] adc_data_pending;          // Buffer for next sample when busy
reg        data_pending   ;           // Flag: pending buffer has data
reg [6:0]  sample_count   ;           // Sample counter for Mode 2 framing (0-127)

//==============================================================================
// ADC Moving-Average Decimator (MA-ADC_DECIM_N)
// 60MHz 输入 → 每 ADC_DECIM_N 个样本输出一次平均值与脉冲，有效等效2Msps
//==============================================================================
// ---- 预滤波：Median-of-3 + OTR替换 ------------------------------------------
reg  [11:0] z0, z1, z2;                            // 3抽头移位寄存器
wire [11:0] med3_a  = (z0 > z1) ? z0 : z1;         // max(z0,z1)
wire [11:0] med3_b  = (z0 > z1) ? z1 : z0;         // min(z0,z1)
wire [11:0] med3_hi = (med3_a > z2) ? med3_a : z2; // max(max(z0,z1),z2)
wire [11:0] med3_lo = (med3_b > z2) ? z2 : med3_b; // min(min(z0,z1),z2)
wire [11:0] med3    = (z0 + z1 + z2) - med3_hi - med3_lo; // median

reg  [11:0] med3_q;                                 // 可选打一拍
wire [11:0] pre_med  = (PREF_PIPE_REG!=0) ? med3_q : med3;
wire [11:0] sample_in_pref = adc_otr_flag ? adc_midpoint : pre_med;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 用中点初始化，避免冷启动尖峰
        z0 <= 12'd2048;
        z1 <= 12'd2048;
        z2 <= 12'd2048;
        med3_q <= 12'd2048;
    end else begin
        if (adc_data_valid) begin
            z2 <= z1;
            z1 <= z0;
            z0 <= adc_data;
        end
        if (PREF_PIPE_REG!=0)
            med3_q <= med3;
    end
end

reg  [19:0] adc_sum_reg;                             // Running sum
reg  [11:0] adc_ringbuf [0:ADC_DECIM_N-1];           // Circular buffer
reg  [4:0]  adc_rb_idx;                               // 0..29
reg  [4:0]  adc_decim_cnt;                            // 0..29
reg  [11:0] adc_data_decim;                           // Decimated sample
reg         adc_valid_decim_pulse;                    // One-cycle pulse

integer i_adc;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_sum_reg           <= 20'd0;
        adc_rb_idx            <= 5'd0;
        adc_decim_cnt         <= 5'd0;
        adc_data_decim        <= 12'd0;
        adc_valid_decim_pulse <= 1'b0;
        for (i_adc = 0; i_adc < ADC_DECIM_N; i_adc = i_adc + 1) begin
            adc_ringbuf[i_adc] <= 12'd0;
        end
    end else begin
        adc_valid_decim_pulse <= 1'b0;
        if (adc_data_valid) begin
            // pop oldest, push newest
            adc_sum_reg                 <= adc_sum_reg + sample_in_pref - adc_ringbuf[adc_rb_idx];
            adc_ringbuf[adc_rb_idx]     <= sample_in_pref;
            // advance index
            if (adc_rb_idx == ADC_DECIM_N-1)
                adc_rb_idx <= 5'd0;
            else
                adc_rb_idx <= adc_rb_idx + 5'd1;
            // decimation counter
            if (adc_decim_cnt == ADC_DECIM_N-1) begin
                adc_decim_cnt         <= 5'd0;
                // round(sum/N)
                adc_data_decim        <= (adc_sum_reg + (ADC_DECIM_N>>1)) / ADC_DECIM_N;
                adc_valid_decim_pulse <= 1'b1;
            end else begin
                adc_decim_cnt <= adc_decim_cnt + 5'd1;
            end
        end
    end
end

//==============================================================================
// Mode 0: USB Test Counter (8-bit counter, no header)
// **Purpose**: Simulates ADC data rate to test complete data path
// **Rate**: 4 MB/s (same as ADC: 2MHz sampling × 2 bytes/sample)
//   - Write every 15 clocks: 60MHz / 15 = 4 MB/s
//   - Counter increments CONTINUOUSLY (simulates ADC, cannot pause)
//   - If FIFO full, data is LOST (same as real ADC overflow)
//==============================================================================
reg [7:0] usb_test_counter;
reg [3:0] mode0_wr_div;  // Write divider: 0-14 (writes when ==14)

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        usb_test_counter <= 8'd0;
        mode0_wr_div <= 4'd0;
    end else if (test_mode == 2'b00) begin
        // Divider always increments (simulates continuous ADC)
        if (mode0_wr_div == 4'd14) begin
            mode0_wr_div <= 4'd0;
            usb_test_counter <= usb_test_counter + 8'd1;
        end else begin
            mode0_wr_div <= mode0_wr_div + 4'd1;
        end
    end else begin
        // Not in Mode 0: reset
        usb_test_counter <= 8'd0;
        mode0_wr_div <= 4'd0;
    end
end

//==============================================================================
// Data Mode 1: Phase Data Transmission (12-bit phase with frame structure)
// Frame format: [0xAA 0x55] + 128 samples × 2B + [0x55 0xAA]
//==============================================================================
localparam P_IDLE     = 3'b000;
localparam P_HEADER1  = 3'b001;
localparam P_HEADER2  = 3'b010;
localparam P_BYTE1    = 3'b011;
localparam P_BYTE2    = 3'b100;
localparam P_TRAILER1 = 3'b101;
localparam P_TRAILER2 = 3'b110;

reg [2:0]  phase_state, phase_next_state;
reg [6:0]  phase_sample_count;         // 0-127 samples per frame
reg [15:0] phase_decim_cnt;           // Decimation counter
reg        phase_sample_ready;        // Current sample available
reg [11:0] phase_sample_curr;         // Current sample data
reg        phase_sample_pending_valid;// Pending sample available
reg [11:0] phase_sample_pending;      // Pending sample data

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_decim_cnt            <= 16'd0;
        phase_sample_ready         <= 1'b0;
        phase_sample_curr          <= 12'd0;
        phase_sample_pending_valid <= 1'b0;
        phase_sample_pending       <= 12'd0;
    end else if (data_mode == 2'd1) begin
        if (phase_strobe) begin
            if (phase_decim_cnt == PHASE_DECIM_N-1) begin
                phase_decim_cnt <= 16'd0;
                if (!phase_sample_ready) begin
                    phase_sample_curr  <= phase_diff_12bit;
                    phase_sample_ready <= 1'b1;
                end else if (!phase_sample_pending_valid) begin
                    phase_sample_pending       <= phase_diff_12bit;
                    phase_sample_pending_valid <= 1'b1;
                end else begin
                    phase_sample_pending       <= phase_diff_12bit;  // overwrite with latest
                    phase_sample_pending_valid <= 1'b1;
                end
            end else begin
                phase_decim_cnt <= phase_decim_cnt + 16'd1;
            end
        end
        if (phase_state == P_BYTE2 && !fifo_full) begin
            if (phase_sample_pending_valid) begin
                phase_sample_curr          <= phase_sample_pending;
                phase_sample_pending_valid <= 1'b0;
                phase_sample_ready         <= 1'b1;
            end else begin
                phase_sample_ready <= 1'b0;
            end
        end
    end else begin
        phase_decim_cnt            <= 16'd0;
        phase_sample_ready         <= 1'b0;
        phase_sample_curr          <= 12'd0;
        phase_sample_pending_valid <= 1'b0;
        phase_sample_pending       <= 12'd0;
    end
end

// Phase frame state machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phase_state        <= P_IDLE;
        phase_sample_count <= 7'd0;
    end else if (data_mode != 2'd1) begin
        phase_state        <= P_IDLE;
        phase_sample_count <= 7'd0;
    end else begin
        phase_state <= phase_next_state;
        if (phase_state == P_BYTE2 && !fifo_full) begin
            if (phase_sample_count == 7'd127)
                phase_sample_count <= 7'd0;
            else
                phase_sample_count <= phase_sample_count + 7'd1;
        end
    end
end

always @(*) begin
    phase_next_state = phase_state;
    case (phase_state)
        P_IDLE: begin
            if (data_mode != 2'd1)
                phase_next_state = P_IDLE;
            else if (phase_sample_ready) begin
                if (phase_sample_count == 7'd0)
                    phase_next_state = P_HEADER1;
                else
                    phase_next_state = P_BYTE1;
            end else
                phase_next_state = P_IDLE;
        end
        P_HEADER1: begin
            if (!fifo_full)
                phase_next_state = P_HEADER2;
        end
        P_HEADER2: begin
            if (!fifo_full) begin
                if (phase_sample_ready)
                    phase_next_state = P_BYTE1;
                else
                    phase_next_state = P_IDLE;
            end
        end
        P_BYTE1: begin
            if (!fifo_full)
                phase_next_state = P_BYTE2;
        end
        P_BYTE2: begin
            if (!fifo_full) begin
                if (phase_sample_count == 7'd127)
                    phase_next_state = P_TRAILER1;
                else
                    phase_next_state = P_IDLE;
            end
        end
        P_TRAILER1: begin
            if (!fifo_full)
                phase_next_state = P_TRAILER2;
        end
        P_TRAILER2: begin
            if (!fifo_full) begin
                if (phase_sample_ready)
                    phase_next_state = P_HEADER1;
                else
                    phase_next_state = P_IDLE;
            end
        end
        default: phase_next_state = P_IDLE;
    endcase
end

//==============================================================================
// Data Mode 2: Debug Packet Transmission (13 bytes, 1kHz)
// **Purpose**: Transmit complete debug information for diagnostics
// **Rate**: 13 KB/s (13 bytes @ 1kHz)
//   - Packet sent every 60,000 clocks (1ms @ 60MHz)
//==============================================================================
// 1ms @ 60MHz = 1kHz packet rate（可参数化）
localparam [15:0] DEBUG_PKT_INTERVAL_L = DEBUG_PKT_INTERVAL[15:0];

reg [15:0] debug_pkt_timer;   // Packet interval timer (0-59999)
reg [3:0]  debug_byte_idx;    // Current byte index (0-12)
reg        debug_pkt_active;  // Packet transmission active flag
reg [7:0]  debug_checksum;    // Accumulated checksum

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        debug_pkt_timer  <= 16'd0;
        debug_byte_idx   <= 4'd0;
        debug_pkt_active <= 1'b0;
        debug_checksum   <= 8'd0;
    end else if (data_mode == 2'd2) begin
        // Debug packet mode
        if (!debug_pkt_active) begin
            // Waiting for next packet interval
            if (debug_pkt_timer == DEBUG_PKT_INTERVAL_L - 1) begin
                debug_pkt_timer  <= 16'd0;
                debug_pkt_active <= 1'b1;
                debug_byte_idx   <= 4'd0;
                debug_checksum   <= 8'd0;
            end else begin
                debug_pkt_timer <= debug_pkt_timer + 16'd1;
            end
        end else begin
            // Transmitting packet
            if (!fifo_full) begin
                if (debug_byte_idx == 4'd12) begin
                    // Last byte sent, finish packet
                    debug_pkt_active <= 1'b0;
                    debug_byte_idx   <= 4'd0;
                end else begin
                    debug_byte_idx <= debug_byte_idx + 4'd1;
                end
            end
        end
    end else begin
        // Not in Debug mode: reset
        debug_pkt_timer  <= 16'd0;
        debug_byte_idx   <= 4'd0;
        debug_pkt_active <= 1'b0;
        debug_checksum   <= 8'd0;
    end
end

//*****************************************************
//**                    main code
//*****************************************************

//==============================================================================
// Header Sent Flag (for Mode 1 only - continuous data with one-time header)
// Mode 2 uses per-frame headers, so this flag is checked differently
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        header_sent <= 1'b0;
    else if (cur_state == HEADER2 && !fifo_full && test_mode == 2'b01)
        header_sent <= 1'b1;  // Only set for Mode 1
end

//==============================================================================
// Sample Counter for Mode 2 Framing
// Counts 0-127 samples per frame
// Increments after each BYTE2 write, resets after TRAILER2
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sample_count <= 7'd0;
    end else if (test_mode == 2'b10) begin
        // Mode 2: Frame-based counting
        if (cur_state == BYTE2 && !fifo_full) begin
            // Increment after writing low byte
            sample_count <= sample_count + 7'd1;
        end else if (cur_state == TRAILER2 && !fifo_full) begin
            // Reset after completing frame trailer
            sample_count <= 7'd0;
        end
    end else begin
        // Mode 0/1: No framing, keep counter at 0
        sample_count <= 7'd0;
    end
end

//==============================================================================
// State Transition
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end

//==============================================================================
// Data Capture Logic - With Pending Buffer
// 
// 目的：持续捕获ADC数据，即使状态机忙碌也不丢失样本
// 策略（修正版）：
//   - ADC valid上升沿：立即写入pending缓冲
//   - 状态机消费数据后（BYTE2完成）：如果有pending数据，立即转移到current
//   - 这样保证数据流连续，状态机可以持续发送而不必返回IDLE等待
//==============================================================================
reg adc_data_valid_r;  // Registered version for edge detection

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        adc_data_valid_r <= 1'b0;
    else
        adc_data_valid_r <= adc_data_valid;
end

// Edge detection: rising edge of data_valid
wire adc_data_valid_rise;
assign adc_data_valid_rise = adc_data_valid && !adc_data_valid_r;

// Two-stage capture: pending + current
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_data_reg      <= 12'd0;
        adc_data_pending  <= 12'd0;
        data_captured     <= 1'b0;
        data_pending      <= 1'b0;
    end else begin
        // 1) 捕获样本到pending：
        //    - test_mode==2'b10(真实ADC)：使用抽取脉冲与抽取样本
        //    - 其他模式：沿用原始上升沿与原始样本
        if ((test_mode == 2'b10) ? adc_valid_decim_pulse : adc_data_valid_rise) begin
            adc_data_pending <= (test_mode == 2'b10) ? adc_data_decim : adc_data;
            data_pending     <= 1'b1;
        end

        // 2) Data transfer logic: pending → current
        // Priority: if consuming current data AND have pending, immediately refill
        if (cur_state == BYTE2 && !fifo_full) begin
            // Just finished sending a sample
            if (data_pending) begin
                // Refill immediately from pending
                adc_data_reg  <= adc_data_pending;
                data_captured <= 1'b1;
                data_pending  <= 1'b0;
            end else begin
                // No pending data, mark current as empty
                data_captured <= 1'b0;
            end
        end
        // If current is empty and have pending, fill it
        else if (!data_captured && data_pending) begin
            adc_data_reg  <= adc_data_pending;
            data_captured <= 1'b1;
            data_pending  <= 1'b0;
        end
    end
end

//==============================================================================
// Next State Logic
// 
// **Mode 0**: Bypass state machine, always in IDLE
// **Mode 1**: One-time header + continuous data (IDLE → HEADER1 → HEADER2 → [BYTE1 → BYTE2 → IDLE]*)
// **Mode 2**: Per-frame header + 128 samples + trailer (IDLE → HEADER1 → HEADER2 → [BYTE1 → BYTE2]*128 → TRAILER1 → TRAILER2 → IDLE)
//
// **Blocking Strategy**: Stay in current state if FIFO is full
//==============================================================================
always @(*) begin
    // Mode 0: Bypass state machine, always write counter
    if (test_mode == 2'b00) begin
        next_state = IDLE;  // Stay in IDLE, write counter directly
    end
    // Mode 1: One-time header, then continuous data
    else if (test_mode == 2'b01) begin
        case (cur_state)
            IDLE: begin
                if (data_captured || data_pending) begin
                    if (!header_sent)
                        next_state = HEADER1;  // Send header once
                    else
                        next_state = BYTE1;    // Then continuous data
                end else begin
                    next_state = IDLE;
                end
            end
            
            HEADER1: begin
                if (!fifo_full)
                    next_state = HEADER2;
                else
                    next_state = HEADER1;
            end
            
            HEADER2: begin
                if (!fifo_full)
                    next_state = BYTE1;
                else
                    next_state = HEADER2;
            end
            
            BYTE1: begin
                if (!fifo_full)
                    next_state = BYTE2;
                else
                    next_state = BYTE1;
            end
            
            BYTE2: begin
                if (!fifo_full)
                    next_state = IDLE;  // Back to IDLE for next sample
                else
                    next_state = BYTE2;
            end
            
            default:
                next_state = IDLE;
        endcase
    end
    // Mode 2: Frame-based with header and trailer
    else begin  // test_mode == 2'b10
        case (cur_state)
            IDLE: begin
                if (data_captured || data_pending) begin
                    // Determine if we need to start a new frame or continue current frame
                    if (sample_count == 7'd0)
                        next_state = HEADER1;  // Start new frame with header
                    else
                        next_state = BYTE1;    // Continue current frame with data
                end else begin
                    next_state = IDLE;
                end
            end
            
            HEADER1: begin
                if (!fifo_full)
                    next_state = HEADER2;
                else
                    next_state = HEADER1;
            end
            
            HEADER2: begin
                if (!fifo_full) begin
                    // After header, check if data is ready
                    if (data_captured || data_pending)
                        next_state = BYTE1;
                    else
                        next_state = IDLE;  // Wait for first sample
                end else begin
                    next_state = HEADER2;
                end
            end
            
            BYTE1: begin
                if (!fifo_full)
                    next_state = BYTE2;
                else
                    next_state = BYTE1;
            end
            
            BYTE2: begin
                if (!fifo_full) begin
                    // Check if frame will be complete AFTER this sample (sample_count will increment to 128)
                    // Current sample_count + 1 == 128 means we've written 128 samples (0-127)
                    if (sample_count == 7'd127)
                        next_state = TRAILER1;  // Frame complete (128 samples written), send trailer
                    else
                        next_state = IDLE;      // Always go to IDLE between samples (same as Mode 1)
                end else begin
                    next_state = BYTE2;
                end
            end
            
            TRAILER1: begin
                if (!fifo_full)
                    next_state = TRAILER2;
                else
                    next_state = TRAILER1;
            end
            
            TRAILER2: begin
                if (!fifo_full) begin
                    // After trailer, check if data is ready for next frame
                    if (data_captured || data_pending)
                        next_state = HEADER1;  // Start next frame immediately
                    else
                        next_state = IDLE;     // Wait for data
                end else begin
                    next_state = TRAILER2;
                end
            end
            
            default:
                next_state = IDLE;
        endcase
    end
end

//==============================================================================
// FIFO Write Logic
// fifo_din and fifo_wr_en are registered outputs
// wr_en is asserted when we have data and FIFO is not full
//
// Priority order (data_mode based):
//   data_mode = 0 (ADC): Use test_mode (0=USB test, 1/2=ADC data state machine)
//   data_mode = 1 (Phase): 12-bit phase transmission
//   data_mode = 2 (Debug): Debug packet transmission
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_din   <= 8'd0;
        fifo_wr_en <= 1'b0;
    end else begin
        // Data mode 1: Phase mode (12-bit with framing)
        if (data_mode == 2'd1) begin
            case (phase_state)
                P_HEADER1: begin
                    fifo_din   <= START_HEADER1;
                    fifo_wr_en <= !fifo_full;
                end
                P_HEADER2: begin
                    fifo_din   <= START_HEADER2;
                    fifo_wr_en <= !fifo_full;
                end
                P_BYTE1: begin
                    fifo_din   <= phase_sample_curr[11:4];
                    fifo_wr_en <= !fifo_full && phase_sample_ready;
                end
                P_BYTE2: begin
                    fifo_din   <= {4'b0000, phase_sample_curr[3:0]};
                    fifo_wr_en <= !fifo_full && phase_sample_ready;
                end
                P_TRAILER1: begin
                    fifo_din   <= FRAME_TRAILER1;
                    fifo_wr_en <= !fifo_full;
                end
                P_TRAILER2: begin
                    fifo_din   <= FRAME_TRAILER2;
                    fifo_wr_en <= !fifo_full;
                end
                default: begin
                    fifo_din   <= 8'd0;
                    fifo_wr_en <= 1'b0;
                end
            endcase
        end
        // Data mode 2: Debug packet mode
        else if (1'b0 /* disabled: mode2 now uses ADC path */) begin
            if (debug_pkt_active && !fifo_full) begin
                case (debug_byte_idx)
                    4'd0:  fifo_din <= 8'hAA;                               // Header 1
                    4'd1:  fifo_din <= 8'h55;                               // Header 2
                    4'd2:  fifo_din <= phase_diff_12bit[11:4];              // Phase high byte
                    4'd3:  fifo_din <= {4'b0000, phase_diff_12bit[3:0]};    // Phase low byte
                    4'd4:  fifo_din <= adc_midpoint[11:4];                  // Midpoint high byte
                    4'd5:  fifo_din <= {4'b0000, adc_midpoint[3:0]};        // Midpoint low byte
                    4'd6:  fifo_din <= adc_min[11:4];                       // Min high byte
                    4'd7:  fifo_din <= {4'b0000, adc_min[3:0]};             // Min low byte
                    4'd8:  fifo_din <= adc_max[11:4];                       // Max high byte
                    4'd9:  fifo_din <= {4'b0000, adc_max[3:0]};             // Max low byte
                    4'd10: fifo_din <= zero_cross_count[15:8];              // Count high byte
                    4'd11: fifo_din <= zero_cross_count[7:0];               // Count low byte
                    4'd12: begin
                        // Calculate checksum: sum of all previous bytes
                        fifo_din <= 8'hAA + 8'h55 + 
                                   phase_diff_12bit[11:4] + {4'b0000, phase_diff_12bit[3:0]} +
                                   adc_midpoint[11:4] + {4'b0000, adc_midpoint[3:0]} +
                                   adc_min[11:4] + {4'b0000, adc_min[3:0]} +
                                   adc_max[11:4] + {4'b0000, adc_max[3:0]} +
                                   zero_cross_count[15:8] + zero_cross_count[7:0];
                    end
                    default: fifo_din <= 8'd0;
                endcase
                fifo_wr_en <= 1'b1;
            end else begin
                fifo_din   <= 8'd0;
                fifo_wr_en <= 1'b0;
            end
        end
        // Data mode 0: ADC mode (use test_mode)
        else if (test_mode == 2'b00) begin
            // Mode 0: Rate-limited counter write (4 MB/s)
            fifo_din   <= usb_test_counter;
            // Only write every 15th clock cycle (when mode0_wr_div==14)
            fifo_wr_en <= (mode0_wr_div == 4'd14) && !fifo_full;
        end
        // test_mode 1/2: State machine controlled write
        else begin
            case (cur_state)
                IDLE: begin
                    fifo_din   <= 8'd0;
                    fifo_wr_en <= 1'b0;
                end
                
                HEADER1: begin
                    fifo_din   <= START_HEADER1;       // 0xAA
                    fifo_wr_en <= !fifo_full;          // Write if not full
                end
                
                HEADER2: begin
                    fifo_din   <= START_HEADER2;       // 0x55
                    fifo_wr_en <= !fifo_full;          // Write if not full
                end
                
                BYTE1: begin
                    fifo_din   <= adc_data_reg[11:4];  // High 8 bits
                    fifo_wr_en <= !fifo_full;          // Write if not full
                end
                
                BYTE2: begin
                    fifo_din   <= {4'b0000, adc_data_reg[3:0]};  // Low 4 bits
                    fifo_wr_en <= !fifo_full;                    // Write if not full
                end
                
                TRAILER1: begin
                    fifo_din   <= FRAME_TRAILER1;      // 0x55 (Mode 2 only)
                    fifo_wr_en <= !fifo_full;          // Write if not full
                end
                
                TRAILER2: begin
                    fifo_din   <= FRAME_TRAILER2;      // 0xAA (Mode 2 only)
                    fifo_wr_en <= !fifo_full;          // Write if not full
                end
                
                default: begin
                    fifo_din   <= 8'd0;
                    fifo_wr_en <= 1'b0;
                end
            endcase
        end
    end
end

endmodule
