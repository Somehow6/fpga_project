// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Fri Aug 25 17:18:05 2023
// Host        : DESKTOP-HN5R6GK running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ rom_1024x10b_sim_netlist.v
// Design      : rom_1024x10b
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a35tfgg484-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "rom_1024x10b,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (clka,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [9:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [9:0]douta;

  wire [9:0]addra;
  wire clka;
  wire [9:0]douta;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [9:0]NLW_U0_doutb_UNCONNECTED;
  wire [9:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [9:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [9:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "10" *) 
  (* C_ADDRB_WIDTH = "10" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     1.229999 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "0" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "rom_1024x10b.mem" *) 
  (* C_INIT_FILE_NAME = "rom_1024x10b.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "1024" *) 
  (* C_READ_DEPTH_B = "1024" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "10" *) 
  (* C_READ_WIDTH_B = "10" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "1024" *) 
  (* C_WRITE_DEPTH_B = "1024" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "10" *) 
  (* C_WRITE_WIDTH_B = "10" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_blk_mem_gen_v8_4_4 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[9:0]),
        .eccpipece(1'b0),
        .ena(1'b0),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[9:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[9:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[9:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(1'b0),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2020.2"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
QGLtnqZzRetDH6gCWT4Js6wuLlZfrNx/VJp3sfR2NF+cxypO5AxN0oDKLJJtmdrtE/ueNDg+Qf7Z
TqBNRojORA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
B6Ger3hRvfjHkaJ+W8639Kl3TzC9TogLuklOXEiMNdc4Im+DjEUzxb3DKlzu0VW3zxZqjJ3+wsW/
LnRmPCESi5Y9eRJaLFXg79EMfoj4X+nTdHAP6yCfltBADKegZ12gpnB/8ey5yn2KA74LUtPC7jna
iyjqSfsWLGnz6UdXzwk=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BX+DxgMPRyZbYojCUR9Sk8Lq+3ZigBz4yMFHQkmurfdfDzyTPJCE827eGiPyTenK1QPVhEtf9g06
0BFXq/0COPuU1BWJwdkz1c4dE6/exDwhvEh+hPx3vRY6z8fDEf6aGVIXrHDvrmddehe7yMSIpo+k
aXHR06EEdfHCFY4TggYwhcJVXjkE+ApsVuyfmEfPmYjo8hCWyQyBsUWIOY03q1+MvUjjsmTwgs9g
fh5MY9ToaLfoJxPKdCpsqrBX4LJ+VDGFlAqIcqHTE2jCmPiToZAFXB7fzf1wDjFCBlJyFVDBGi0i
m+CouLSb7X1mvVhdDZgNrZDJMV688Bu3o54vew==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DaIU/Ddc8USbZ2mURzujJDWDH1JbHl5tFVOOQ2aVaUPIA71yyE38OXVLEtF8rNmujYH30nEeQ+FV
LVJ16aaHw+iiuaqorTM3K5KLohVlN+WlcEtSXHuPNHjw8ddqtzpaX7pH1zqZH+YmfCL5oaNLqDH4
rkBnUl0/Gm/hzSwKjYhXGQFYQ+gGP99OjXakzrAqZzp/Iq4gt+Z5902/JV9thd/isHQImJ0QyK8M
EKM579iPAfXGes2mbiNYHcvDmSPYmW1zlhOE++N1EKeea7j/msnKeyhlC+hGE4Xfn4TVvqgQexCT
rp/wS/MosY6WH1aKFQlFH2hEppA7KXUaQlvG+w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
XmWoAt4X8hrCJ5yTyug4ajJW5UhfkLNibzjihWzZ4Cr9hQSvWZoTc8rjGsLPbz6Le+/9iI5KxecS
eR0wiAO+G2IkwhZgVBeZdKoFnlnTVAyLjk9wMAFXNyJZM6b1NDbfXlPcUsC6JePvPlwwdWknkSsC
r3KvgkWAS+O3xvRmaNw=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hw3Y+rShKrXiUViyNU1/O2qv6TgheLHBnFMj1i9MUGrHYqh9pLfLYUgWR7S2vj4jv4S+Ks0BpP4p
dKEqVAFmTCfQNEUHaVcFPkOHgig6L4mhLY6HUUKJoRgiQepgLi/W3V+ZZPQSQFkB3CU4MsJzhXvR
yLcpDriZy8cnAHD87Zi5DrNGBzj3kigJeM0du6lCQbxtF5aEdoaNP+YTnIFtcqYhoYnswQlYt0sV
HKgFA8VzqzL5WYnpH7+1IKmFkJBHkyqHCa9wPK0qCKnxkuDj70YzPVqQ+cocdKU+/gNdpCOdZlci
F2HTxrgfrXndJru3TiDqu4UavqAe0MNuFp3t0w==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
XPVggoWL6aXz+MpODTOZhEUQDa0vfEnUDaYeEHXm2vGyqKJujN2c/FFAFBeBYdJATLsIsQ+BqoPc
pBbcFYXDBfOtFIW2dH6Y1OoD65KyJ/hAq8coa21kFgq4hFat5vzZ2iIfkCpTUr4vDZO7Xne8cZO9
WsHffoTCt5rS59wWm2b8I5R8Eh2TUbQg3RCyrcnD66cvcEnlXe1CNMQ4/loVJpA4IBinBf820Wjc
vw2fZbGI0jXC+ACSHOviH63Xwmn+aRV5Ppkup7IYoon/ieKapRQeASu3TTY37xSBXiInSdtMTzJ6
+4GfO4eSHVriCk/sWbuTBzfRzoSShrnHjzz5LA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2020_08", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
L78XuiswVcgO2gtebzL7SA9BC/jJGAM0v6S9pzmyqL+QYzRneiYeGyDmsW33jEVVSTuNjTXkBLY7
yTOKQruatwe4V0OLi6174saSAmPgerSV1GyLP7KhmusLV/N61avC9TPam+tekhKeE0tds4EnJ3et
4JdLh+SE4Z4pcuqCjB5MFneIYKKWDx7siU6oesAQtoSJOesfMchX63MhOjOHFP/ch+1gHv3T45hg
IGF7V7TrdREVE4f9631tlVJ1o2Dypsmo/76Itz5WCGlTMjAnWXN8IXxKN+PZ3dyt1wjrZm2P/td+
xiGszFnSLrRvw/HferwtSmRx8q0fiHZ88roGTw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kDX5kq2QEe25429T6vQqBCFvV1McKTJRYfK99ymVNK2GGvGLXSzgwJHwB2fj9rM0wme3zYYY0vQR
x+9F4L7KLlOVY6qY3LB59uDzyXBI3mMZaS905HXHJkdZHWtQWpfHhl27LqL+8FSluaD6F+KFfYOV
CwIOVuCIp/XjxFXpNBik7YiPt4kHOlDA97IXNLnYUn/g1csGqeNWce4UTne50ggWvLYGbTFGmTjT
N67TpUiGRVRCSv8Tax72GWFIMFZk3Tlp68ZUSQEybZMWX1U9XdMdtxfvNGhf8mi5jQJ2SupSzKu4
T/+53IN9T8aLePAiGBKKG1ZBj4y1ZyYA7XYvjw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 18320)
`pragma protect data_block
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
oN4nyP/HT+ypO7IH4XRABgAC2pjRayA=
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
