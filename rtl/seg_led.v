//****************************************Copyright (c)***********************************//
// Original source: www.yuanzige.com
// Support forum: http://www.openedv.com/forum.php
// Taobao store: https://zhengdianyuanzi.tmall.com
// Follow WeChat official account "Original Point Atomic" to get ZYNQ & FPGA & STM32 & LINUX resources
// Copyright reserved, piracy not allowed
// Copyright(C) Original Point Atomic 2022-2032
// All rights reserved
//----------------------------------------------------------------------------------------
// File name:           seg_led
// Last modified Date:  2022/11/27 14:52:46
// Last Version:        V1.0
// Descriptions:        6-digit 7-segment LED display driver
//----------------------------------------------------------------------------------------
// Created by:          Original Point Atomic
// Created date:        2022/11/27 14:52:46
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module seg_led(
    input                   clk    ,   // Clock
    input                   rst_n  ,  // Reset signal, active low

    input         [19:0]  data   , // 6-digit BCD data input
    input         [5:0]   point  , // Decimal point control for each digit
    input                   en     , // Display enable
    input                   sign   , // Sign display control ("-" sign)

    output   reg  [5:0]   seg_sel,  // Digit selection control
    output   reg  [7:0]   seg_led  // 7-segment LED segments
    );

//parameter define
localparam  MAX_NUM  = 20000 ; // Counter for 1ms at 20MHz clock

//reg define
reg    [23:0]      bcd_data_t    ;     // 24-bit BCD data with sign handling
reg    [15:0]      cnt_1ms       ;      // 1ms counter for digit scanning
reg                  cnt_1ms_flag  ;    // Flag indicating cnt_1ms overflow (1ms)
reg    [2:0]        cnt_sel       ;       // Digit selection counter (0-5)
reg    [3:0]        bcd_data_disp ;  // BCD data for current digit display
reg                  dot_disp      ;     // Decimal point display control signal

//wire define
wire   [23:0]      bcd_data      ; // 24-bit BCD data from converter     

//*****************************************************
//**                    main code
//*****************************************************


