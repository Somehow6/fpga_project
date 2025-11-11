// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Tue Jun  6 17:48:08 2023
// Host        : DESKTOP-HL6DT46 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ rom_1024x10b_sim_netlist.v
// Design      : rom_1024x10b
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z010clg400-1
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
  (* C_FAMILY = "zynq" *) 
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
  (* C_XDEVICEFAMILY = "zynq" *) 
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
RcKfCaS7bwu4Ns9XA3SNX/d5Kq4m3Iw=
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
