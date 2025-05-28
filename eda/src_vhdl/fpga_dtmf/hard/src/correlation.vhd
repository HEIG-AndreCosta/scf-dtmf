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
        ADDR_WIDTH          : natural := 32;
        DATA_WIDTH          : natural := 32;
        WINDOW_MEM_SIZE     : natural := 131072;
        REF_MEM_SIZE        : natural := 65536;
        MAX_WINDOW_SAMPLES  : natural := 2048;
        MAX_WINDOWS         : natural := 24;
        NUM_DTMF_BUTTONS    : natural := 12
    );
    port (
        -- Clock and reset
        clk_i               : in  std_logic;
        rst_i               : in  std_logic;
        
        -- Avalon Memory-Mapped Slave Interface (CPU access)
        avalon_address         : in  std_logic_vector(7 downto 0);
        avalon_write           : in  std_logic;
        avalon_writedata       : in  std_logic_vector(31 downto 0);
        avalon_read            : in  std_logic;
        avalon_readdata        : out std_logic_vector(31 downto 0);
        avalon_waitrequest     : out std_logic;

        -- Avalon Memory-Mapped Master Interface (DMA memory access)
        mem_address            : in  std_logic_vector(9 downto 0);
        mem_write              : in  std_logic;
        mem_byteenable         : in std_logic_vector(3 downto 0);
        mem_writedata          : in  std_logic_vector(31 downto 0);
        mem_waitrequest        : out std_logic; 
        mem_burstcount         : in  std_logic_vector(4 downto 0); 
        
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
    constant DTMF_WINDOW_RESULT_REG_START_OFFSET: unsigned(7 downto 0) := x"20"; -- 0x20
    --  constant DMA_ADDR_REG_OFFSET           : unsigned(4 downto 0) := "00101"; -- 0x14
    --  constant DMA_SIZE_REG_OFFSET           : unsigned(4 downto 0) := "00110"; -- 0x18
    --  constant DMA_START_TRANSFER_REG_OFFSET : unsigned(4 downto 0) := "00111"; -- 0x1C
    
    -- DMA transfer types
    -- constant DMA_TYPE_REF_SIGNALS   : std_logic_vector(31 downto 0) := x"00000001";
    -- constant DMA_TYPE_WINDOWS       : std_logic_vector(31 downto 0) := x"00000002";
    -- constant DMA_TYPE_RESULTS       : std_logic_vector(31 downto 0) := x"00000003";
    
    -- IRQ status bits
    constant IRQ_STATUS_CALCULATION_DONE          : natural := 0;

    -- Memory Layout
    constant WINDOW_REGION_SIZE         : unsigned(11 downto 0) := x"1000"; -- 4096 bytes
    constant REF_SIGNALS_REGION_SIZE    : unsigned(11 downto 0) := x"0800"; -- 2048 bytes
    constant DTMF_WINDOW_START_ADDR    : unsigned(9 downto 0) := "0001000000"; -- 0x40
    constant DTMF_REF_SIGNAL_START_ADDR : unsigned(11 downto 0) := DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE;

    -- this one below is used for the other register like DTMF_START_CALCULATION_REG_OFFSET, so Andre want to use the memory to store or basic value but Patrick want to store them in a separated register, to define together or with the professor
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
    signal number_of_window_reg       : unsigned(31 downto 0);
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
    signal sample_idx              : unsigned(9 downto 0);
    signal current_window_base     : unsigned(9 downto 0);
    signal current_ref_base        : unsigned(9 downto 0);

    -- Current sample values
    signal window_sample          : signed(15 downto 0);
    signal ref_sample            : signed(15 downto 0);
    signal samples_per_window     : unsigned(5 downto 0);

    signal window_idx            : unsigned(3 downto 0);
    signal reference_idx         : unsigned(3 downto 0);
    signal resultat_idx          : unsigned(9 downto 0);

    -- Internal memory control signals
    signal read_mem_addr     : std_logic_vector(9 downto 0);
    signal write_mem_addr     : std_logic_vector(9 downto 0);
    signal mem_read     : std_logic;
    signal write_mem_write     : std_logic;
    signal mem_readdata  : std_logic_vector(31 downto 0);
    signal write_mem_writedata  : std_logic_vector(31 downto 0);

    signal internal_mem_addr      : std_logic_vector(9 downto 0);
    signal internal_mem_write     : std_logic;
    signal internal_mem_writedata : std_logic_vector(31 downto 0);
    signal internal_mem_read      : std_logic;

    component correlation_RAM is
        port (
            clock       : in std_logic;
            data        : in std_logic_vector(31 downto 0);
            rdaddress   : in std_logic_vector(9 downto 0);
            rden        : in std_logic;
            wraddress   : in std_logic_vector(9 downto 0);
            wren        : in std_logic;
            q           : out std_logic_vector(31 downto 0)
        );
    end component;
begin

    internal_mem_addr <= mem_address when correlation_state = IDLE else 
                        write_mem_addr;

    internal_mem_writedata <= mem_writedata when (correlation_state = IDLE) else write_mem_writedata;

    internal_mem_write <= mem_write when (correlation_state = IDLE) else write_mem_write;
    -- Memory instance for window and reference data
    mem_inst : correlation_RAM
        port map (
            clock       => clk_i,
            data        => internal_mem_writedata,
            rdaddress   => read_mem_addr,
            rden        => mem_read,
            wraddress   => internal_mem_addr,
            wren        => internal_mem_write,
            q           => mem_readdata
    );
    
    -- Avalon Memory-Mapped Slave interface for register access
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            avalon_readdata <= (others => '0');
            window_size_reg <= (others => '0');
            number_of_window_reg <= (others => '0');
            irq_status_reg <= (others => '0');
            start_calculation <= '0';

        elsif rising_edge(clk_i) then
            start_calculation <= '0';
            
            -- Reads
            if avalon_read = '1' then
                case unsigned(avalon_address) is
                    when DTMF_WINDOW_SIZE_REG_OFFSET =>
                        avalon_readdata <= std_logic_vector(window_size_reg);
                    when DTMF_WINDOW_NUMBER_REG_OFFSET =>
                        avalon_readdata <= std_logic_vector(number_of_window_reg);
                    when DTMF_IRQ_STATUS_REG_OFFSET =>
                        avalon_readdata <= irq_status_reg;
                    when others =>
                        avalon_readdata <= (others => '0');
                end case;
            end if;
            
            -- Writes
            if avalon_write = '1' then
                case unsigned(avalon_address) is
                    when DTMF_START_CALCULATION_REG_OFFSET =>
                        start_calculation <= '1';
                    when DTMF_WINDOW_SIZE_REG_OFFSET =>
                        window_size_reg <= unsigned(avalon_writedata);
                    when DTMF_WINDOW_NUMBER_REG_OFFSET =>
                        number_of_window_reg <= unsigned(avalon_writedata);
                    when DTMF_IRQ_STATUS_REG_OFFSET =>
                        -- Writing to IRQ status clears the corresponding bits
                        irq_status_reg <= irq_status_reg and not avalon_writedata;
                    when others =>
                        null;
                end case;
            end if;
            
            -- Set IRQ status bits
            if calculation_done = '1' then
                irq_status_reg(IRQ_STATUS_CALCULATION_DONE) <= '1';
            end if;
        end if;
    end process;

    mem_waitrequest <= '0';

    -- State machine for correlation computation
    process(clk_i, rst_i)
        variable numerator : signed(63 downto 0);
        variable denominator : signed(63 downto 0);
    begin
        if rst_i = '1' then
            correlation_state <= IDLE;
            write_mem_write <= '0';
            write_mem_writedata <= (others => '0');
            write_mem_addr <= (others => '0');
            internal_mem_read <= '0';
            window_idx <= (others => '0');
            reference_idx <= (others => '0');
            sample_idx <= (others => '0');
            calculation_done <= '0';
            resultat_idx <= (others => '0');

        elsif rising_edge(clk_i) then
            calculation_done <= '0';
            write_mem_write <= '0';
            internal_mem_read <= '0';

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
                    if window_idx < number_of_window_reg(11 downto 0) then
                        current_window_base <= WINDOW_MEM_OFFSET + (window_idx * samples_per_window);
                    else
                        current_window_base <= (others => '0');
                    end if;
                    if reference_idx < NUM_DTMF_BUTTONS then
                        current_ref_base <= REF_MEM_OFFSET + (reference_idx * samples_per_window);
                    else
                        current_ref_base <= (others => '0');
                    end if;

                    dot_product <= (others => '0');
                    sample_idx <= (others => '0');

                    correlation_state <= READ_WINDOW_SAMPLE;

                when READ_WINDOW_SAMPLE =>
                    if sample_idx < samples_per_window then
                        read_mem_addr <= std_logic_vector(current_window_base(9 downto 0) + sample_idx);
                    else
                        read_mem_addr <= (others => '0');
                    end if;
                    mem_read <= '1';

                    correlation_state <= WAIT_WINDOW_SAMPLE;

                -- Not sure about these wait
                when WAIT_WINDOW_SAMPLE =>
                    mem_read <= '0';
                    correlation_state <= READ_REF_SAMPLE;

                when READ_REF_SAMPLE =>
                    window_sample <= signed(mem_readdata(15 downto 0));
                    read_mem_addr <= std_logic_vector(current_ref_base(9 downto 0) + sample_idx);
                    mem_read <= '1';
                    correlation_state <= WAIT_REF_SAMPLE;

                -- Not sure about these wait
                when WAIT_REF_SAMPLE =>
                    mem_read <= '0';
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
                    write_mem_addr <= std_logic_vector(RESULT_MEM_OFFSET(9 downto 0) + resultat_idx);
                    resultat_idx <= resultat_idx + 1;
                    write_mem_writedata <= x"0000000" & std_logic_vector(best_reference_idx);
                    write_mem_write <= '1';
                    correlation_state <= NEXT_WINDOW;

                when NEXT_WINDOW =>
                    write_mem_write <= '0';

                    if window_idx < number_of_window_reg(11 downto 0) - 1 then
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
    
    -- No wait states for register access
    avalon_waitrequest <= '0';

end rtl;