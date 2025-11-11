# Time constraints

create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {key[0]}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {key[1]}]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports {key[2]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {key[3]}]
# DA output I/O Standards
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {da_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports da_clk]

# DA output Pin Assignments
set_property PACKAGE_PIN Y8 [get_ports da_clk]
set_property PACKAGE_PIN V9 [get_ports {da_data[0]}]
set_property PACKAGE_PIN W9 [get_ports {da_data[1]}]
set_property PACKAGE_PIN Y7 [get_ports {da_data[2]}]
set_property PACKAGE_PIN V8 [get_ports {da_data[3]}]
set_property PACKAGE_PIN U7 [get_ports {da_data[4]}]
set_property PACKAGE_PIN AB7 [get_ports {da_data[5]}]
set_property PACKAGE_PIN V7 [get_ports {da_data[6]}]
set_property PACKAGE_PIN AB6 [get_ports {da_data[7]}]
set_property PACKAGE_PIN AB8 [get_ports {da_data[8]}]
set_property PACKAGE_PIN AA8 [get_ports {da_data[9]}]


# LED SEG
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[0]}]

set_property PACKAGE_PIN J15 [get_ports {seg_sel[0]}]
set_property PACKAGE_PIN H17 [get_ports {seg_sel[1]}]
set_property PACKAGE_PIN H13 [get_ports {seg_sel[2]}]
set_property PACKAGE_PIN G17 [get_ports {seg_sel[3]}]
set_property PACKAGE_PIN H18 [get_ports {seg_sel[4]}]
set_property PACKAGE_PIN G18 [get_ports {seg_sel[5]}]
set_property PACKAGE_PIN H15 [get_ports {seg_led[0]}]
set_property PACKAGE_PIN G16 [get_ports {seg_led[1]}]
set_property PACKAGE_PIN L13 [get_ports {seg_led[2]}]
set_property PACKAGE_PIN G15 [get_ports {seg_led[3]}]
set_property PACKAGE_PIN K13 [get_ports {seg_led[4]}]
set_property PACKAGE_PIN G13 [get_ports {seg_led[5]}]
set_property PACKAGE_PIN H14 [get_ports {seg_led[6]}]
set_property PACKAGE_PIN J14 [get_ports {seg_led[7]}]


#----------------------USB UART---------------------------
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports uart_rxd]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS33} [get_ports uart_txd]

#led
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property PACKAGE_PIN V2 [get_ports {led[2]}]
set_property PACKAGE_PIN Y2 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

#==============================================================================
# HDMI Interface Constraints
#==============================================================================
set_property PACKAGE_PIN A18 [get_ports {tmds_data_p[0]}]
set_property PACKAGE_PIN A15 [get_ports {tmds_data_p[1]}]
set_property PACKAGE_PIN A13 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports tmds_oen]
set_property PACKAGE_PIN C20 [get_ports tmds_oen]
set_property PACKAGE_PIN B17 [get_ports tmds_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports tmds_clk_p]

#==============================================================================
# Camera Interface Constraints
#==============================================================================
create_clock -period 40.000 -name cmos_pclk [get_ports cam_pclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports cam_pclk]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports cam_rst_n]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports cam_pwdn]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[0]}]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[1]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[2]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[3]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[4]}]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[5]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[6]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[7]}]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports cam_vsync]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports cam_href]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports cam_scl]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports cam_sda]

#==============================================================================
# Note: DDR3 pin constraints are handled by MIG IP core
# The MIG will generate its own constraint file: mig_7series_0.xdc
# Make sure to include that file in your project constraints
#==============================================================================

#==============================================================================
# USB2.0 Interface Constraints (FT232H)
# Reference: usb_loopback project constraints
#==============================================================================
# USB Clock (60MHz from FT232H)
create_clock -period 16.667 -name usb_clk_60m -waveform {0.000 8.334} [get_ports usb_clk_60m]
set_property -dict {PACKAGE_PIN Y4 IOSTANDARD LVCMOS33} [get_ports usb_clk_60m]

