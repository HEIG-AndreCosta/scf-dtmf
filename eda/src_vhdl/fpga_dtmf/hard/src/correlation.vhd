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
--                - Register space for input windows
--                - Register space for reference DTMF patterns
--                - Register for scalar product results
--                - Interrupt generation for completion signals
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
        AXI_ADDR_WIDTH      : natural := 12;
        AXI_DATA_WIDTH      : natural := 32;
        AVL_ADDR_WIDTH      : natural := 13;  -- Increased to accommodate new memory layout
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
    --Constants
    constant CONSTANT_ID                    : std_logic_vector(31 downto 0) := x"CAFE1234";    -- Expected ID value
    constant IRQ_STATUS_CALCULATION_DONE    : natural := 0;

    signal irq_status_reg         : std_logic_vector(31 downto 0);
    
    -- Control signals
    signal start_calculation       : std_logic;
    signal calculation_done        : std_logic;

    -- Correlation computation signals
    signal dot_product            : signed(63 downto 0);

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

    signal test_register_s     : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);

    type sample_array_t is array (0 to 63) of std_logic_vector(15 downto 0);
    signal window_samples_s : sample_array_t;
    signal ref_samples_s : sample_array_t;

begin

    axi_awready_o <= axi_awready_s;
    axi_wready_o  <= axi_wready_s;
    axi_bresp_o   <= axi_bresp_s;
    axi_bvalid_o  <= axi_bvalid_s;
    axi_arready_o <= axi_arready_s;
    axi_rvalid_o  <= axi_rvalid_s;
    axi_rresp_o   <= axi_rresp_s;

    avl_mem_readdata_o    <= (others => '0');
    avl_mem_waitrequest_o <= '0';

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

    -----------------------------------------------------------
    -- Register write process (adapted from reference)
    process (rst_i, clk_i)
        variable int_waddr_v : natural;
        variable byte_index  : integer;
        variable sample_offset : integer;
    begin
        if rst_i = '1' then
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
                    when 2 => start_calculation <= '1';
                    when 3 => irq_status_reg <= irq_status_reg and not axi_wdata_i;
                    when others => 
                        -- 0x100
                        if(int_waddr_v >= 64 and int_waddr_v <= 96) then
                            -- not necessarily an optimisation but it's more readable
                            sample_offset := (int_waddr_v - 64) * 2;
                            window_samples_s(sample_offset) <= axi_wdata_i(15 downto 0);
                            window_samples_s(sample_offset + 1) <= axi_wdata_i(31 downto 16);
                        elsif (int_waddr_v >= 97 and int_waddr_v <= 161) then
                            sample_offset := (int_waddr_v - 97) * 2;
                            ref_samples_s(sample_offset) <= axi_wdata_i(15 downto 0);
                            ref_samples_s(sample_offset + 1) <= axi_wdata_i(31 downto 16);
                        end if;
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

    process (test_register_s, irq_status_reg,
             dot_product, axi_araddr_mem_s)
    variable int_raddr_v : natural;
    begin
        int_raddr_v := to_integer(unsigned(axi_araddr_mem_s));
        axi_rdata_s <= (others => '0');
        case int_raddr_v is
            when 0 => axi_rdata_s <= CONSTANT_ID;
            when 1 => axi_rdata_s <= test_register_s;
            when 3 => axi_rdata_s <= irq_status_reg;
            when 4 => axi_rdata_s <= std_logic_vector(dot_product(31 downto 0));
            when 5 => axi_rdata_s <= std_logic_vector(dot_product(63 downto 32));
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

    process(clk_i, rst_i)
        variable temp_sum : signed(63 downto 0);
        variable abs_temp_sum : signed(63 downto 0);
    begin
        if rst_i = '1' then
            calculation_done <= '0';
            dot_product <= (others => '0');
        elsif rising_edge(clk_i) then
            if calculation_done = '1' then
                calculation_done <= '0';
            end if;

            if start_calculation = '1' then
                temp_sum := (others => '0');
                for i in 0 to 63 loop
                    temp_sum := temp_sum + (signed(window_samples_s(i)) * signed(ref_samples_s(i)));
                end loop;

                if temp_sum < 0 then
                    abs_temp_sum := -temp_sum;
                else
                    abs_temp_sum := temp_sum;
                end if;
                
                dot_product <= abs_temp_sum;
                calculation_done <= '1';
            end if;
        end if;
    end process;
    
    -- IRQ output generation
    irq_o <= irq_status_reg(IRQ_STATUS_CALCULATION_DONE);

end rtl;
