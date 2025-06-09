--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : correlation.vhd
-- Author   : SCF Lab 9 Implementation
-- Date     : 2025
--
-- Context  : DTMF Analysis using Correlation
--
--------------------------------------------------------------------------------
-- Description :  DTMF correlation module that analyzes input windows against
--                reference values to determine the most probable DTMF key.
--                
--                Features:
--                - Contiguous storage space for input windows
--                - Storage space for reference DTMF patterns
--                - Register for window size and number of windows
--                - Storage for correlation results (most probable key per window)
--                - Interrupt generation for completion signals
--
--                Memory Architecture:
--                - Window region: 20KB (5 * 4096 bytes)
--                - Reference signals region: 4KB
--                - Sample size: 32 bits (signed 16-bit samples)
--
--------------------------------------------------------------------------------
-- Dependencies : - 
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    2025        SCF         Initial DTMF implementation
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity correlation is
    generic (
        NUM_DTMF_BUTTONS    : natural := 12;
        AXI_ADDR_WIDTH      : natural := 12;
        AXI_DATA_WIDTH      : natural := 32;
        AVL_ADDR_WIDTH      : natural := 11;
        AVL_DATA_WIDTH      : natural := 32
    );
    port (
        -- Clock and reset
        clk_i               : in  std_logic;
        rst_i               : in  std_logic;
        
        -- AXI4-Lite Slave Interface (CPU access)
        axi_awaddr_i    : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
        axi_awprot_i    : in  std_logic_vector( 2 downto 0);
        axi_awvalid_i   : in  std_logic;
        axi_awready_o   : out std_logic;
        axi_wdata_i     : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        axi_wstrb_i     : in std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0);
        axi_wvalid_i    : in  std_logic;
        axi_wready_o    : out std_logic;
        axi_bresp_o     : out std_logic_vector(1 downto 0);
        axi_bvalid_o    : out std_logic;
        axi_bready_i    : in  std_logic;
        axi_araddr_i    : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
        axi_arprot_i    : in  std_logic_vector( 2 downto 0);
        axi_arvalid_i   : in  std_logic;
        axi_arready_o   : out std_logic;
        axi_rdata_o     : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        axi_rresp_o     : out std_logic_vector(1 downto 0);
        axi_rvalid_o    : out std_logic;
        axi_rready_i    : in  std_logic;

        -- Avalon Memory-Mapped Master Interface (DMA memory access)
        avl_mem_address_i            : in  std_logic_vector(AVL_ADDR_WIDTH-1 downto 0);
        avl_mem_write_i              : in  std_logic;
        avl_mem_read_i               : in  std_logic;
        avl_mem_byteenable_i         : in std_logic_vector(3 downto 0);
        avl_mem_writedata_i          : in  std_logic_vector(31 downto 0);
        avl_mem_readdata_o           : out  std_logic_vector(31 downto 0);
        avl_mem_waitrequest_o        : out std_logic;
        -- Interrupt output
        irq_o               : out std_logic
    );
end correlation;

