------------------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : DE1_SoC_top.vhd
-- Author               : Sébastien Masle
-- Date                 : 17.01.2018
--
-- Context              : HPA
--
------------------------------------------------------------------------------------------
-- Description : top design for DE1-SoC board
--
------------------------------------------------------------------------------------------
-- Dependencies :
--
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer      Comments
-- 0.0    17.01.2018  SMS           Initial version.
--
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity DE1_SoC_top is
    port ( -- clock pins
           CLOCK_50_i  : in  std_logic;
           CLOCK2_50_i : in  std_logic;
           CLOCK3_50_i : in  std_logic;
           CLOCK4_50_i : in  std_logic;

           -- ADC
           ADC_CS_N_o : out std_logic;
           ADC_DIN_o  : out std_logic;
           ADC_DOUT_i : in std_logic;
           ADC_SCLK_o : out std_logic;

           -- Audio
           AUD_ADCLRCK_io : inout std_logic;
           AUD_ADCDAT_i   : in std_logic;
           AUD_DACLRCK_io : inout std_logic;
           AUD_DACDAT_o   : out std_logic;
           AUD_XCK_o      : out std_logic;
           AUD_BCLK_io    : inout std_logic;

           -- SDRAM
           DRAM_ADDR_o  : out std_logic_vector(12 downto 0);
           DRAM_BA_o    : out std_logic_vector(1 downto 0);
           DRAM_CAS_N_o : out std_logic;
           DRAM_CKE_o   : out std_logic;
           DRAM_CLK_o   : out std_logic;
           DRAM_CS_N_o  : out std_logic;
           DRAM_DQ_io   : inout std_logic_vector(15 downto 0);
           DRAM_LDQM_o  : out std_logic;
           DRAM_RAS_N_o : out std_logic;
           DRAM_UDQM_o  : out std_logic;
           DRAM_WE_N_o  : out std_logic;

           --I2C Bus for Configuration of the Audio and Video-In Chips
           FPGA_I2C_SCLK_o  : out std_logic;
           FPGA_I2C_SDAT_io : inout std_logic;

           -- 40-pin headers
           GPIO_0_io    : inout std_logic_vector(35 downto 0);
           GPIO_1_io    : inout std_logic_vector(35 downto 0);

           -- Seven Segment Displays
           HEX0_o       : out std_logic_vector(6 downto 0);
           HEX1_o       : out std_logic_vector(6 downto 0);
           HEX2_o       : out std_logic_vector(6 downto 0);
           HEX3_o       : out std_logic_vector(6 downto 0);
           HEX4_o       : out std_logic_vector(6 downto 0);
           HEX5_o       : out std_logic_vector(6 downto 0);

           -- IR
           IRDA_RXD_i   : in std_logic;
           IRDA_TXD_o   : out std_logic;

           -- Pushbuttons
           KEY_i        : in std_logic_vector(3 downto 0);

           -- LEDs
           LEDR_o       : out std_logic_vector(9 downto 0);

           -- PS2 Ports
           PS2_CLK_io   : inout std_logic;
           PS2_DAT_io   : inout std_logic;
           PS2_CLK2_io  : inout std_logic;
           PS2_DAT2_io  : inout std_logic;

           -- Slider Switches
           SW_i         : in std_logic_vector(9 downto 0);

           -- Video-In
           TD_CLK27_i   : in std_logic;
           TD_DATA_i    : in std_logic_vector(7 downto 0);
           TD_HS_i      : in std_logic;
           TD_RESET_N_o : out std_logic;
           TD_VS_i      : in std_logic;
           
           -- VGA
           VGA_R_o       : out std_logic_vector(7 downto 0);
           VGA_G_o       : out std_logic_vector(7 downto 0);
           VGA_B_o       : out std_logic_vector(7 downto 0);
           VGA_CLK_o     : out std_logic;
           VGA_SYNC_N_o  : out std_logic;
           VGA_BLANK_N_o : out std_logic;
           VGA_HS_o      : out std_logic;
           VGA_VS_o      : out std_logic;
           
           -- DDR3 SDRAM
           HPS_DDR3_ADDR_o      : out std_logic_vector(14 downto 0);
           HPS_DDR3_BA_o        : out std_logic_vector(2 downto 0);
           HPS_DDR3_CAS_N_o     : out std_logic;
           HPS_DDR3_CKE_o       : out std_logic;
           HPS_DDR3_CK_N_o      : out std_logic;
           HPS_DDR3_CK_P_o      : out std_logic;
           HPS_DDR3_CS_N_o      : out std_logic;
           HPS_DDR3_DM_o        : out std_logic_vector(3 downto 0);
           HPS_DDR3_DQ_io       : inout std_logic_vector(31 downto 0);
           HPS_DDR3_DQS_N_io    : inout std_logic_vector(3 downto 0);
           HPS_DDR3_DQS_P_io    : inout std_logic_vector(3 downto 0);
           HPS_DDR3_ODT_o       : out std_logic;
           HPS_DDR3_RAS_N_o     : out std_logic;
           HPS_DDR3_RESET_N_o   : out std_logic;
           HPS_DDR3_RZQ_i       : in std_logic;
           HPS_DDR3_WE_N_o      : out std_logic;

           -- Ethernet
           --HPS_ENET_GTX_CLK_o   : out std_logic;
           --HPS_ENET_INT_N_io    : inout std_logic;
           --HPS_ENET_MDC_o       : out std_logic;
           --HPS_ENET_MDIO_io     : inout std_logic;
           --HPS_ENET_RX_CLK_i    : in std_logic;
           --HPS_ENET_RX_DATA_i   : in std_logic_vector(3 downto 0);
           --HPS_ENET_RX_DV_i     : in std_logic;
           --HPS_ENET_TX_DATA_o   : out std_logic_vector(3 downto 0);
           --HPS_ENET_TX_EN_o     : out std_logic;
           
           -- Flash
           --HPS_FLASH_DATA_io    : inout std_logic_vector(3 downto 0);
           --HPS_FLASH_DCLK_o     : out std_logic;
           --HPS_FLASH_NCSO_o     : out std_logic;

           -- Accelerometer
           --HPS_GSENSOR_INT_io   : inout std_logic;

           -- General Purpose I/O
           --HPS_GPIO_io          : inout std_logic_vector(1 downto 0);
           
           -- I2C
           --HPS_I2C_CONTROL_io   : inout std_logic;
           --HPS_I2C1_SCLK_io     : inout std_logic;
           --HPS_I2C1_SDAT_io     : inout std_logic;
           --HPS_I2C2_SCLK_io     : inout std_logic;
           --HPS_I2C2_SDAT_io     : inout std_logic;

           -- Pushbutton
           HPS_KEY_io           : inout std_logic;

           -- LED
           HPS_LED_io           : inout std_logic;

           -- SD Card
           --HPS_SD_CLK_o         : out std_logic;
           --HPS_SD_CMD_io        : inout std_logic;
           --HPS_SD_DATA_io       : inout std_logic_vector(3 downto 0);

           -- SPI
           --HPS_SPIM_CLK_o       : out std_logic;
           --HPS_SPIM_MISO_i      : in std_logic;
           --HPS_SPIM_MOSI_o      : out std_logic;
           --HPS_SPIM_SS_io       : inout std_logic;

           -- UART
           --HPS_UART_RX_i        : in std_logic;
           --HPS_UART_TX_o        : out std_logic;

           -- USB
           --HPS_CONV_USB_N_io    : inout std_logic;
           --HPS_USB_CLKOUT_i     : in std_logic;
           --HPS_USB_DATA_io      : inout std_logic_vector(7 downto 0);
           --HPS_USB_DIR_i        : in std_logic;
           --HPS_USB_NXT_i        : in std_logic;
           --HPS_USB_STP_o        : out std_logic;

           -- LTC connector
           --HPS_LTC_GPIO_io      : inout std_logic;

           -- FAN
           FAN_CTRL_o           : out std_logic
           );
