#**************************************************************
# Altera DE1-SoC SDC settings
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 20 [get_ports CLOCK_50_i]
create_clock -period 20 [get_ports CLOCK2_50_i]
create_clock -period 20 [get_ports CLOCK3_50_i]
create_clock -period 20 [get_ports CLOCK4_50_i]

create_clock -period "27 MHz"  -name tv_27m [get_ports TD_CLK27_i]
create_clock -period "100 MHz" -name clk_dram [get_ports DRAM_CLK_o]
# AUDIO : 48kHz 384fs 32-bit data
#create_clock -period "18.432 MHz" -name clk_audxck [get_ports AUD_XCK_o]
#create_clock -period "1.536 MHz" -name clk_audbck [get_ports AUD_BCLK_io]
# VGA : 640x480@60Hz
create_clock -period "25.18 MHz" -name clk_vga [get_ports VGA_CLK_o]
# VGA : 800x600@60Hz
#create_clock -period "40.0 MHz" -name clk_vga [get_ports VGA_CLK_o]
# VGA : 1024x768@60Hz
#create_clock -period "65.0 MHz" -name clk_vga [get_ports VGA_CLK_o]
# VGA : 1280x1024@60Hz
#create_clock -period "108.0 MHz" -name clk_vga [get_ports VGA_CLK_o]


#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************
# Board Delay (Data) + Propagation Delay - Board Delay (Clock)
set_input_delay -max -clock clk_dram -0.048 [get_ports DRAM_DQ_io*]
set_input_delay -min -clock clk_dram -0.057 [get_ports DRAM_DQ_io*]

set_input_delay -max -clock tv_27m 3.692 [get_ports TD_DATA_i*]
set_input_delay -min -clock tv_27m 2.492 [get_ports TD_DATA_i*]
set_input_delay -max -clock tv_27m 3.654 [get_ports TD_HS_i]
set_input_delay -min -clock tv_27m 2.454 [get_ports TD_HS_i]
set_input_delay -max -clock tv_27m 3.656 [get_ports TD_VS_i]
set_input_delay -min -clock tv_27m 2.456 [get_ports TD_VS_i]

#**************************************************************
# Set Output Delay
#**************************************************************
# max : Board Delay (Data) - Board Delay (Clock) + tsu (External Device)
# min : Board Delay (Data) - Board Delay (Clock) - th (External Device)
set_output_delay -max -clock clk_dram 1.452  [get_ports DRAM_DQ_io*]
set_output_delay -min -clock clk_dram -0.857 [get_ports DRAM_DQ_io*]
set_output_delay -max -clock clk_dram 1.531 [get_ports DRAM_ADDR_o*]
set_output_delay -min -clock clk_dram -0.805 [get_ports DRAM_ADDR_o*]
set_output_delay -max -clock clk_dram 1.533  [get_ports DRAM_*DQM_o]
set_output_delay -min -clock clk_dram -0.805 [get_ports DRAM_*DQM_o]
set_output_delay -max -clock clk_dram 1.510  [get_ports DRAM_BA_o*]
set_output_delay -min -clock clk_dram -0.800 [get_ports DRAM_BA_o*]
set_output_delay -max -clock clk_dram 1.520  [get_ports DRAM_RAS_N_o]
set_output_delay -min -clock clk_dram -0.780 [get_ports DRAM_RAS_N_o]
set_output_delay -max -clock clk_dram 1.5000  [get_ports DRAM_CAS_N_o]
set_output_delay -min -clock clk_dram -0.800 [get_ports DRAM_CAS_N_o]
set_output_delay -max -clock clk_dram 1.545 [get_ports DRAM_WE_N_o]
set_output_delay -min -clock clk_dram -0.755 [get_ports DRAM_WE_N_o]
set_output_delay -max -clock clk_dram 1.496  [get_ports DRAM_CKE_o]
set_output_delay -min -clock clk_dram -0.804 [get_ports DRAM_CKE_o]
set_output_delay -max -clock clk_dram 1.508  [get_ports DRAM_CS_N_o]
set_output_delay -min -clock clk_dram -0.792 [get_ports DRAM_CS_N_o]

set_output_delay -max -clock clk_vga 0.220 [get_ports VGA_R_o*]
set_output_delay -min -clock clk_vga -1.506 [get_ports VGA_R_o*]
set_output_delay -max -clock clk_vga 0.212 [get_ports VGA_G_o*]
set_output_delay -min -clock clk_vga -1.519 [get_ports VGA_G_o*]
set_output_delay -max -clock clk_vga 0.264 [get_ports VGA_B_o*]
set_output_delay -min -clock clk_vga -1.519 [get_ports VGA_B_o*]
set_output_delay -max -clock clk_vga 0.215 [get_ports VGA_BLANK_N_o]
set_output_delay -min -clock clk_vga -1.485 [get_ports VGA_BLANK_N_o]



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************