architecture rtl of correlation is

    
    --TODO: So DTMF_WINDOW_NUMBER_REG_OFFSET was removed, so what we need to adapt our code.
    --  We know that we have 32 windows to correlate, so we can use a constant for the number of windows.
    --  The window size is given to us through the DTMF_WINDOW_SIZE_REG_OFFSET register.
    --  for each window a sample is represented by 2 bytes
    --  So what will change are the line like:
    --      if window_idx < number_of_window_reg(11 downto 0) then
    --          current_window_base <= WINDOW_MEM_OFFSET + (window_idx * samples_per_window);
    --      else
    --          current_window_base <= (others => '0');
    --      end if;
    --  where we need to adapt the index caluclation of each sample or/and window
    --  Also we need to add our base adress, the base adress are defined like this in the driver:
    --      #define WINDOW_REGION_SIZE		 (4096)
    --      #define REF_SIGNALS_REGION_SIZE		 (2048)
    --      #define DTMF_WINDOW_START_ADDR	   0x40
    --      #define DTMF_REF_SIGNAL_START_ADDR (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)
    --      #define DTMF_REG(x)                                    \
    --      	(DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE + \
    --      	 REF_SIGNALS_REGION_SIZE + x)
    --  
    -- 
    --  so we need to have the same in vhdl, so we can use the same base address for the memory
    --  We will probably need more memory for now we have a memory of 4K, so maybe extend it to 8K

    -- Register map
    constant DTMF_START_CALCULATION_REG_OFFSET  : unsigned(7 downto 0) := x"00"; -- 0x00
    constant DTMF_WINDOW_SIZE_REG_OFFSET        : unsigned(7 downto 0) := x"04"; -- 0x04  
    --constant DTMF_WINDOW_NUMBER_REG_OFFSET      : unsigned(7 downto 0) := x"08"; -- removed, TODO adapt new number of window by knowing we have 32 windows
    constant DTMF_IRQ_STATUS_REG_OFFSET         : unsigned(7 downto 0) := x"10"; -- 0x10
    constant CONSTANT_OFFSET                    : unsigned(7 downto 0) := x"14"; -- 0x14
    constant DTMF_WINDOW_RESULT_REG_START_OFFSET: unsigned(7 downto 0) := x"20"; -- 0x20

    -- Configuration constants
    constant NUM_WINDOWS            : natural := 32;  -- Fixed number of windows
    constant BYTES_PER_SAMPLE       : natural := 2;

    --Constants
    constant CONSTANT_VALUE         : std_logic_vector(31 downto 0) := x"CAFE1234";    -- IRQ status bits
    constant IRQ_STATUS_CALCULATION_DONE          : natural := 0;

    -- Memory Layout
    constant WINDOW_REGION_SIZE         : unsigned(12 downto 0) := "1000000000000"; -- 4096 bytes
    constant REF_SIGNALS_REGION_SIZE    : unsigned(12 downto 0) := "0100000000000"; -- 2048 bytes
    constant DTMF_WINDOW_START_ADDR    : unsigned(10 downto 0) := "00001000000"; -- 0x40
    constant DTMF_REF_SIGNAL_START_ADDR : unsigned(12 downto 0) := DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE;

    -- this one below is used for the other register like DTMF_START_CALCULATION_REG_OFFSET, so Andre want to use the memory to store our basic value but Patrick want to store them in a separated register, to define together or with the professor
    -- DTMF_REG(x) = DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE + REF_SIGNALS_REGION_SIZE + x
   
    -- State machine for correlation computation
    type correlation_state_t is (
        IDLE,
        LOAD_WINDOW,
        READ_WINDOW_SAMPLE,
        WAIT_WINDOW_SAMPLE,
        READ_REF_SAMPLE,
        WAIT_REF_SAMPLE,
        CORRELATE_SAMPLES,
        COMPUTE_CORRELATION,
        COMPUTE_SIMILARITY,
        WAIT_DIVISION,
        CHECK_BEST_MATCH,
        STORE_RESULT,
        NEXT_WINDOW,
        COMPLETE
    );
    
    -- Internal signals
    signal correlation_state        : correlation_state_t;
    
    -- Configuration registers
    signal window_size_reg         : unsigned(31 downto 0);
    -- signal number_of_window_reg       : unsigned(31 downto 0);
    signal irq_status_reg         : std_logic_vector(31 downto 0);
    
    -- Control signals
    signal start_calculation       : std_logic;
    signal calculation_done        : std_logic;

    -- Correlation computation signals
    signal dot_product            : signed(63 downto 0);
    signal norm_x                 : signed(63 downto 0);
    signal norm_y                 : signed(63 downto 0);
    signal current_similarity     : unsigned(63 downto 0);
    signal best_similarity        : unsigned(63 downto 0);
    signal best_reference_idx     : unsigned(3 downto 0);
    signal sample_idx              : unsigned(10 downto 0);
    signal current_window_base     : unsigned(10 downto 0);
    signal current_ref_base        : unsigned(10 downto 0);

    -- Current sample values
    signal window_sample         : signed(15 downto 0);
    signal ref_sample            : signed(15 downto 0);
    signal samples_per_window    : unsigned(5 downto 0);
    signal nb_windows            : unsigned(AXI_DATA_WIDTH-1 downto 0);

    signal window_idx            : unsigned(5 downto 0);
    signal reference_idx         : unsigned(3 downto 0);
    signal resultat_idx          : unsigned(10 downto 0);

    -- Internal memory control signals
    signal int_mem_read        : std_logic;
    signal int_mem_addr_s      : std_logic_vector(10 downto 0);
    signal int_mem_write_s     : std_logic;
    signal int_mem_writedata_s : std_logic_vector(31 downto 0);
    signal int_mem_read_s      : std_logic;
    signal int_mem_readdata_s  : std_logic_vector(31 downto 0);

    signal axi_awready_s       : std_logic;
    signal axi_wready_s        : std_logic;
    signal axi_bresp_s         : std_logic_vector(1 downto 0);
    signal axi_waddr_done_s    : std_logic;
    signal axi_bvalid_s        : std_logic;
    signal axi_arready_s       : std_logic;
    signal axi_rresp_s         : std_logic_vector(1 downto 0);
    signal axi_raddr_done_s    : std_logic;
    signal axi_rvalid_s        : std_logic;

    constant ADDR_LSB  : integer := (AXI_DATA_WIDTH/32)+ 1; -- USEFUL ? 
    
    signal axi_waddr_mem_s     : std_logic_vector(AXI_ADDR_WIDTH-1 downto ADDR_LSB);
    signal axi_data_wren_s     : std_logic;
    signal axi_write_done_s    : std_logic;
    signal axi_araddr_mem_s    : std_logic_vector(AXI_ADDR_WIDTH-1 downto ADDR_LSB);
    signal axi_data_rden_s     : std_logic;
    signal axi_read_done_s     : std_logic;
    signal axi_rdata_s         : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);

    signal reading_s           : std_logic;
    signal read_count_s        : natural;
    signal prev_avl_mem_read_s : std_logic;
    signal test_register_s     : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);

    signal last_wr_addr_s       : std_logic_vector(AVL_ADDR_WIDTH-1 downto 0);
    signal last_rd_addr_s       : std_logic_vector(AVL_ADDR_WIDTH-1 downto 0);
    signal last_wr_byteenable_s : std_logic_vector(3 downto 0);
    signal last_rd_byteenable_s : std_logic_vector(3 downto 0);
    signal wr_count_s           : unsigned(AXI_DATA_WIDTH-1 downto 0);
    signal rd_count_s           : unsigned(AXI_DATA_WIDTH-1 downto 0);

    signal wr_in_progress_s    : std_logic; 
    signal rd_in_progress_s    : std_logic;

    component correlation_RAM is
        port (
                 address_a	: in std_logic_vector (AVL_ADDR_WIDTH-1 downto 0);
                 address_b	: in std_logic_vector (AVL_ADDR_WIDTH-1 downto 0);
                 clock		: in std_logic  := '1';
                 data_a		: in std_logic_vector (31 downto 0);
                 data_b		: in std_logic_vector (31 downto 0);
                 wren_a		: in std_logic  := '0';
                 wren_b		: in std_logic  := '0';
                 byteena_a	: in std_logic_vector (3 downto 0) :=  (others => '1');
                 q_a		: out std_logic_vector (31 downto 0);
                 q_b		: out std_logic_vector (31 downto 0)
        );
    end component;
