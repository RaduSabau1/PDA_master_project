-- Layer under symbol_renderer and top for (button_pulse & lfsr_random)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity random_matrix is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        btnC       : in  STD_LOGIC;
        spin_block : in  STD_LOGIC;  -- Block spins when high (during animation)
        matrix_out : out STD_LOGIC_VECTOR(26 downto 0);  -- 9 cells, each 3 bits (values 0-4)
        spin_done  : out STD_LOGIC  -- pulse when spin completes
    );
end random_matrix;

architecture Behavioral of random_matrix is
    component lfsr_random
        Port ( clk, reset, next_num : in STD_LOGIC; random_out : out STD_LOGIC_VECTOR(7 downto 0) );
    end component;

    component button_pulse
        Port ( clk, btn : in STD_LOGIC; pulse : out STD_LOGIC );
    end component;

    signal rand_val  : STD_LOGIC_VECTOR(7 downto 0);
    signal btn_pulse : STD_LOGIC;
    signal next_rand : STD_LOGIC;
    type matrix_array is array(0 to 8) of STD_LOGIC_VECTOR(2 downto 0);
    signal matrix : matrix_array := (others => (others => '0'));
    signal index : integer range 0 to 9 := 0;
    signal loading : STD_LOGIC := '0';
begin

    rand_gen : lfsr_random port map(clk => clk, reset => reset, next_num => next_rand, random_out => rand_val);
    btn_edge : button_pulse port map(clk => clk, btn => btnC, pulse => btn_pulse);

    process(clk, reset)
    begin
        if reset = '1' then
            matrix <= (others => (others => '0'));
            index <= 0;
            loading <= '0';
            next_rand <= '0';
            spin_done <= '0';
        elsif rising_edge(clk) then
            next_rand <= '0';
            spin_done <= '0';

            if btn_pulse = '1' and spin_block = '0' then
                index <= 0;
                loading <= '1';
            elsif loading = '1' then
                next_rand <= '1';
                matrix(index) <= std_logic_vector(to_unsigned(to_integer(unsigned(rand_val(2 downto 0))) mod 5, 3));
                index <= index + 1;

                if index = 8 then
                    loading <= '0';
                    spin_done <= '1';  -- signal spin complete
                end if;
            end if;
        end if;
    end process;

    -- Flatten to single vector
    matrix_out <= matrix(0) & matrix(1) & matrix(2) &
                  matrix(3) & matrix(4) & matrix(5) &
                  matrix(6) & matrix(7) & matrix(8);

end Behavioral;
