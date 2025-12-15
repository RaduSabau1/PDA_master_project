library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity credit_system is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        spin_done  : in  STD_LOGIC;
        stake      : in  STD_LOGIC_VECTOR(3 downto 0);  -- Current stake (1-10)
        matrix     : in  STD_LOGIC_VECTOR(26 downto 0);
        credits_bcd : out STD_LOGIC_VECTOR(15 downto 0);
        win_rows   : out STD_LOGIC_VECTOR(2 downto 0)   -- Which rows won (bit 0=row0, bit 1=row1, bit 2=row2)
    );
end credit_system;

architecture Behavioral of credit_system is
    signal credits : integer range 0 to 9999 := 100;
    signal bcd_reg : STD_LOGIC_VECTOR(15 downto 0) := x"0100";
    signal stake_int : integer range 1 to 10;
    signal win_rows_reg : STD_LOGIC_VECTOR(2 downto 0) := "000";

    function get_cell(mat : STD_LOGIC_VECTOR(26 downto 0); idx : integer) return STD_LOGIC_VECTOR is
    begin
        return mat((26 - idx*3) downto (24 - idx*3));
    end function;

begin

    -- Convert stake to integer (ensure minimum of 1)
    stake_int <= 1 when to_integer(unsigned(stake)) = 0 else to_integer(unsigned(stake));

    process(clk, reset)
        variable cell0, cell1, cell2 : STD_LOGIC_VECTOR(2 downto 0);
        variable cell3, cell4, cell5 : STD_LOGIC_VECTOR(2 downto 0);
        variable cell6, cell7, cell8 : STD_LOGIC_VECTOR(2 downto 0);
        variable wins : integer;
        variable new_credits : integer;
        variable temp_val : integer;
        variable thousands, hundreds, tens, ones : integer;
    begin
        if reset = '1' then
            credits <= 100;
            bcd_reg <= x"0100";
        elsif rising_edge(clk) then
            -- Always update BCD from current credits (every clock cycle)
            temp_val := credits;
            thousands := temp_val / 1000;
            temp_val := temp_val mod 1000;
            hundreds := temp_val / 100;
            temp_val := temp_val mod 100;
            tens := temp_val / 10;
            ones := temp_val mod 10;

            bcd_reg <= std_logic_vector(to_unsigned(thousands, 4)) &
                       std_logic_vector(to_unsigned(hundreds, 4)) &
                       std_logic_vector(to_unsigned(tens, 4)) &
                       std_logic_vector(to_unsigned(ones, 4));

            -- Update credits only on spin_done
            if spin_done = '1' then
                cell0 := get_cell(matrix, 0);
                cell1 := get_cell(matrix, 1);
                cell2 := get_cell(matrix, 2);
                cell3 := get_cell(matrix, 3);
                cell4 := get_cell(matrix, 4);
                cell5 := get_cell(matrix, 5);
                cell6 := get_cell(matrix, 6);
                cell7 := get_cell(matrix, 7);
                cell8 := get_cell(matrix, 8);

                wins := 0;
                win_rows_reg <= "000";

                if cell0 = cell1 and cell1 = cell2 then
                    wins := wins + 1;
                    win_rows_reg(0) <= '1';
                end if;
                if cell3 = cell4 and cell4 = cell5 then
                    wins := wins + 1;
                    win_rows_reg(1) <= '1';
                end if;
                if cell6 = cell7 and cell7 = cell8 then
                    wins := wins + 1;
                    win_rows_reg(2) <= '1';
                end if;

                new_credits := credits - stake_int + (wins * 5 * stake_int);

                if new_credits < 0 then
                    new_credits := 0;
                elsif new_credits > 9999 then
                    new_credits := 9999;
                end if;

                credits <= new_credits;
            end if;
        end if;
    end process;

    credits_bcd <= bcd_reg;
    win_rows <= win_rows_reg;

end Behavioral;
