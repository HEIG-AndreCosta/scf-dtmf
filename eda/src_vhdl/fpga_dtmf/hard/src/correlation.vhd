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
        avalon_address         : in  std_logic_vector(4 downto 0);
        avalon_write           : in  std_logic;
        avalon_writedata       : in  std_logic_vector(31 downto 0);
        avalon_read            : in  std_logic;
        avalon_readdata        : out std_logic_vector(31 downto 0);
        avalon_waitrequest     : out std_logic;

        -- memory access signals TODO change in coonsequence with the new memory architecture
        mem_addr        : out std_logic_vector(15 downto 0);
        mem_clken       : out std_logic;
        mem_chipselect  : out std_logic;
        mem_write       : out std_logic;
        mem_readdata    : in  std_logic_vector(31 downto 0);
        mem_writedata   : out std_logic_vector(31 downto 0);
        mem_byteenable  : out std_logic_vector(3 downto 0);
        mem_reset       : in  std_logic;  
        mem_reset_req   : in  std_logic;  
        -- Interrupt output
        irq_o               : out std_logic
    );
end correlation;

architecture rtl of correlation is

    -- Register map
    constant START_CALCULATION_REG_OFFSET  : unsigned(4 downto 0) := "00000"; -- 0x00
    constant WINDOW_SIZE_REG_OFFSET        : unsigned(4 downto 0) := "00001"; -- 0x04  
    constant WINDOW_NUMBER_REG_OFFSET      : unsigned(4 downto 0) := "00010"; -- 0x08
    constant IRQ_STATUS_REG_OFFSET         : unsigned(4 downto 0) := "00100"; -- 0x10
    --  constant DMA_ADDR_REG_OFFSET           : unsigned(4 downto 0) := "00101"; -- 0x14
    --  constant DMA_SIZE_REG_OFFSET           : unsigned(4 downto 0) := "00110"; -- 0x18
    --  constant DMA_START_TRANSFER_REG_OFFSET : unsigned(4 downto 0) := "00111"; -- 0x1C
    
    -- DMA transfer types
    -- constant DMA_TYPE_REF_SIGNALS   : std_logic_vector(31 downto 0) := x"00000001";
    -- constant DMA_TYPE_WINDOWS       : std_logic_vector(31 downto 0) := x"00000002";
    -- constant DMA_TYPE_RESULTS       : std_logic_vector(31 downto 0) := x"00000003";
    
    -- IRQ status bits
    constant IRQ_STATUS_DMA_TRANSFER_DONE           : natural := 0;
    constant IRQ_STATUS_CALCULATION_DONE          : natural := 1;

    -- Memory Layout
    -- Probably to modify (TODO)
    -- Result memory layout
    constant RESULT_MEM_OFFSET    : unsigned(15 downto 0) := x"0000";
    -- Reference memory layout
    constant REF_MEM_OFFSET       : unsigned(15 downto 0) := x"1000";
    -- Window memory layout:
    constant WINDOW_MEM_OFFSET     : unsigned(15 downto 0) := x"6000";
    
   
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
    signal sample_idx              : unsigned(11 downto 0);
    signal current_window_base     : unsigned(15 downto 0);
    signal current_ref_base        : unsigned(15 downto 0);

    -- Current sample values
    signal window_sample          : signed(15 downto 0);
    signal ref_sample            : signed(15 downto 0);
    signal samples_per_window     : unsigned(11 downto 0);

    signal window_idx            : unsigned(3 downto 0);
    signal reference_idx         : unsigned(3 downto 0);
    signal resultat_idx          : unsigned(9 downto 0);

    -- LPM_divide IP
    component correlation_divide is
        port (
            clock     : in  std_logic;
            numer     : in  std_logic_vector(63 downto 0);
            denom     : in  std_logic_vector(63 downto 0);
            quotient  : out std_logic_vector(63 downto 0);
            remain    : out std_logic_vector(63 downto 0)
        );
    end component;

    -- For division operation
    signal div_numer, div_denom : std_logic_vector(63 downto 0);
    signal div_quotient : std_logic_vector(63 downto 0);