begin

    axi_awready_o <= axi_awready_s;
    axi_wready_o  <= axi_wready_s;
    axi_bresp_o   <= axi_bresp_s;
    axi_bvalid_o  <= axi_bvalid_s;
    axi_arready_o <= axi_arready_s;
    axi_rvalid_o  <= axi_rvalid_s;
    axi_rresp_o   <= axi_rresp_s;

    -----------------------------------------------------------
    -- Write adresse channel

    -- Implement axi_awready generation and
    -- Implement axi_awaddr memorizing
    --   memorize address when S_AXI_AWVALID is valid.
    process (rst_i, clk_i)
    begin
        if rst_i = '1' then
            axi_awready_s    <= '0';
            axi_waddr_done_s <= '0';   
            axi_waddr_mem_s  <= (others => '0');
        elsif rising_edge(clk_i) then
            axi_waddr_done_s <= '0';
            if (axi_awready_s = '1' and axi_awvalid_i = '1')  then --and axi_wvalid_i = '1') then  modif EMI 10juil
                -- slave is ready to accept write address when
                -- there is a valid write address
                axi_awready_s    <= '0';
                axi_waddr_done_s <= '1';
                -- Write Address memorizing
                axi_waddr_mem_s  <= axi_awaddr_i(AXI_ADDR_WIDTH-1 downto ADDR_LSB);
            elsif axi_write_done_s = '1' then
                axi_awready_s    <= '1';
            end if;
        end if;
    end process;

    -----------------------------------------------------------
    -- Write data channel
    -- Implement axi_wready generation
    process (rst_i, clk_i)
    begin
        if rst_i = '1' then
            axi_wready_s    <= '0';
            -- axi_data_wren_s <= '0';
        elsif rising_edge(clk_i) then
            -- axi_data_wren_s <= '0';
            --if (axi_wready_s = '0' and axi_wvalid_i = '1' and axi_awready_s = '1' ) then --axi_awvalid_i = '1') then
            if (axi_wready_s = '1' and axi_wvalid_i = '1') then --modif EMI 10juil
                -- slave is ready to accept write address when
                -- there is a valid write address and write data
                -- on the write address and data bus. This design
                -- expects no outstanding transactions.
                axi_wready_s <= '0';
                -- axi_data_wren_s <= '1';
            elsif axi_waddr_done_s = '1' then
                axi_wready_s <= '1';
            end if;
        end if;
    end process;

    -- Implement memory mapped register select and write logic generation
    -- The write data is accepted and written to memory mapped registers when
    -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    -- select byte enables of slave registers while writing.
    -- These registers are cleared when reset is applied.
    -- Slave register write enable is asserted when valid address and data are available
    -- and the slave is ready to accept the write address and write data.
    axi_data_wren_s <= axi_wready_s and axi_wvalid_i ; --and axi_awready_s and axi_awvalid_i ;

    -- Memory instance for window and reference data
    mem_inst : correlation_RAM
        port map (
                     clock      => clk_i,
                     address_a  => avl_mem_address_i,
                     byteena_a  => avl_mem_byteenable_i,
                     data_a	=> avl_mem_writedata_i,
                     wren_a	=> avl_mem_write_i,
                     q_a	=> avl_mem_readdata_o,
                     address_b  => int_mem_addr_s,
                     data_b	=> int_mem_writedata_s,
                     wren_b	=> int_mem_write_s,
                     q_b	=> int_mem_readdata_s
                 );

    -- Stall avalon bus so the memory has time to fetch the data
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            reading_s <= '0';
            read_count_s <= 0;
        elsif rising_edge(clk_i) then
            prev_avl_mem_read_s <= avl_mem_read_i;
            read_count_s <= read_count_s - 1;

            if avl_mem_read_i = '1' and prev_avl_mem_read_s = '0' then
                read_count_s <= 2;
                reading_s <= '1';
            elsif reading_s = '1' and read_count_s = 0 then
                reading_s <= '0';
            end if;
        end if;
    end process;
    
    -- Assert waitrequest during the first cycle of a read
    avl_mem_waitrequest_o <= (avl_mem_read_i and not prev_avl_mem_read_s) or reading_s;

    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            last_wr_addr_s <= (others => '0');
            last_rd_addr_s <= (others => '0');
            rd_in_progress_s <= '0';
            wr_in_progress_s <= '0';
            last_wr_byteenable_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if avl_mem_write_i = '1' then
                last_wr_addr_s <= avl_mem_address_i;
                last_wr_byteenable_s <= avl_mem_byteenable_i;
                if wr_in_progress_s = '0' then
                    wr_count_s <= wr_count_s + 1;
                    wr_in_progress_s <= '1';
                end if;
            else
                    wr_in_progress_s <= '0';
            end if;
            if avl_mem_read_i = '1' then
                last_rd_addr_s <= avl_mem_address_i;
                last_rd_byteenable_s <= avl_mem_byteenable_i;
                if rd_in_progress_s = '0' then
                    rd_count_s <= rd_count_s + 1;
                    rd_in_progress_s <= '1';
                end if;
            else
                    rd_in_progress_s <= '0';
            end if;
        end if;
    end process;
    -----------------------------------------------------------
    -- Register write process (adapted from reference)
    process (rst_i, clk_i)
        variable int_waddr_v : natural;
        variable byte_index  : integer;
    begin
        if rst_i = '1' then
            window_size_reg   <= (others => '0');
            irq_status_reg    <= (others => '0');
            start_calculation <= '0';
            axi_write_done_s  <= '1';
        elsif rising_edge(clk_i) then
            axi_write_done_s <= '0';
            start_calculation <= '0';

            if axi_data_wren_s = '1' then
                axi_write_done_s <= '1';
                int_waddr_v := to_integer(unsigned(axi_waddr_mem_s));
                case int_waddr_v is
                    when 1 => test_register_s <= axi_wdata_i;
                    when 2 => 
                        start_calculation <= '1';
                        nb_windows <= unsigned(axi_wdata_i);
                    when 3 => window_size_reg <= unsigned(axi_wdata_i);
                    when 4 => irq_status_reg <= irq_status_reg and not axi_wdata_i;
                    when others => null;
                end case;
            end if;

            -- Set IRQ status bits
            if calculation_done = '1' then
                irq_status_reg(IRQ_STATUS_CALCULATION_DONE) <= '1';
            end if;
        end if;
    end process;


    -----------------------------------------------------------
    -- Write respond channel

    -- Implement write response logic generation
    -- The write response and response valid signals are asserted by the slave
    -- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    -- This marks the acceptance of address and indicates the status of
    -- write transaction.

    process (rst_i, clk_i)
    begin
        if rst_i = '1' then
            axi_bvalid_s <= '0';
            axi_bresp_s  <= "00"; --need to work more on the responses
        elsif rising_edge(clk_i) then
            --if (axi_awready_s ='1' and axi_awvalid_i ='1' and axi_wready_s ='1' and axi_wvalid_i ='1' then -- supprimer: axi_bready_i ='0' ) then
            if axi_data_wren_s = '1' then
                axi_bvalid_s <= '1';
                axi_bresp_s  <= "00";
            elsif (axi_bready_i = '1') then --  and axi_bvalid_s = '1') then
                axi_bvalid_s <= '0';
            end if;
        end if;
    end process;

    -----------------------------------------------------------
    -- Read address channel

    -- Implement axi_arready generation
    -- axi_arready is asserted for one S_AXI_ACLK clock cycle when
    -- S_AXI_ARVALID is asserted. axi_awready is
    -- de-asserted when reset (active low) is asserted.
    -- The read address is also memorised when S_AXI_ARVALID is
    -- asserted. axi_araddr is reset to zero on reset assertion.
    process (rst_i, clk_i)
    begin
        if rst_i = '1' then
           axi_arready_s    <= '1';
           axi_raddr_done_s <= '0';
           axi_araddr_mem_s <= (others => '1');
        elsif rising_edge(clk_i) then
            if axi_arready_s = '1' and axi_arvalid_i = '1' then
                axi_arready_s    <= '0';
                axi_raddr_done_s <= '1';
                -- Read Address memorization
                axi_araddr_mem_s <= axi_araddr_i(AXI_ADDR_WIDTH-1 downto ADDR_LSB);
            elsif (axi_raddr_done_s = '1' and axi_rvalid_s = '0') then
                axi_raddr_done_s <= '0';
            elsif axi_read_done_s = '1' then
                axi_arready_s    <= '1';
            end if;
        end if;
    end process;

    -----------------------------------------------------------
    -- Read data channel

    -- Implement axi_rvalid generation
    -- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    -- S_AXI_ARVALID and axi_arready are asserted. The slave registers
    -- data are available on the axi_rdata bus at this instance. The
    -- assertion of axi_rvalid marks the validity of read data on the
    -- bus and axi_rresp indicates the status of read transaction.axi_rvalid
    -- is deasserted on reset. axi_rresp and axi_rdata are
    -- cleared to zero on reset.
    process (rst_i, clk_i)
    begin
        if rst_i = '1' then
            -- axi_raddr_done_s <= '0';
            axi_rvalid_s    <= '0';
            axi_read_done_s <= '0';
            axi_rresp_s     <= "00";
        elsif rising_edge(clk_i) then
            -- if axi_arready_s = '0' and axi_arvalid_i = '1' then     --  modif EMI 10juil
            --     axi_raddr_done_s <= '1';
            --if (axi_arready_s = '1' and axi_arvalid_i = '1' and axi_rvalid_s = '0') then
            axi_read_done_s <= '0';
            if (axi_raddr_done_s = '1' and axi_rvalid_s = '0') then   --  modif EMI 10juil
                -- Valid read data is available at the read data bus
                axi_rvalid_s    <= '1';
                -- axi_raddr_done_s <= '0';                                   --  modif EMI 10juil
                axi_rresp_s  <= "00"; -- 'OKAY' response
            elsif (axi_rvalid_s = '1' and axi_rready_i = '1') then
                -- Read data is accepted by the master
                axi_rvalid_s    <= '0';
                axi_read_done_s <= '1';
            end if;
        end if;
    end process;

    -- Implement memory mapped register select and read logic generation
    -- Slave register read enable is asserted when valid address is available
    -- and the slave is ready to accept the read address.
    axi_data_rden_s <= axi_raddr_done_s and (not axi_rvalid_s);

    process (axi_araddr_mem_s, window_size_reg, irq_status_reg)
    variable int_raddr_v : natural;
    begin
        int_raddr_v := to_integer(unsigned(axi_araddr_mem_s));
        axi_rdata_s <= (others => '0');
        case int_raddr_v is
            when 0 => axi_rdata_s <= CONSTANT_VALUE;
            when 1 => axi_rdata_s <= test_register_s;
            when 3 => axi_rdata_s <= std_logic_vector(window_size_reg);
            when 4 => axi_rdata_s <= irq_status_reg;
            when 5 => axi_rdata_s <= std_logic_vector(resize(unsigned(last_rd_addr_s), axi_rdata_s'length));
            when 6 => axi_rdata_s <= std_logic_vector(resize(unsigned(last_rd_byteenable_s), axi_rdata_s'length));
            when 7 => axi_rdata_s <= std_logic_vector(rd_count_s);
            when 8 => axi_rdata_s <= std_logic_vector(resize(unsigned(last_wr_addr_s), axi_rdata_s'length));
            when 9 => axi_rdata_s <= std_logic_vector(resize(unsigned(last_wr_byteenable_s), axi_rdata_s'length));
            when 10 => axi_rdata_s <= std_logic_vector(wr_count_s);
            when others => axi_rdata_s <= x"A5A5A5A5";
        end case;
    end process;

    process (rst_i, clk_i)
    begin
        if rst_i = '1' then
            axi_rdata_o <= (others => '0');
        elsif rising_edge(clk_i) then
            if axi_data_rden_s = '1' then
                -- When there is a valid read address (S_AXI_ARVALID) with
                -- acceptance of read address by the slave (axi_arready),
                -- output the read dada
                -- Read address mux
                axi_rdata_o <= axi_rdata_s;
            end if;
        end if;
    end process;

    -- State machine for correlation computation
    process(clk_i, rst_i)
        variable numerator : signed(63 downto 0);
        variable denominator : signed(63 downto 0);
    begin
        if rst_i = '1' then
            correlation_state <= IDLE;
            int_mem_write_s <= '0';
            int_mem_writedata_s <= (others => '0');
            int_mem_addr_s <= (others => '0');
            window_idx <= (others => '0');
            reference_idx <= (others => '0');
            sample_idx <= (others => '0');
            calculation_done <= '0';
            resultat_idx <= (others => '0');

        elsif rising_edge(clk_i) then
            calculation_done <= '0';
            int_mem_write_s <= '0';

            case correlation_state is
                when IDLE =>
                    if start_calculation = '1' then
                        correlation_state <= LOAD_WINDOW;
                        window_idx <= (others => '0');
                        reference_idx <= (others => '0');
                        sample_idx <= (others => '0');
                        samples_per_window <= window_size_reg(5 downto 0);
                        best_similarity <= (others => '0');
                        best_reference_idx <= x"F"; -- Default to 0xF (no match)
                        dot_product <= (others => '0');
                        current_similarity <= (others => '0');
                        resultat_idx <= (others => '0');
                    end if;

                when LOAD_WINDOW =>
                    if window_idx < NUM_WINDOWS then
                        current_window_base <= resize(DTMF_WINDOW_START_ADDR + (window_idx * samples_per_window * BYTES_PER_SAMPLE), current_window_base'length);
                    else
                        current_window_base <= (others => '0');
                    end if;
                    if reference_idx < NUM_DTMF_BUTTONS then
                        current_ref_base <= resize(DTMF_REF_SIGNAL_START_ADDR + (reference_idx * samples_per_window * BYTES_PER_SAMPLE), current_ref_base'length);
                    else
                        current_ref_base <= (others => '0');
                    end if;

                    dot_product <= (others => '0');
                    sample_idx <= (others => '0');

                    correlation_state <= READ_WINDOW_SAMPLE;

                when READ_WINDOW_SAMPLE =>
                    if sample_idx < samples_per_window then
                        int_mem_addr_s <= std_logic_vector(resize(current_window_base + (sample_idx * BYTES_PER_SAMPLE), int_mem_addr_s'length));
                    else
                        int_mem_addr_s <= (others => '0');
                    end if;
                    int_mem_read <= '1';

                    correlation_state <= WAIT_WINDOW_SAMPLE;

                -- Not sure about these wait
                when WAIT_WINDOW_SAMPLE =>
                    int_mem_read <= '0';
                    correlation_state <= READ_REF_SAMPLE;

                when READ_REF_SAMPLE =>
                    window_sample <= signed(int_mem_readdata_s(15 downto 0));
                    int_mem_addr_s <= std_logic_vector(resize(current_ref_base + (sample_idx * BYTES_PER_SAMPLE), int_mem_addr_s'length));
                    int_mem_read <= '1';
                    correlation_state <= WAIT_REF_SAMPLE;

                -- Not sure about these wait
                when WAIT_REF_SAMPLE =>
                    int_mem_read <= '0';
                    correlation_state <= CORRELATE_SAMPLES;

                when CORRELATE_SAMPLES =>
                    ref_sample <= signed(int_mem_readdata_s(15 downto 0));

                    correlation_state <= COMPUTE_CORRELATION;

                when COMPUTE_CORRELATION =>
                    -- dot += xi * yi;
                    dot_product <= dot_product + (window_sample * ref_sample);

                    if sample_idx < samples_per_window - 1 then
                        sample_idx <= sample_idx + 1;
                        correlation_state <= READ_WINDOW_SAMPLE;
                    else
                        correlation_state <= COMPUTE_SIMILARITY;
                    end if;

                when COMPUTE_SIMILARITY =>
                    if dot_product >= 0 then
                        current_similarity <= unsigned(dot_product);
                    else
                        current_similarity <= unsigned(-dot_product);
                    end if;
                    correlation_state <= CHECK_BEST_MATCH;
                
                when CHECK_BEST_MATCH =>
                    if current_similarity > best_similarity then
                        best_similarity <= current_similarity;
                        best_reference_idx <= reference_idx;
                    end if;

                    if reference_idx < NUM_DTMF_BUTTONS - 1 then
                        reference_idx <= reference_idx + 1;
                        correlation_state <= LOAD_WINDOW;
                    else
                        correlation_state <= STORE_RESULT;
                    end if;

                when STORE_RESULT =>
                    int_mem_addr_s <= std_logic_vector(DTMF_WINDOW_RESULT_REG_START_OFFSET + resultat_idx);
                    int_mem_write_s <= '1';
                    int_mem_writedata_s <= x"0000000" & std_logic_vector(best_reference_idx);
                    resultat_idx <= resultat_idx + 1;
                    correlation_state <= NEXT_WINDOW;

                when NEXT_WINDOW =>
                    int_mem_write_s <= '0';

                    if window_idx < (NUM_WINDOWS - 1) then
                        window_idx <= window_idx + 1;
                        reference_idx <= (others => '0');
                        best_similarity <= (others => '0');
                        best_reference_idx <= x"F";
                        correlation_state <= LOAD_WINDOW;
                    else
                        correlation_state <= COMPLETE;
                    end if;

                when COMPLETE =>
                    calculation_done <= '1';
                    correlation_state <= IDLE;

                when others =>
                    correlation_state <= IDLE;
            end case;
        end if;
    end process;
    
    -- IRQ output generation
    irq_o <= irq_status_reg(IRQ_STATUS_CALCULATION_DONE);

end rtl;