// Format 20-bit binary to 24-bit BCD (4-bit per digit, up to 6 digits)
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        bcd_data_t <= 24'b0;
    else begin
        if (bcd_data[23:20] || point[5]) // 6th digit is active
            bcd_data_t <= bcd_data; // Direct display of all 6 digits
        else if(bcd_data[19:16] || point[4]) begin // 5th digit is active or force display
			   bcd_data_t[19:0] <= bcd_data[19:0];
            if(sign)
                bcd_data_t[23:20] <= 4'd11; // Display sign in 6th digit position
            else
                bcd_data_t[23:20] <= 4'd10; // Turn off 6th digit display
        end
        else if (bcd_data[15:12] || point[3]) begin
            bcd_data_t[15:0] <= bcd_data[15:0];
            bcd_data_t[23:20] <= 4'd10; // Turn off 6th digit
            if(sign)             // Display sign in 5th digit position
                bcd_data_t[19:16] <= 4'd11;
            else                 // Turn off 5th digit
                bcd_data_t[19:16] <= 4'd10;
        end
        else if (bcd_data[11:8] || point[2]) begin
            bcd_data_t[11:0] <= bcd_data[11:0];
                             // Turn off digits 6,5,4
            bcd_data_t[23:16] <= {2{4'd10}};
            if(sign)         // Display sign in 4th digit position
                bcd_data_t[15:12] <= 4'd11;
            else             // Turn off 4th digit
                bcd_data_t[15:12] <= 4'd10;
        end
        else if (bcd_data[7:4] || point[1]) begin
            bcd_data_t[7:0] <= bcd_data[7:0];
                         // Turn off digits 6,5,4,3
            bcd_data_t[23:12] <= {3{4'd10}};
            if(sign)     // Display sign in 3rd digit position
                bcd_data_t[11:8]  <= 4'd11;
            else         // Turn off 3rd digit
                bcd_data_t[11:8] <=  4'd10;
        end
        else begin
            bcd_data_t[3:0] <= bcd_data[3:0];
                         // Turn off digits 6,5
            bcd_data_t[23:8] <= {4{4'd10}};
            if(sign)     // Display sign in 2nd digit position
                bcd_data_t[7:4] <= 4'd11;
            else         // Turn off 2nd digit
                bcd_data_t[7:4] <= 4'd10;
        end
    end
end

// 1ms counter: counts from 0 to MAX_NUM-1 and generates 1ms flag
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        cnt_1ms <= 16'd0;
        cnt_1ms_flag <= 1'b0;
     end
    else if (cnt_1ms < MAX_NUM - 1'b1) begin
        cnt_1ms <= cnt_1ms + 1'b1;
        cnt_1ms_flag <= 1'b0;
     end
    else begin
        cnt_1ms <= 16'd0;
        cnt_1ms_flag <= 1'b1;
     end
end

// cnt_sel counter: 0 to 5 cycles to select different digit segments
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0)
        cnt_sel <= 3'b0;
    else if(cnt_1ms_flag) begin
        if(cnt_sel < 3'd5)
            cnt_sel <= cnt_sel + 1'b1;
        else
            cnt_sel <= 3'b0;
    end
    else
        cnt_sel <= cnt_sel;
end

// Select digit position: choose one of 6 digit segments to display
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seg_sel  <= 6'b111111;              // Turn off all digits
        bcd_data_disp <= 4'b0;
		  dot_disp <= 1'b1;                   // Decimal point off by default
    end
    else begin
        if(en) begin
            case (cnt_sel)
                3'd0 :begin
                    seg_sel  <= 6'b111110;  // Select digit 0 position
                    bcd_data_disp <= bcd_data_t[3:0] ;  // Display digit 0 data
						  dot_disp <= ~point[0];
                end
                3'd1 :begin
                    seg_sel  <= 6'b111101;  // Select digit 1 position
                    bcd_data_disp <= bcd_data_t[7:4] ;
						  dot_disp <= ~point[1];
                end
                3'd2 :begin
                    seg_sel  <= 6'b111011;  // Select digit 2 position
                    bcd_data_disp <= bcd_data_t[11:8];
						  dot_disp <= ~point[2];
                end
                3'd3 :begin
                    seg_sel  <= 6'b110111;  // Select digit 3 position
                    bcd_data_disp <= bcd_data_t[15:12];
						  dot_disp <= ~point[3];
                end
                3'd4 :begin
                    seg_sel  <= 6'b101111;  // Select digit 4 position
                    bcd_data_disp <= bcd_data_t[19:16];
						  dot_disp <= ~point[4];
                end
                3'd5 :begin
                    seg_sel  <= 6'b011111;  // Select digit 5 position
                    bcd_data_disp <= bcd_data_t[23:20];
						  dot_disp <= ~point[5];
                end
                default :begin
                    seg_sel  <= 6'b111111;
                    bcd_data_disp <= 4'b0;
						  dot_disp <= 1;
                end
            endcase
        end
        else begin
            seg_sel  <= 6'b111111;          // Turn off all digits when en=0
            bcd_data_disp <= 4'b0;
				dot_disp <= 1;
        end
    end
end

// 7-segment decoder: convert BCD to display segments
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        seg_led <= 8'hff;
    else begin
        case (bcd_data_disp)
            4'd0 : seg_led <= {dot_disp,7'b1000000}; //??????? 0
            4'd1 : seg_led <= {dot_disp,7'b1111001}; //??????? 1
            4'd2 : seg_led <= {dot_disp,7'b0100100}; //??????? 2
            4'd3 : seg_led <= {dot_disp,7'b0110000}; //??????? 3
            4'd4 : seg_led <= {dot_disp,7'b0011001}; //??????? 4
            4'd5 : seg_led <= {dot_disp,7'b0010010}; //??????? 5
            4'd6 : seg_led <= {dot_disp,7'b0000010}; //??????? 6
            4'd7 : seg_led <= {dot_disp,7'b1111000}; //??????? 7
            4'd8 : seg_led <= {dot_disp,7'b0000000}; //??????? 8
            4'd9 : seg_led <= {dot_disp,7'b0010000}; //??????? 9
            4'd10: seg_led <= 8'b11111111;         //??????��????
            4'd11: seg_led <= 8'b10111111;         //???????(-)
            default:seg_led <= 8'hff;
        endcase
    end
end

// Binary to BCD converter instantiation
binary2bcd u_binary2bcd(  
    .sys_clk        (clk     ),
    .sys_rst_n     (rst_n   ),
                
    .data            (data    ),
    .bcd_data     (bcd_data)
    );

endmodule 

