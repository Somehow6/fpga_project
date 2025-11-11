// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Tue Nov  4 17:23:23 2025
// Host        : DESKTOP-4KALS5N running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/senhaowang/project/33_hs_dual_da/prj/hs_dual_da.gen/sources_1/ip/ila_0/ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tfgg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2020.2" *)
module ila_0(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[2:0],probe3[0:0],probe4[7:0],probe5[7:0],probe6[0:0],probe7[0:0],probe8[0:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [2:0]probe2;
  input [0:0]probe3;
  input [7:0]probe4;
  input [7:0]probe5;
  input [0:0]probe6;
  input [0:0]probe7;
  input [0:0]probe8;
endmodule