end DE1_SoC_top;

architecture top of DE1_SoC_top is
    
    component qsys_system is
        port (
            ------------------------------------
            -- FPGA Side
            ------------------------------------
        
            -- Global signals
        
            ------------------------------------
            -- HPS Side
            ------------------------------------
            -- DDR3 SDRAM
            memory_mem_a                    : out   std_logic_vector(14 downto 0);                    -- mem_a
            memory_mem_ba                   : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                   : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                 : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                  : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                 : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n                : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n                : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                 : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n              : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                   : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
            memory_mem_dqs                  : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                  : out   std_logic;                                        -- mem_odt
            memory_mem_dm                   : out   std_logic_vector(3 downto 0);                     -- mem_dm
            memory_oct_rzqin                : in    std_logic                     := 'X';             -- oct_rzqin
    
            -- Pushbutton
            hps_io_0_hps_io_gpio_inst_GPIO54  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO54
    
            -- LED
            hps_io_0_hps_io_gpio_inst_GPIO53  : inout std_logic                     := 'X'              -- hps_io_gpio_inst_GPIO53
        );
    end component qsys_system;

begin

---------------------------------------------------------
--  HPS mapping
---------------------------------------------------------

    System : component qsys_system
    port map (
        ------------------------------------
        -- FPGA Side
        ------------------------------------
    
        -- Global signals
        
        ------------------------------------
        -- HPS Side
        ------------------------------------
        -- DDR3 SDRAM
        memory_mem_a        => HPS_DDR3_ADDR_o,
        memory_mem_ba       => HPS_DDR3_BA_o,
        memory_mem_ck       => HPS_DDR3_CK_P_o,
        memory_mem_ck_n     => HPS_DDR3_CK_N_o,
        memory_mem_cke      => HPS_DDR3_CKE_o,
        memory_mem_cs_n     => HPS_DDR3_CS_N_o,
        memory_mem_ras_n    => HPS_DDR3_RAS_N_o,
        memory_mem_cas_n    => HPS_DDR3_CAS_N_o,
        memory_mem_we_n     => HPS_DDR3_WE_N_o,
        memory_mem_reset_n  => HPS_DDR3_RESET_N_o,
        memory_mem_dq       => HPS_DDR3_DQ_io,
        memory_mem_dqs      => HPS_DDR3_DQS_P_io,
        memory_mem_dqs_n    => HPS_DDR3_DQS_N_io,
        memory_mem_odt      => HPS_DDR3_ODT_o,
        memory_mem_dm       => HPS_DDR3_DM_o,
        memory_oct_rzqin    => HPS_DDR3_RZQ_i,
    
        -- Pushbutton
        hps_io_0_hps_io_gpio_inst_GPIO54  => HPS_KEY_io,
    
        -- LED
        hps_io_0_hps_io_gpio_inst_GPIO53  => HPS_LED_io
    );

end top;
