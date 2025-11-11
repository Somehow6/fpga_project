// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Wed Jun 21 10:23:05 2023
// Host        : DESKTOP-HL6DT46 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ rom_1024x10b_sim_netlist.v
// Design      : rom_1024x10b
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z020clg400-2
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
1sV1bQgV9vRPrz3Mfh6HJmdV28H221w=
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