# USB Data Bus (8-bit bidirectional)
set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS33} [get_ports {usb_data[0]}]
set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS33} [get_ports {usb_data[1]}]
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD LVCMOS33} [get_ports {usb_data[2]}]
set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS33} [get_ports {usb_data[3]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS33} [get_ports {usb_data[4]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS33} [get_ports {usb_data[5]}]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS33} [get_ports {usb_data[6]}]
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVCMOS33} [get_ports {usb_data[7]}]

# USB Control Signals
set_property -dict {PACKAGE_PIN Y3 IOSTANDARD LVCMOS33} [get_ports usb_wr_n]
set_property -dict {PACKAGE_PIN AA5 IOSTANDARD LVCMOS33} [get_ports usb_txe_n]
set_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS33} [get_ports usb_siwu_n]

#==============================================================================
# ADC Interface Constraints (CH2 - 12-bit single channel)
#==============================================================================
# ADC CH2 Clock Output (from FPGA to ADC)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports ch2_clk]

# ADC CH2 Data Input (12-bit, from ADC to FPGA)
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {ch2_data[0]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {ch2_data[1]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports {ch2_data[2]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS33} [get_ports {ch2_data[3]}]
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS33} [get_ports {ch2_data[4]}]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS33} [get_ports {ch2_data[5]}]
set_property -dict {PACKAGE_PIN K22 IOSTANDARD LVCMOS33} [get_ports {ch2_data[6]}]
set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVCMOS33} [get_ports {ch2_data[7]}]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports {ch2_data[8]}]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS33} [get_ports {ch2_data[9]}]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS33} [get_ports {ch2_data[10]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {ch2_data[11]}]

# ADC CH2 Over-Range Indicator
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports ch2_otr]

#==============================================================================
# Clock Domain Crossing Constraints
#==============================================================================
# Set asynchronous clock groups for proper timing analysis
# **UPDATED for 60MHz unified clock domain refactor**:
#   - sys_clk (50MHz) generates clk_20m via PLL for DDS and key debounce
#   - usb_clk_60m (60MHz from FT232H) is used for ADC and USB TX
#   - ADC now runs in usb_clk_60m domain (NO async FIFO, NO CDC issues!)
#   - Only CDC crossing: test_mode signal from clk_20m to usb_clk_60m (simple reg)
set_clock_groups -asynchronous -group [get_clocks sys_clk] \
                                -group [get_clocks usb_clk_60m]
                                -group [get_clocks cmos_pclk]

#==============================================================================
# Additional Timing Constraints for USB Interface
#==============================================================================
# Set input delay for USB signals (relative to usb_clk_60m)
set_input_delay -clock [get_clocks usb_clk_60m] -min 0.000 [get_ports usb_txe_n]
set_input_delay -clock [get_clocks usb_clk_60m] -max 5.000 [get_ports usb_txe_n]
set_input_delay -clock [get_clocks usb_clk_60m] -min 0.000 [get_ports {usb_data[*]}]
set_input_delay -clock [get_clocks usb_clk_60m] -max 5.000 [get_ports {usb_data[*]}]

# Set output delay for USB signals
set_output_delay -clock [get_clocks usb_clk_60m] -min -2.000 [get_ports usb_wr_n]
set_output_delay -clock [get_clocks usb_clk_60m] -max 2.000 [get_ports usb_wr_n]
set_output_delay -clock [get_clocks usb_clk_60m] -min -2.000 [get_ports {usb_data[*]}]
set_output_delay -clock [get_clocks usb_clk_60m] -max 2.000 [get_ports {usb_data[*]}]
set_output_delay -clock [get_clocks usb_clk_60m] -min -2.000 [get_ports usb_siwu_n]
set_output_delay -clock [get_clocks usb_clk_60m] -max 2.000 [get_ports usb_siwu_n]

#==============================================================================
# Configuration Bank Voltage
# Required to eliminate DRC warnings
#==============================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]