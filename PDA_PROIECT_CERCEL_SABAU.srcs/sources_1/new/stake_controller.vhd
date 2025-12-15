-- Stake controller: handles stake increase/decrease with btnU/btnD
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stake_controller is
    Port (
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        btnU      : in  STD_LOGIC;  -- Increase stake
        btnD      : in  STD_LOGIC;  -- Decrease stake
        stake     : out STD_LOGIC_VECTOR(3 downto 0);  -- Current stake (1-10)
        stake_bcd : out STD_LOGIC_VECTOR(15 downto 0)  -- BCD for display
    );
end stake_controller;

architecture Behavioral of stake_controller is
    signal stake_val : integer range 1 to 10 := 1;
    signal btnU_sync, btnU_prev : STD_LOGIC := '0';
    signal btnD_sync, btnD_prev : STD_LOGIC := '0';
    signal btnU_pulse, btnD_pulse : STD_LOGIC := '0';
begin

    process(clk, reset)
        variable temp_val : integer;
        variable thousands, hundreds, tens, ones : integer;
    begin
        if reset = '1' then
            stake_val <= 1;
            btnU_sync <= '0';
            btnU_prev <= '0';
            btnD_sync <= '0';
            btnD_prev <= '0';
        elsif rising_edge(clk) then
            -- Synchronize buttons
            btnU_sync <= btnU;
            btnU_prev <= btnU_sync;
            btnD_sync <= btnD;
            btnD_prev <= btnD_sync;

            -- Detect rising edges
            btnU_pulse <= btnU_sync and not btnU_prev;
            btnD_pulse <= btnD_sync and not btnD_prev;

            -- Update stake on button press
            if btnU_sync = '1' and btnU_prev = '0' then
                if stake_val < 10 then
                    stake_val <= stake_val + 1;
                end if;
            elsif btnD_sync = '1' and btnD_prev = '0' then
                if stake_val > 1 then
                    stake_val <= stake_val - 1;
                end if;
            end if;
        end if;
    end process;

    -- Output stake as 4-bit value
    stake <= std_logic_vector(to_unsigned(stake_val, 4));

    -- Generate BCD output for display (stake is 1-10, so simple conversion)
    process(stake_val)
        variable tens_v, ones_v : integer;
    begin
        tens_v := stake_val / 10;
        ones_v := stake_val mod 10;
        stake_bcd <= x"00" & std_logic_vector(to_unsigned(tens_v, 4)) &
                     std_logic_vector(to_unsigned(ones_v, 4));
    end process;

end Behavioral;
