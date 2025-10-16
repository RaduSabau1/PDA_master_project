library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lfsr_random is
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        next  : in  STD_LOGIC;  -- pulse to generate a new number
        random_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end lfsr_random;

architecture Behavioral of lfsr_random is
    signal lfsr_reg : STD_LOGIC_VECTOR(7 downto 0) := "10101100";
    signal feedback : STD_LOGIC;
begin
    feedback <= lfsr_reg(7) xor lfsr_reg(5) xor lfsr_reg(4) xor lfsr_reg(3);

    process(clk, reset)
    begin
        if reset = '1' then
            lfsr_reg <= "10101100";
        elsif rising_edge(clk) then
            if next = '1' then
                lfsr_reg <= lfsr_reg(6 downto 0) & feedback;
            end if;
        end if;
    end process;

    random_out <= lfsr_reg;
end Behavioral;
