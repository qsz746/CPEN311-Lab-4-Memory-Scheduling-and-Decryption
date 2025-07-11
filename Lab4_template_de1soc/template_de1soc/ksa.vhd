library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ksa is
  port(
    CLOCK_50            : in  std_logic;  -- Clock pin
    KEY                 : in  std_logic_vector(3 downto 0);  -- push button switches
    SW                 : in  std_logic_vector(9 downto 0);  -- slider switches
    LEDR : out std_logic_vector(9 downto 0);  -- red lights
    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0));
end ksa;

architecture rtl of ksa is
   COMPONENT SevenSegmentDisplayDecoder IS
    PORT
    (
        ssOut : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        nIn : IN STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
    END COMPONENT;
	 
	 
	 
	 component multicore_decryption is
    port(
      clk               : in  std_logic;
      reset_n           : in  std_logic;
      start             : in  std_logic;
      secret_key        : out std_logic_vector(23 downto 0);
      done              : out std_logic;
      secret_key_found  : out std_logic;
      active_core       : out std_logic_vector(1 downto 0)
    );
    end component;


 
	 
    -- Signals
	 signal secret_key     : std_logic_vector(23 downto 0);
    signal multicore_done : std_logic;
    signal start_multicore     : std_logic := '1'; -- Default to '1' for auto-start
 
    signal secret_key_found : std_logic;
	 signal active_core      : std_logic_vector(1 downto 0);
    -- clock and reset signals  
	 signal clk, reset_n : std_logic;		


    
    signal Seven_Seg_Val0, Seven_Seg_Val1, Seven_Seg_Val2 : std_logic_vector(6 downto 0);
    signal Seven_Seg_Val3, Seven_Seg_Val4, Seven_Seg_Val5 : std_logic_vector(6 downto 0);	 
--	 constant SECRET_KEY_START : std_logic_vector(23 downto 0) := x"000000";
--    constant SECRET_KEY_END   : std_logic_vector(23 downto 0) := x"3FFFFF";
   
begin

    clk <= CLOCK_50;
    reset_n <= KEY(3);
	 
 
	 
  -- Instantiate multicore decryptor
    multicore_inst : multicore_decryption
      port map (
			clk               => clk,
			reset_n           => reset_n,
			start             => start_multicore,
			secret_key        => secret_key,
			done              => multicore_done,
			secret_key_found  => secret_key_found,
			active_core       => active_core
		);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                start_multicore <= '1';  -- <== Reset triggers a fresh start
            elsif multicore_done = '1' then
                start_multicore <= '0';  -- Disable after completion
            end if;
        end if;
    end process;


--    LEDR(0) <= multicore_done;  -- Show completion status
--  LEDR(9) <= start_core; -- Show when core is active
--	 LEDR(1) <= secret_key_found_flag;
	 
	 -- LED3 lights up if all cores are done and none found the key
	 LEDR(3) <= '1' when (multicore_done = '1' and secret_key_found = '0') else '0';


	 LEDR(9) <= '1' when (secret_key_found = '1' and active_core = "11") else '0';  -- Core 3
	 LEDR(8) <= '1' when (secret_key_found = '1' and active_core = "10") else '0';  -- Core 2
	 LEDR(7) <= '1' when (secret_key_found = '1' and active_core = "01") else '0';  -- Core 1
	 LEDR(6) <= '1' when (secret_key_found = '1' and active_core = "00") else '0';  -- Core 0



    SevenSegmentDisplayDecoder_inst0: SevenSegmentDisplayDecoder
    port map (
      ssOut => Seven_Seg_Val0,
      nIn   => secret_key(3 downto 0)
    );

    SevenSegmentDisplayDecoder_inst1: SevenSegmentDisplayDecoder
      port map (
        ssOut => Seven_Seg_Val1,
        nIn   => secret_key(7 downto 4)
      );

    SevenSegmentDisplayDecoder_inst2: SevenSegmentDisplayDecoder
      port map (
        ssOut => Seven_Seg_Val2,
        nIn   => secret_key(11 downto 8)
      );

    SevenSegmentDisplayDecoder_inst3: SevenSegmentDisplayDecoder
      port map (
        ssOut => Seven_Seg_Val3,
        nIn   => secret_key(15 downto 12)
      );

    SevenSegmentDisplayDecoder_inst4: SevenSegmentDisplayDecoder
      port map (
        ssOut => Seven_Seg_Val4,
        nIn   => secret_key(19 downto 16)
      );

    SevenSegmentDisplayDecoder_inst5: SevenSegmentDisplayDecoder
      port map (
        ssOut => Seven_Seg_Val5,
        nIn   => secret_key(23 downto 20)
      );

    HEX0 <= Seven_Seg_Val0;
    HEX1 <= Seven_Seg_Val1;
    HEX2 <= Seven_Seg_Val2;
    HEX3 <= Seven_Seg_Val3;
    HEX4 <= Seven_Seg_Val4;
    HEX5 <= Seven_Seg_Val5;
end RTL;