begin
    -- Diviser set to do the calculation in one clock cycle
    divider_inst : correlation_divide
    port map (
        clock    => clk_i,
        numer    => div_numer,
        denom    => div_denom,
        quotient => div_quotient,
        remain   => open
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
                    when WINDOW_SIZE_REG_OFFSET =>
                        avalon_readdata <= std_logic_vector(window_size_reg);
                    when WINDOW_NUMBER_REG_OFFSET =>
                        avalon_readdata <= std_logic_vector(number_of_window_reg);
                    when IRQ_STATUS_REG_OFFSET =>
                        avalon_readdata <= irq_status_reg;
                    when others =>
                        avalon_readdata <= (others => '0');
                end case;
            end if;
            
            -- Writes
            if avalon_write = '1' then
                case unsigned(avalon_address) is
                    when START_CALCULATION_REG_OFFSET =>
                        start_calculation <= '1';
                    when WINDOW_SIZE_REG_OFFSET =>
                        window_size_reg <= unsigned(avalon_writedata);
                    when WINDOW_NUMBER_REG_OFFSET =>
                        number_of_window_reg <= unsigned(avalon_writedata);
                    when IRQ_STATUS_REG_OFFSET =>
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

    -- State machine for correlation computation
    process(clk_i, rst_i)
        variable numerator : signed(63 downto 0);
        variable denominator : signed(63 downto 0);
    begin
        if rst_i = '1' then
            correlation_state <= IDLE;
            mem_clken <= '0';
            mem_chipselect <= '0';
            mem_write <= '0';
            mem_writedata <= (others => '0');
            mem_addr <= (others => '0');
            mem_byteenable <= (others => '0');
            window_idx <= (others => '0');
            reference_idx <= (others => '0');
            sample_idx <= (others => '0');
            calculation_done <= '0';

        elsif rising_edge(clk_i) then
            calculation_done <= '0';
            mem_clken <= '0';
            mem_chipselect <= '0';
            mem_write <= '0';

            case correlation_state is
                when IDLE =>
                    if start_calculation = '1' then
                        correlation_state <= LOAD_WINDOW;
                        window_idx <= (others => '0');
                        reference_idx <= (others => '0');
                        sample_idx <= (others => '0');
                        samples_per_window <= window_size_reg(11 downto 0);
                        best_similarity <= (others => '0');
                        best_reference_idx <= x"F"; -- Default to 0xF (no match)
                        dot_product <= (others => '0');
                        norm_x <= (others => '0');
                        norm_y <= (others => '0');
                        current_similarity <= (others => '0');
                        current_window_base <= (others => '0');
                        current_ref_base <= (others => '0');
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
                    norm_x <= (others => '0');
                    norm_y <= (others => '0');
                    sample_idx <= (others => '0');

                    correlation_state <= READ_WINDOW_SAMPLE;

                when READ_WINDOW_SAMPLE =>
                    if sample_idx < samples_per_window then
                        mem_addr <= std_logic_vector(current_window_base(15 downto 0) + sample_idx);
                    else
                        mem_addr <= (others => '0');
                    end if;
                    mem_clken <= '1';
                    mem_chipselect <= '1';
                    mem_write <= '0';
                    mem_byteenable <= (others => '1');
                    correlation_state <= WAIT_WINDOW_SAMPLE;

                -- Not sure about these wait
                when WAIT_WINDOW_SAMPLE =>
                    mem_clken <= '0';
                    mem_chipselect <= '0';
                    correlation_state <= READ_REF_SAMPLE;

                when READ_REF_SAMPLE =>
                    window_sample <= signed(mem_readdata(15 downto 0));
                    mem_addr <= std_logic_vector(current_ref_base(15 downto 0) + sample_idx);
                    mem_clken <= '1';
                    mem_chipselect <= '1';
                    mem_write <= '0';
                    mem_byteenable <= (others => '1');
                    correlation_state <= WAIT_REF_SAMPLE;

                -- Not sure about these wait
                when WAIT_REF_SAMPLE =>
                    mem_clken <= '0';
                    mem_chipselect <= '0';
                    correlation_state <= CORRELATE_SAMPLES;

                when CORRELATE_SAMPLES =>
                    ref_sample <= signed(mem_readdata(15 downto 0));

                    correlation_state <= COMPUTE_CORRELATION;

                when COMPUTE_CORRELATION =>
                    -- dot += xi * yi;
                    dot_product <= dot_product + (window_sample * ref_sample);

                    -- norm_x += xi * xi;
                    norm_x <= norm_x + (window_sample * window_sample);

                    -- norm_y += yi * yi;
                    norm_y <= norm_y + (ref_sample * ref_sample);

                    if sample_idx < samples_per_window - 1 then
                        sample_idx <= sample_idx + 1;
                        correlation_state <= READ_WINDOW_SAMPLE;
                    else
                        correlation_state <= COMPUTE_SIMILARITY;
                    end if;

                when COMPUTE_SIMILARITY =>
                    if norm_x = 0 or norm_y = 0 then
                        current_similarity <= (others => '0');
                        correlation_state <= CHECK_BEST_MATCH;
                    else
                        numerator := shift_left(resize(dot_product * dot_product, 64), 8);
                        denominator := resize(norm_x * norm_y, 64);
                        if denominator = 0 then
                            current_similarity <= (others => '0');
                            correlation_state <= CHECK_BEST_MATCH;
                        else
                            -- Avoid division by zero
                            -- TODO use a core IP for division (done)
                            div_numer <= std_logic_vector(numerator);
                            div_denom <= std_logic_vector(denominator);
                            correlation_state <= WAIT_DIVISION;
                        end if;
                    end if;
                
                when WAIT_DIVISION =>
                    current_similarity <= unsigned(div_quotient);
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
                    mem_addr <= std_logic_vector(RESULT_MEM_OFFSET(15 downto 0) + resultat_idx);
                    resultat_idx <= resultat_idx + 1;
                    mem_writedata <= x"0000000" & std_logic_vector(best_reference_idx);
                    mem_clken <= '1';
                    mem_chipselect <= '1';
                    mem_write <= '1';
                    mem_byteenable <= (others => '1');
                    correlation_state <= NEXT_WINDOW;

                when NEXT_WINDOW =>
                    mem_clken <= '0';
                    mem_chipselect <= '0';
                    mem_write <= '0';

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