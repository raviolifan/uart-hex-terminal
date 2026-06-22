-- Project: UART Hex Terminal
-- Target Board: Digilent Basys 3 (Artix-7 FPGA)
--
-- Description:
--   UART-driven hexadecimal terminal implemented on the Basys 3 FPGA.
--   Characters received from a serial terminal (e.g., Tera Term) are
--   decoded and displayed on the four-digit seven-segment display.
--
-- Supported Inputs:
--   0-9, A-F, a-f : Display hexadecimal digit
--   Backspace     : Remove most recently entered digit
--   Delete        : Remove most recently entered digit
--   Space         : Clear display
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity uart_test is
   port(
      clk, btnC, btnU: in std_logic;
      rx: in std_logic;
      tx: out std_logic;
      sseg: out std_logic_vector(7 downto 0);
      led: out std_logic_vector(7 downto 0);
      an: out std_logic_vector(3 downto 0)
   );
end uart_test;

architecture arch of uart_test is
   signal tx_full, rx_empty, rx_empty_d: std_logic;
   signal rec_data,rec_data1: std_logic_vector(7 downto 0);
   signal btn_tick: std_logic;
   signal hex_digit: std_logic_vector(3 downto 0);
   signal rd_uart: std_logic;
   signal digit3, digit2, digit1, digit0 : std_logic_vector(3 downto 0);
   signal sseg3, sseg2, sseg1, sseg0 : std_logic_vector(7 downto 0);
    
begin
   -- instantiate uart
   uart_unit: entity work.uart(str_arch)
      port map(clk=>clk, reset=>btnC, rd_uart=>rd_uart,
               wr_uart=>btn_tick, rx=>rx, w_data=>rec_data1,
               tx_full=>tx_full, rx_empty=>rx_empty,
               r_data=>rec_data, tx=>tx);
  -- instantiate sseg
    hex0: entity work.hex_to_sseg
        port map(hex=>digit0, dp=>'1', sseg=>sseg0);
    
    hex1: entity work.hex_to_sseg
       port map(hex=>digit1, dp=>'1', sseg=>sseg1);
    
    hex2: entity work.hex_to_sseg
       port map(hex=>digit2, dp=>'1', sseg=>sseg2);
    
    hex3: entity work.hex_to_sseg
       port map(hex=>digit3, dp=>'1', sseg=>sseg3);
    -- instantiate sseg
     disp_unit: entity work.disp_mux
       port map( clk  => clk, reset=> btnC,
          in3=>sseg3, in2=>sseg2,
          in1=>sseg1, in0=>sseg0,
    
          an=>an,
          sseg=>sseg
       );
   -- instantiate debounce
   btn_db_unit: entity work.debounce(fsmd_arch)
      port map(clk=>clk, reset=>btnC,
               sw => btnU,
               db_level=>open, db_tick=>btn_tick);
   
   led<=rec_data;
   
  -- ==========================================================================
-- Display Shift Register and UART Command Processing
--
-- Commands:
--   0-9, A-F, a-f : Shift hexadecimal digit onto display
--   Backspace     : Remove most recent digit (ASCII 08h or 7Fh)
--   Space         : Clear display
--
-- New UART characters are detected by monitoring the transition of
-- rx_empty from '1' to '0'. A read pulse is generated to remove the
-- character from the receive FIFO.
-- ==========================================================================
 
process(clk, btnC)
begin
   -- Asynchronous reset: clear all displayed digits
    if btnC = '1' then
          digit3<=(others=>'0');
          digit2<=(others=>'0');
          digit1<=(others=>'0');
          digit0<=(others=>'0');
   elsif rising_edge(clk) then
      -- Save previous FIFO empty state for edge detection
    rx_empty_d<=rx_empty;
      -- Detect arrival of a new UART character
      if rx_empty_d='1' and rx_empty='0' then
          -- Backspace/Delete command
          -- Shift digits right and clear the leftmost positio
          if rec_data = x"08" or rec_data = x"7F" then
              digit0<=digit1;
              digit1<=digit2;
              digit2<=digit3;
              digit3<=x"0";
          -- Space character clears the displa
          elsif rec_data = x"20" then
              digit3<=(others=>'0');
              digit2<=(others=>'0');
              digit1<=(others=>'0');
              digit0<=(others=>'0');
          -- Valid hexadecimal character
          -- Shift existing digits and insert newest digit
          else
             digit3<=digit2;
             digit2<=digit1;
             digit1<=digit0;
             digit0<=hex_digit;
         end if;
         -- Generate UART FIFO read pulse
         rd_uart<='1';
      else
        -- No new UART data available
        rd_uart<='0';
      end if;
   end if;
end process;

-- ==============================================================
-- ASCII to Hexadecimal Decoder
--
-- Converts received UART ASCII characters into a 4-bit
-- hexadecimal value for display.
--
-- Supported inputs:
--   '0' - '9'  (30h - 39h)
--   'A' - 'F'  (41h - 46h)
--   'a' - 'f'  (61h - 66h)
--
-- Examples:
--   ASCII '5' (35h) -> 0101
--   ASCII 'A' (41h) -> 1010
--   ASCII 'F' (46h) -> 1111
--
-- Any unsupported character is decoded as 0.
-- ==============================================================

process(rec_data)
begin
   -- Decode ASCII digits 0-9
   if rec_data >= x"30" and rec_data <= x"39" then
      hex_digit <= rec_data(3 downto 0);

   -- Decode uppercase hexadecimal letters A-F
   elsif rec_data >= x"41" and rec_data <= x"46" then
      hex_digit <= std_logic_vector(
                     unsigned(rec_data(3 downto 0)) + 9);
   
   -- Decode lowercase hexadecimal letters a-f
   elsif rec_data >= x"61" and rec_data <= x"66" then
      hex_digit <= std_logic_vector(
                     unsigned(rec_data(3 downto 0)) + 9);
   
   -- Unsupported characterelse
      hex_digit <= x"0";
   end if;
end process;   
   
end arch;
