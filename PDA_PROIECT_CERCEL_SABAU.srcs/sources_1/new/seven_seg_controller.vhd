library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_controller is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        value   : in  STD_LOGIC_VECTOR(15 downto 0);  -- 4 digits, 4 bits each (BCD)
        seg     : out STD_LOGIC_VECTOR(6 downto 0);   -- segment cathodes (active low)
        an      : out STD_LOGIC_VECTOR(3 downto 0)    -- digit anodes (active low)
    );
end seven_seg_controller;

architecture Behavioral of seven_seg_controller is
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal digit_select : unsigned(1 downto 0) := (others => '0');
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0);
begin

    -- Refresh counter for multiplexing (~1kHz refresh rate)
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    digit_select <= refresh_counter(19 downto 18);

    -- Select which digit to display and which anode to enable
    process(digit_select, value)
    begin
        case digit_select is
            when "00" =>
                an <= "1110";  -- rightmost digit (ones)
                current_digit <= value(3 downto 0);
            when "01" =>
                an <= "1101";  -- tens
                current_digit <= value(7 downto 4);
            when "10" =>
                an <= "1011";  -- hundreds
                current_digit <= value(11 downto 8);
            when others =>
                an <= "0111";  -- leftmost digit (thousands)
                current_digit <= value(15 downto 12);
        end case;
    end process;

    -- 7-segment decoder (active low: 0 = segment ON)
    -- seg(6 downto 0) = gfedcba (matches constraint: seg[0]=CA, seg[6]=CG)
    process(current_digit)
    begin
        case current_digit is
            --                   gfedcba
            when "0000" => seg <= "1000000";  -- 0
            when "0001" => seg <= "1111001";  -- 1
            when "0010" => seg <= "0100100";  -- 2
            when "0011" => seg <= "0110000";  -- 3
            when "0100" => seg <= "0011001";  -- 4
            when "0101" => seg <= "0010010";  -- 5
            when "0110" => seg <= "0000010";  -- 6
            when "0111" => seg <= "1111000";  -- 7
            when "1000" => seg <= "0000000";  -- 8
            when "1001" => seg <= "0010000";  -- 9
            when others => seg <= "1111111";  -- blank
        end case;
    end process;

end Behavioral;
