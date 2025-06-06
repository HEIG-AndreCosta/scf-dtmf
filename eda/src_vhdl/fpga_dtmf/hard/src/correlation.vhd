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
        AXI_DATA_WIDTH      : natural := 32
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
        axi_arprot_i    : in  std_logic_vector(2 downto 0);
        axi_arvalid_i   : in  std_logic;
        axi_arready_o   : out std_logic;
        axi_rdata_o     : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        axi_rresp_o     : out std_logic_vector(1 downto 0);
        axi_rvalid_o    : out std_logic;
        axi_rready_i    : in  std_logic;

        -- Avalon Memory-Mapped Master Interface (DMA memory access)
        -- mem_address            : in  std_logic_vector(10 downto 0);
        -- mem_write              : in  std_logic;
        -- mem_byteenable         : in std_logic_vector(3 downto 0);
        -- mem_writedata          : in  std_logic_vector(31 downto 0);
        -- mem_waitrequest        : out std_logic; 
        -- mem_burstcount         : in  std_logic_vector(4 downto 0); 
        
        -- Interrupt output
        irq_o               : out std_logic
    );
end correlation;

architecture rtl of correlation is

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
    constant constant_value         : std_logic_vector(31 downto 0) := x"cafe1234";    -- IRQ status bits
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
    signal window_sample          : signed(15 downto 0);
    signal ref_sample            : signed(15 downto 0);
    signal samples_per_window     : unsigned(5 downto 0);

    signal window_idx            : unsigned(5 downto 0);
    signal reference_idx         : unsigned(3 downto 0);
    signal resultat_idx          : unsigned(10 downto 0);

    -- Internal memory control signals
    signal read_mem_addr     : std_logic_vector(10 downto 0);
    signal write_mem_addr     : std_logic_vector(10 downto 0);
    signal mem_read     : std_logic;
    signal write_mem_write     : std_logic;
    signal mem_readdata  : std_logic_vector(31 downto 0);
    signal write_mem_writedata  : std_logic_vector(31 downto 0);

    signal internal_mem_write_addr      : std_logic_vector(10 downto 0);
    signal internal_mem_write     : std_logic;
    signal internal_mem_writedata : std_logic_vector(31 downto 0);
    signal internal_mem_read_addr      : std_logic_vector(10 downto 0);
    signal internal_mem_read     : std_logic;

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

    signal axi_ram_rdaddress : std_logic_vector(10 downto 0);
    signal axi_ram_rden      : std_logic;
    signal axi_ram_q         : std_logic_vector(31 downto 0);
    signal axi_ram_wraddress : std_logic_vector(10 downto 0);
    signal axi_ram_wdata     : std_logic_vector(31 downto 0);
    signal axi_ram_wren      : std_logic;

    signal correlation_read_addr     : std_logic_vector(10 downto 0);
    signal correlation_write_addr    : std_logic_vector(10 downto 0);
    signal correlation_read_enable   : std_logic;
    signal correlation_write_enable  : std_logic;
    signal correlation_writedata     : std_logic_vector(31 downto 0);

    component correlation_RAM is
        port (
            clock       : in std_logic;
            data        : in std_logic_vector(31 downto 0);
            rdaddress   : in std_logic_vector(10 downto 0);
            rden        : in std_logic;
            wraddress   : in std_logic_vector(10 downto 0);
            wren        : in std_logic;
            q           : out std_logic_vector(31 downto 0)
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


    --internal_mem_write_addr <= mem_address when (correlation_state = IDLE and axi_ram_wren = '0') else 
    --                      axi_ram_wraddress when (correlation_state = IDLE and axi_ram_wren = '1') else 
    --                      write_mem_addr;    internal_mem_read_addr <= axi_ram_rdaddress when (correlation_state = IDLE) else read_mem_addr;
--
--    --internal_mem_writedata <= mem_writedata when (correlation_state = IDLE and axi_ram_wren = '0') else
--    --                     axi_ram_wdata when (correlation_state = IDLE and axi_ram_wren = '1') else
    --                     write_mem_writedata;
--
--    --internal_mem_write <= mem_write when (correlation_state = IDLE and axi_ram_wren = '0') else
--    --                 axi_ram_wren when (correlation_state = IDLE and axi_ram_wren = '1') else
    --                 write_mem_write;    internal_mem_read <= axi_ram_rden when (correlation_state = IDLE) else mem_read;

    internal_mem_write_addr <= axi_ram_wraddress when (correlation_state = IDLE) else 
                          correlation_write_addr;

    internal_mem_read_addr <= axi_ram_rdaddress when (correlation_state = IDLE) else 
                             correlation_read_addr;

    internal_mem_writedata <= axi_ram_wdata when (correlation_state = IDLE) else
                             correlation_writedata;

    internal_mem_write <= axi_ram_wren when (correlation_state = IDLE) else
                         correlation_write_enable;

    internal_mem_read <= axi_ram_rden when (correlation_state = IDLE) else 
                    correlation_read_enable;

    -- Memory instance for window and reference data
    mem_inst : correlation_RAM
        port map (
            clock       => clk_i,
            data        => internal_mem_writedata,
            rdaddress   => internal_mem_read_addr,
            rden        => internal_mem_read,
            wraddress   => internal_mem_write_addr,
            wren        => internal_mem_write,
            q           => mem_readdata
    );

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
            axi_ram_wraddress <= (others => '0');
            axi_ram_wdata       <= (others => '0'); 
            axi_ram_wren      <= '0';
            axi_ram_rdaddress <= (others => '0');
            axi_ram_rden      <= '0';
        elsif rising_edge(clk_i) then
            axi_write_done_s <= '0';
            start_calculation <= '0';
            axi_ram_rden <= '0'; 
            axi_ram_wren <= '0';

            if axi_data_wren_s = '1' then
                axi_write_done_s <= '1';
                int_waddr_v := to_integer(unsigned(axi_waddr_mem_s));
                case int_waddr_v is
                    -- 0x00 >> 2 = 0: Start calculation register
                    when 0 => start_calculation <= '1';

                    -- 0x04 >> 2 = 1: Window size register
                    when 1 => window_size_reg <= unsigned(axi_wdata_i);
                            
                    -- 0x10 >> 2 = 4: IRQ status register (clear on write)
                    when 4 => irq_status_reg <= irq_status_reg and not axi_wdata_i;
                    -- 0x14 >> 2 = 5: setup rd_address TOCHECK = converion form a bigger width
                    when 5 => axi_ram_rdaddress <= axi_wdata_i(10 downto 0);
                    -- 0x18 >> 2 = 5: setup rden
                    when 6 => axi_ram_rden <= '1';
                    -- 0x1C >> 2 = 7: setup wr_address TOCHECK = converion form a bigger width
                    when 7 => axi_ram_wraddress <= axi_wdata_i(10 downto 0);
                    -- 0x20 >> 2 = 8: setup wdata
                    when 8 => axi_ram_wdata <= axi_wdata_i;
                    -- 0x24 >> 2 = 9: setup wren
                    when 9 => axi_ram_wren <= '1';
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

    process (axi_araddr_mem_s, window_size_reg, irq_status_reg, mem_readdata)
    variable int_raddr_v : natural;
    begin
        int_raddr_v := to_integer(unsigned(axi_araddr_mem_s));
        axi_rdata_s <= x"A5A5A5A5"; -- default value
        case int_raddr_v is
            --0x04 >> 2 = 1: Window size register
            when 1 =>
                axi_rdata_s <= std_logic_vector(window_size_reg);
            --0x10 >> 2 = 4: IRQ status register
            when 4 => -- 0x10: IRQ status register
                axi_rdata_s <= irq_status_reg;
            --0x14 >> 2 = 5: read memory data
            when 5 => -- 0x08: Read memory data
                axi_rdata_s <= mem_readdata;
            --0x18 >> 2 = 5: Constant register
            when 6 => -- 0x14: Constant register
                axi_rdata_s <= constant_value;
            when others =>
                axi_rdata_s <= x"A5A5A5A5";
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
            window_idx <= (others => '0');
            reference_idx <= (others => '0');
            sample_idx <= (others => '0');
            calculation_done <= '0';
            resultat_idx <= (others => '0');
            correlation_state <= IDLE;
            correlation_write_enable <= '0';
            correlation_read_enable <= '0';
            correlation_writedata <= (others => '0');
            correlation_write_addr <= (others => '0');
            correlation_read_addr <= (others => '0');

        elsif rising_edge(clk_i) then
            calculation_done <= '0';
            correlation_write_enable <= '0';
            correlation_read_enable <= '0';

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
                        correlation_read_addr <= std_logic_vector(resize(current_window_base + (sample_idx * BYTES_PER_SAMPLE), read_mem_addr'length));
                    else
                        correlation_read_addr <= (others => '0');
                    end if;
                    correlation_read_enable <= '1';

                    correlation_state <= WAIT_WINDOW_SAMPLE;

                -- Not sure about these wait
                when WAIT_WINDOW_SAMPLE =>
                    correlation_read_enable <= '0';
                    correlation_state <= READ_REF_SAMPLE;

                when READ_REF_SAMPLE =>
                    window_sample <= signed(mem_readdata(15 downto 0));
                    correlation_read_addr <= std_logic_vector(resize(current_ref_base + (sample_idx * BYTES_PER_SAMPLE), read_mem_addr'length));
                    correlation_read_enable <= '1';
                    correlation_state <= WAIT_REF_SAMPLE;

                -- Not sure about these wait
                when WAIT_REF_SAMPLE =>
                    correlation_read_enable <= '0';
                    correlation_state <= CORRELATE_SAMPLES;

                when CORRELATE_SAMPLES =>
                    ref_sample <= signed(mem_readdata(15 downto 0));

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
                    correlation_write_addr <= std_logic_vector(DTMF_WINDOW_RESULT_REG_START_OFFSET + resultat_idx);
                    resultat_idx <= resultat_idx + 1;
                    correlation_writedata <= x"0000000" & std_logic_vector(best_reference_idx);
                    correlation_write_enable <= '1';
                    correlation_state <= NEXT_WINDOW;

                when NEXT_WINDOW =>
                    correlation_write_enable <= '0';

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