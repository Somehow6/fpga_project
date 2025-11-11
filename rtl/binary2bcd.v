//****************************************Copyright (c)***********************************//
// Original source from Original Point Atomic Learning Platform: www.yuanzige.com
// Technical support: http://www.openedv.com/forum.php
// Taobao store: https://zhengdianyuanzi.tmall.com
// Follow WeChat official account "Original Point Atomic" to get ZYNQ & FPGA & STM32 & LINUX resources
// Copyright reserved, piracy strictly prohibited
// Copyright(C) Original Point Atomic 2022-2032
// All rights reserved
//----------------------------------------------------------------------------------------
// File name:           binary2bcd
// Last modified Date:  2022/11/27 14:52:46
// Last Version:        V1.0
// Descriptions:        Binary to BCD converter
//----------------------------------------------------------------------------------------
// Created by:          Original Point Atomic
// Created date:        2022/11/27 14:52:46
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

  module binary2bcd(
      input   wire             sys_clk,
      input   wire             sys_rst_n,
      input   wire    [19:0]   data,
      
      output  reg     [23:0]   bcd_data        // BCD display data
  );
  //parameter define
  parameter   CNT_SHIFT_NUM = 7'd20;  			// Number of bits in input data
 //reg define
 reg [6:0]       cnt_shift;         				// Shift operation counter
 reg [43:0]      data_shift;        				// Shift register for BCD conversion
 reg             shift_flag;        				// Shift operation flag
 
 //*****************************************************
 //**                    main code                      
 //*****************************************************
 
 // cnt_shift counter logic
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         cnt_shift <= 7'd0;
     else if((cnt_shift == CNT_SHIFT_NUM + 1) && (shift_flag))
         cnt_shift <= 7'd0;
     else if(shift_flag)
         cnt_shift <= cnt_shift + 1'b1;
     else
         cnt_shift <= cnt_shift;
 end
 
 // data_shift: initialize at 0, perform BCD adjustment for 1~CNT_SHIFT_NUM
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         data_shift <= 44'd0;
     else if(cnt_shift == 7'd0)
         data_shift <= {24'b0,data};
     else if((cnt_shift <= CNT_SHIFT_NUM)&&(!shift_flag))begin
         data_shift[23:20] <= (data_shift[23:20] > 4) 
         ? (data_shift[23:20] + 2'd3):(data_shift[23:20]);
         data_shift[27:24] <= (data_shift[27:24] > 4) 
         ? (data_shift[27:24] + 2'd3):(data_shift[27:24]);
         data_shift[31:28] <= (data_shift[31:28] > 4) 
         ? (data_shift[31:28] + 2'd3):(data_shift[31:28]);
         data_shift[35:32] <= (data_shift[35:32] > 4) 
         ? (data_shift[35:32] + 2'd3):(data_shift[35:32]);
         data_shift[39:36] <= (data_shift[39:36] > 4) 
         ? (data_shift[39:36] + 2'd3):(data_shift[39:36]);
         data_shift[43:40] <= (data_shift[43:40] > 4) 
         ? (data_shift[43:40] + 2'd3):(data_shift[43:40]);
         end
     else if((cnt_shift <= CNT_SHIFT_NUM)&&(shift_flag))
         data_shift <= data_shift << 1;
     else
         data_shift <= data_shift;
 end
 
 // shift_flag: controls shift operation timing and sequence
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         shift_flag <= 1'b0;
     else
         shift_flag <= ~shift_flag;
 end
 
 // Output BCD data when conversion completes
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         bcd_data <= 24'd0;
     else if(cnt_shift == CNT_SHIFT_NUM + 1)
         bcd_data <= data_shift[43:20];
     else
         bcd_data <= bcd_data;
 end
 
 endmodule

