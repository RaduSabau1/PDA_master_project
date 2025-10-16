library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity button_pulse is
    Port (
        clk   : in  STD_LOGIC;
        btn   : in  STD_LOGIC;
        pulse : out STD_LOGIC
    );
end button_pulse;

architecture Behavioral of button_pulse is
    signal btn_sync, btn_prev : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            btn_sync <= btn;
            pulse <= '1' when (btn_sync = '1' and btn_prev = '0') else '0';
            btn_prev <= btn_sync;
        end if;
    end process;
end Behavioral;
