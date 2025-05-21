# Copyright (C) 2017  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel MegaCore Function License Agreement, or other 
# applicable license agreement, including, without limitation, 
# that your use is for the sole purpose of programming logic 
# devices manufactured by Intel and sold by Intel or its 
# authorized distributors.  Please refer to the applicable 
# agreement for further details.

# Quartus Prime Version 17.0.0 Build 595 04/25/2017 SJ Standard Edition
# File: /media/sebastien/Data/Projects/SoCF_Cours/Test/quartus/DE1_SoC.tcl
# Generated on: Tue Feb  6 08:44:25 2018

package require ::quartus::project

set_location_assignment PIN_AJ4 -to ADC_CS_N_o
set_location_assignment PIN_AK4 -to ADC_DIN_o
set_location_assignment PIN_AK3 -to ADC_DOUT_i
set_location_assignment PIN_AK2 -to ADC_SCLK_o
set_location_assignment PIN_K7 -to AUD_ADCDAT_i
set_location_assignment PIN_K8 -to AUD_ADCLRCK_io
set_location_assignment PIN_H7 -to AUD_BCLK_io
set_location_assignment PIN_J7 -to AUD_DACDAT_o
set_location_assignment PIN_H8 -to AUD_DACLRCK_io
set_location_assignment PIN_G7 -to AUD_XCK_o
set_location_assignment PIN_AF14 -to CLOCK_50_i
set_location_assignment PIN_AA16 -to CLOCK2_50_i
set_location_assignment PIN_Y26 -to CLOCK3_50_i
set_location_assignment PIN_K14 -to CLOCK4_50_i
set_location_assignment PIN_AK14 -to DRAM_ADDR_o[0]
set_location_assignment PIN_AH14 -to DRAM_ADDR_o[1]
set_location_assignment PIN_AG15 -to DRAM_ADDR_o[2]
set_location_assignment PIN_AE14 -to DRAM_ADDR_o[3]
set_location_assignment PIN_AB15 -to DRAM_ADDR_o[4]
set_location_assignment PIN_AC14 -to DRAM_ADDR_o[5]
set_location_assignment PIN_AD14 -to DRAM_ADDR_o[6]
set_location_assignment PIN_AF15 -to DRAM_ADDR_o[7]
set_location_assignment PIN_AH15 -to DRAM_ADDR_o[8]
set_location_assignment PIN_AG13 -to DRAM_ADDR_o[9]
set_location_assignment PIN_AG12 -to DRAM_ADDR_o[10]
set_location_assignment PIN_AH13 -to DRAM_ADDR_o[11]
set_location_assignment PIN_AJ14 -to DRAM_ADDR_o[12]
set_location_assignment PIN_AF13 -to DRAM_BA_o[0]
set_location_assignment PIN_AJ12 -to DRAM_BA_o[1]
set_location_assignment PIN_AF11 -to DRAM_CAS_N_o
set_location_assignment PIN_AK13 -to DRAM_CKE_o
set_location_assignment PIN_AH12 -to DRAM_CLK_o
set_location_assignment PIN_AG11 -to DRAM_CS_N_o
set_location_assignment PIN_AK6 -to DRAM_DQ_io[0]
set_location_assignment PIN_AJ7 -to DRAM_DQ_io[1]
set_location_assignment PIN_AK7 -to DRAM_DQ_io[2]
set_location_assignment PIN_AK8 -to DRAM_DQ_io[3]
set_location_assignment PIN_AK9 -to DRAM_DQ_io[4]
set_location_assignment PIN_AG10 -to DRAM_DQ_io[5]
set_location_assignment PIN_AK11 -to DRAM_DQ_io[6]
set_location_assignment PIN_AJ11 -to DRAM_DQ_io[7]
set_location_assignment PIN_AH10 -to DRAM_DQ_io[8]
set_location_assignment PIN_AJ10 -to DRAM_DQ_io[9]
set_location_assignment PIN_AJ9 -to DRAM_DQ_io[10]
set_location_assignment PIN_AH9 -to DRAM_DQ_io[11]
set_location_assignment PIN_AH8 -to DRAM_DQ_io[12]
set_location_assignment PIN_AH7 -to DRAM_DQ_io[13]
set_location_assignment PIN_AJ6 -to DRAM_DQ_io[14]
set_location_assignment PIN_AJ5 -to DRAM_DQ_io[15]
set_location_assignment PIN_AB13 -to DRAM_LDQM_o
set_location_assignment PIN_AE13 -to DRAM_RAS_N_o
set_location_assignment PIN_AK12 -to DRAM_UDQM_o
set_location_assignment PIN_AA13 -to DRAM_WE_N_o
set_location_assignment PIN_AA12 -to FAN_CTRL_o
set_location_assignment PIN_J12 -to FPGA_I2C_SCLK_o
set_location_assignment PIN_K12 -to FPGA_I2C_SDAT_io
set_location_assignment PIN_AC18 -to GPIO_0_io[0]
set_location_assignment PIN_AH18 -to GPIO_0_io[10]
set_location_assignment PIN_AH17 -to GPIO_0_io[11]
set_location_assignment PIN_AG16 -to GPIO_0_io[12]
set_location_assignment PIN_AE16 -to GPIO_0_io[13]
set_location_assignment PIN_AF16 -to GPIO_0_io[14]
set_location_assignment PIN_AG17 -to GPIO_0_io[15]
set_location_assignment PIN_AA18 -to GPIO_0_io[16]
set_location_assignment PIN_AA19 -to GPIO_0_io[17]
set_location_assignment PIN_AE17 -to GPIO_0_io[18]
set_location_assignment PIN_AC20 -to GPIO_0_io[19]
set_location_assignment PIN_Y17 -to GPIO_0_io[1]
set_location_assignment PIN_AH19 -to GPIO_0_io[20]
set_location_assignment PIN_AJ20 -to GPIO_0_io[21]
set_location_assignment PIN_AH20 -to GPIO_0_io[22]
set_location_assignment PIN_AK21 -to GPIO_0_io[23]
set_location_assignment PIN_AD19 -to GPIO_0_io[24]
set_location_assignment PIN_AD20 -to GPIO_0_io[25]
set_location_assignment PIN_AE18 -to GPIO_0_io[26]
set_location_assignment PIN_AE19 -to GPIO_0_io[27]
set_location_assignment PIN_AF20 -to GPIO_0_io[28]
set_location_assignment PIN_AF21 -to GPIO_0_io[29]
set_location_assignment PIN_AD17 -to GPIO_0_io[2]
set_location_assignment PIN_AF19 -to GPIO_0_io[30]
set_location_assignment PIN_AG21 -to GPIO_0_io[31]
set_location_assignment PIN_AF18 -to GPIO_0_io[32]
set_location_assignment PIN_AG20 -to GPIO_0_io[33]
set_location_assignment PIN_AG18 -to GPIO_0_io[34]
set_location_assignment PIN_AJ21 -to GPIO_0_io[35]
set_location_assignment PIN_Y18 -to GPIO_0_io[3]
set_location_assignment PIN_AK16 -to GPIO_0_io[4]
set_location_assignment PIN_AK18 -to GPIO_0_io[5]
set_location_assignment PIN_AK19 -to GPIO_0_io[6]
set_location_assignment PIN_AJ19 -to GPIO_0_io[7]
set_location_assignment PIN_AJ17 -to GPIO_0_io[8]
set_location_assignment PIN_AJ16 -to GPIO_0_io[9]
set_location_assignment PIN_AB17 -to GPIO_1_io[0]
set_location_assignment PIN_AG26 -to GPIO_1_io[10]
set_location_assignment PIN_AH24 -to GPIO_1_io[11]
set_location_assignment PIN_AH27 -to GPIO_1_io[12]
set_location_assignment PIN_AJ27 -to GPIO_1_io[13]
set_location_assignment PIN_AK29 -to GPIO_1_io[14]
set_location_assignment PIN_AK28 -to GPIO_1_io[15]
set_location_assignment PIN_AK27 -to GPIO_1_io[16]
set_location_assignment PIN_AJ26 -to GPIO_1_io[17]
set_location_assignment PIN_AK26 -to GPIO_1_io[18]
set_location_assignment PIN_AH25 -to GPIO_1_io[19]
set_location_assignment PIN_AA21 -to GPIO_1_io[1]
set_location_assignment PIN_AJ25 -to GPIO_1_io[20]
set_location_assignment PIN_AJ24 -to GPIO_1_io[21]
set_location_assignment PIN_AK24 -to GPIO_1_io[22]
set_location_assignment PIN_AG23 -to GPIO_1_io[23]
set_location_assignment PIN_AK23 -to GPIO_1_io[24]
set_location_assignment PIN_AH23 -to GPIO_1_io[25]
set_location_assignment PIN_AK22 -to GPIO_1_io[26]
set_location_assignment PIN_AJ22 -to GPIO_1_io[27]
set_location_assignment PIN_AH22 -to GPIO_1_io[28]
set_location_assignment PIN_AG22 -to GPIO_1_io[29]
set_location_assignment PIN_AB21 -to GPIO_1_io[2]
set_location_assignment PIN_AF24 -to GPIO_1_io[30]
set_location_assignment PIN_AF23 -to GPIO_1_io[31]
set_location_assignment PIN_AE22 -to GPIO_1_io[32]
set_location_assignment PIN_AD21 -to GPIO_1_io[33]
set_location_assignment PIN_AA20 -to GPIO_1_io[34]
set_location_assignment PIN_AC22 -to GPIO_1_io[35]
set_location_assignment PIN_AC23 -to GPIO_1_io[3]
set_location_assignment PIN_AD24 -to GPIO_1_io[4]
set_location_assignment PIN_AE23 -to GPIO_1_io[5]
set_location_assignment PIN_AE24 -to GPIO_1_io[6]
set_location_assignment PIN_AF25 -to GPIO_1_io[7]
set_location_assignment PIN_AF26 -to GPIO_1_io[8]
set_location_assignment PIN_AG25 -to GPIO_1_io[9]
set_location_assignment PIN_AE26 -to HEX0_o[0]
set_location_assignment PIN_AE27 -to HEX0_o[1]
set_location_assignment PIN_AE28 -to HEX0_o[2]
set_location_assignment PIN_AG27 -to HEX0_o[3]
set_location_assignment PIN_AF28 -to HEX0_o[4]
set_location_assignment PIN_AG28 -to HEX0_o[5]
set_location_assignment PIN_AH28 -to HEX0_o[6]
set_location_assignment PIN_AJ29 -to HEX1_o[0]
set_location_assignment PIN_AH29 -to HEX1_o[1]
set_location_assignment PIN_AH30 -to HEX1_o[2]
set_location_assignment PIN_AG30 -to HEX1_o[3]
set_location_assignment PIN_AF29 -to HEX1_o[4]
set_location_assignment PIN_AF30 -to HEX1_o[5]
set_location_assignment PIN_AD27 -to HEX1_o[6]
set_location_assignment PIN_AB23 -to HEX2_o[0]
set_location_assignment PIN_AE29 -to HEX2_o[1]
set_location_assignment PIN_AD29 -to HEX2_o[2]
set_location_assignment PIN_AC28 -to HEX2_o[3]
set_location_assignment PIN_AD30 -to HEX2_o[4]
set_location_assignment PIN_AC29 -to HEX2_o[5]
set_location_assignment PIN_AC30 -to HEX2_o[6]
set_location_assignment PIN_AD26 -to HEX3_o[0]
set_location_assignment PIN_AC27 -to HEX3_o[1]
set_location_assignment PIN_AD25 -to HEX3_o[2]
set_location_assignment PIN_AC25 -to HEX3_o[3]
set_location_assignment PIN_AB28 -to HEX3_o[4]
set_location_assignment PIN_AB25 -to HEX3_o[5]
set_location_assignment PIN_AB22 -to HEX3_o[6]
set_location_assignment PIN_AA24 -to HEX4_o[0]
set_location_assignment PIN_Y23 -to HEX4_o[1]
set_location_assignment PIN_Y24 -to HEX4_o[2]
set_location_assignment PIN_W22 -to HEX4_o[3]
set_location_assignment PIN_W24 -to HEX4_o[4]
set_location_assignment PIN_V23 -to HEX4_o[5]
set_location_assignment PIN_W25 -to HEX4_o[6]
set_location_assignment PIN_V25 -to HEX5_o[0]
set_location_assignment PIN_AA28 -to HEX5_o[1]
set_location_assignment PIN_Y27 -to HEX5_o[2]
set_location_assignment PIN_AB27 -to HEX5_o[3]
set_location_assignment PIN_AB26 -to HEX5_o[4]
set_location_assignment PIN_AA26 -to HEX5_o[5]
set_location_assignment PIN_AA25 -to HEX5_o[6]
set_location_assignment PIN_AA30 -to IRDA_RXD_i
set_location_assignment PIN_AB30 -to IRDA_TXD_o
set_location_assignment PIN_AA14 -to KEY_i[0]
set_location_assignment PIN_AA15 -to KEY_i[1]
set_location_assignment PIN_W15 -to KEY_i[2]
set_location_assignment PIN_Y16 -to KEY_i[3]
set_location_assignment PIN_V16 -to LEDR_o[0]
set_location_assignment PIN_W16 -to LEDR_o[1]
set_location_assignment PIN_V17 -to LEDR_o[2]
set_location_assignment PIN_V18 -to LEDR_o[3]
set_location_assignment PIN_W17 -to LEDR_o[4]
set_location_assignment PIN_W19 -to LEDR_o[5]
set_location_assignment PIN_Y19 -to LEDR_o[6]
set_location_assignment PIN_W20 -to LEDR_o[7]
set_location_assignment PIN_W21 -to LEDR_o[8]
set_location_assignment PIN_Y21 -to LEDR_o[9]
set_location_assignment PIN_AD7 -to PS2_CLK_io
set_location_assignment PIN_AE7 -to PS2_DAT_io
set_location_assignment PIN_AD9 -to PS2_CLK2_io
set_location_assignment PIN_AE9 -to PS2_DAT2_io
set_location_assignment PIN_AB12 -to SW_i[0]
set_location_assignment PIN_AC12 -to SW_i[1]
set_location_assignment PIN_AF9 -to SW_i[2]
set_location_assignment PIN_AF10 -to SW_i[3]
set_location_assignment PIN_AD11 -to SW_i[4]
set_location_assignment PIN_AD12 -to SW_i[5]
set_location_assignment PIN_AE11 -to SW_i[6]
set_location_assignment PIN_AC9 -to SW_i[7]
set_location_assignment PIN_AD10 -to SW_i[8]
set_location_assignment PIN_AE12 -to SW_i[9]
set_location_assignment PIN_H15 -to TD_CLK27_i
set_location_assignment PIN_D2 -to TD_DATA_i[0]
set_location_assignment PIN_B1 -to TD_DATA_i[1]
set_location_assignment PIN_E2 -to TD_DATA_i[2]
set_location_assignment PIN_B2 -to TD_DATA_i[3]
set_location_assignment PIN_D1 -to TD_DATA_i[4]
set_location_assignment PIN_E1 -to TD_DATA_i[5]
set_location_assignment PIN_C2 -to TD_DATA_i[6]
set_location_assignment PIN_B3 -to TD_DATA_i[7]
set_location_assignment PIN_A5 -to TD_HS_i
set_location_assignment PIN_F6 -to TD_RESET_N_o
set_location_assignment PIN_A3 -to TD_VS_i
set_location_assignment PIN_B13 -to VGA_B_o[0]
set_location_assignment PIN_G13 -to VGA_B_o[1]
set_location_assignment PIN_H13 -to VGA_B_o[2]
set_location_assignment PIN_F14 -to VGA_B_o[3]
set_location_assignment PIN_H14 -to VGA_B_o[4]
set_location_assignment PIN_F15 -to VGA_B_o[5]
set_location_assignment PIN_G15 -to VGA_B_o[6]
set_location_assignment PIN_J14 -to VGA_B_o[7]
set_location_assignment PIN_F10 -to VGA_BLANK_N_o
set_location_assignment PIN_A11 -to VGA_CLK_o
set_location_assignment PIN_J9 -to VGA_G_o[0]
set_location_assignment PIN_J10 -to VGA_G_o[1]
set_location_assignment PIN_H12 -to VGA_G_o[2]
set_location_assignment PIN_G10 -to VGA_G_o[3]
set_location_assignment PIN_G11 -to VGA_G_o[4]
set_location_assignment PIN_G12 -to VGA_G_o[5]
set_location_assignment PIN_F11 -to VGA_G_o[6]
set_location_assignment PIN_E11 -to VGA_G_o[7]
set_location_assignment PIN_B11 -to VGA_HS_o
set_location_assignment PIN_A13 -to VGA_R_o[0]
set_location_assignment PIN_C13 -to VGA_R_o[1]
set_location_assignment PIN_E13 -to VGA_R_o[2]
set_location_assignment PIN_B12 -to VGA_R_o[3]
set_location_assignment PIN_C12 -to VGA_R_o[4]
set_location_assignment PIN_D12 -to VGA_R_o[5]
set_location_assignment PIN_E12 -to VGA_R_o[6]
set_location_assignment PIN_F13 -to VGA_R_o[7]
set_location_assignment PIN_C10 -to VGA_SYNC_N_o
set_location_assignment PIN_D11 -to VGA_VS_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_CS_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_DIN_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_DOUT_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SCLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_ADCDAT_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_ADCLRCK_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_BCLK_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_DACDAT_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_DACLRCK_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_XCK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_502_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK3_50_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK4_50_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_ADDR_o[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_BA_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_BA_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_CAS_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_CKE_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_CLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_CS_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_DQ_io[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_LDQM_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_RAS_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_UDQM_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DRAM_WE_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to FAN_CTRL_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to FPGA_I2C_SCLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to FPGA_I2C_SDAT_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[16]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[17]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[18]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[19]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[20]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[21]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[22]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[23]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[24]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[25]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[26]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[27]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[28]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[29]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[30]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[31]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[32]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[33]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[34]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[35]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_0_io[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[16]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[17]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[18]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[19]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[20]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[21]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[22]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[23]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[24]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[25]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[26]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[27]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[28]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[29]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[30]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[31]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[32]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[33]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[34]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[35]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1_io[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IRDA_RXD_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IRDA_TXD_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_i[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_i[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_i[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_i[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR_o[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to PS2_CLK_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to PS2_DAT_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to PS2_CLK2_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to PS2_DAT2_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_i[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_CLK27_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_DATA_i[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_HS_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_RESET_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TD_VS_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_BLANK_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_CLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_SYNC_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_CONV_USB_N_io
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[4]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[5]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[6]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[7]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[8]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[9]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[10]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[11]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[12]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[13]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ADDR_o[14]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_BA_o[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_BA_o[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_BA_o[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_CAS_N_o
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_CKE_o
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_CK_N_o
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_CK_P_o
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_CS_N_o
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DM_o[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DM_o[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DM_o[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DM_o[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[4]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[5]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[6]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[7]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[8]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[9]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[10]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[11]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[12]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[13]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[14]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[15]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[16]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[17]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[18]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[19]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[20]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[21]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[22]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[23]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[24]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[25]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[26]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[27]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[28]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[29]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[30]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_DQ_io[31]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_N_io[0]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_N_io[1]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_N_io[2]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_N_io[3]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_P_io[0]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_P_io[1]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_P_io[2]
set_instance_assignment -name IO_STANDARD "DIFFERENTIAL 1.5-V SSTL CLASS I" -to HPS_DDR3_DQS_P_io[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_ODT_o
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_RAS_N_o
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_RESET_N_o
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_RZQ_i
set_instance_assignment -name IO_STANDARD "SSTL-15 CLASS I" -to HPS_DDR3_WE_N_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_GTX_CLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_INT_N_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_MDC_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_MDIO_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_RX_CLK_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_RX_DATA_i[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_RX_DATA_i[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_RX_DATA_i[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_RX_DATA_i[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_RX_DV_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_TX_DATA_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_TX_DATA_o[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_TX_DATA_o[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_TX_DATA_o[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_ENET_TX_EN_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_FLASH_DATA_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_FLASH_DATA_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_FLASH_DATA_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_FLASH_DATA_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_FLASH_DCLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_FLASH_NCSO_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_GSENSOR_INT_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_I2C1_SCLK_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_I2C1_SDAT_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_I2C2_SCLK_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_I2C2_SDAT_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_I2C_CONTROL_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_KEY_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_LED_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_LTC_GPIO_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SD_CLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SD_CMD_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SD_DATA_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SD_DATA_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SD_DATA_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SD_DATA_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SPIM_CLK_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SPIM_MISO_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SPIM_MOSI_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_SPIM_SS_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_UART_RX_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_UART_TX_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_CLKOUT_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DATA_io[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_DIR_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_NXT_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_USB_STP_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_GPIO_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_GPIO_io[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[10]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[11]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[12]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[13]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[14]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[8]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ADDR_o[9]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_BA_o[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_BA_o[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_BA_o[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_CAS_N_o
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_CKE_o
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_CS_N_o
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_ODT_o
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_RAS_N_o
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_WE_N_o
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to HPS_DDR3_RESET_N_o
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[0]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[1]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[2]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[3]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[4]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[5]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[6]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[7]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[8]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[9]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[10]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[11]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[12]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[13]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[14]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[15]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[16]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[17]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[18]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[19]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[20]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[21]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[22]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[23]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[24]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[25]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[26]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[27]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[28]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[29]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[30]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[31]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[0]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[1]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[2]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[3]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[0]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[1]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[2]
set_instance_assignment -name INPUT_TERMINATION "PARALLEL 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[3]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[0]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[1]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[2]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[3]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[4]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[5]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[6]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[7]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[8]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[9]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[10]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[11]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[12]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[13]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[14]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[15]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[16]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[17]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[18]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[19]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[20]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[21]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[22]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[23]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[24]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[25]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[26]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[27]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[28]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[29]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[30]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQ_io[31]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[0]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[1]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[2]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_P_io[3]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[0]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[1]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[2]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DQS_N_io[3]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITHOUT CALIBRATION" -to HPS_DDR3_CK_P_o
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITHOUT CALIBRATION" -to HPS_DDR3_CK_N_o
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DM_o[0]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DM_o[1]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DM_o[2]
set_instance_assignment -name OUTPUT_TERMINATION "SERIES 50 OHM WITH CALIBRATION" -to HPS_DDR3_DM_o[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MINIMUM CURRENT" -to VGA_*
