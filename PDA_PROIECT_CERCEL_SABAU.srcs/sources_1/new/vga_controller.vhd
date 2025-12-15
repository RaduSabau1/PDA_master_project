library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port (
        clk100 : in  STD_LOGIC;     -- Basys 3 100 MHz clock
        reset  : in  STD_LOGIC;
        hsync  : out STD_LOGIC;
        vsync  : out STD_LOGIC;
        video_on : out STD_LOGIC;
        pixel_x : out STD_LOGIC_VECTOR(9 downto 0);
        pixel_y : out STD_LOGIC_VECTOR(9 downto 0)
    );
end vga_controller;

architecture Behavioral of vga_controller is
    signal clk25   : STD_LOGIC := '0';
    signal clk_div : STD_LOGIC := '0';
    signal h_count, v_count : unsigned(9 downto 0) := (others => '0');
begin
    -- Clock divider: 100 MHz → 25 MHz
    process(clk100)
    begin
        if rising_edge(clk100) then
            clk_div <= not clk_div;
            if clk_div = '1' then
                clk25 <= not clk25;
            end if;
        end if;
    end process;

    process(clk25, reset)
    begin
        if reset = '1' then
            h_count <= (others => '0');
            v_count <= (others => '0');
        elsif rising_edge(clk25) then
            if h_count = 799 then
                h_count <= (others => '0');
                if v_count = 524 then
                    v_count <= (others => '0');
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;

    -- HSYNC: active low during counts 656-751
    hsync <= '0' when (h_count >= 656 and h_count < 752) else '1';
    -- VSYNC: active low during counts 490-491
    vsync <= '0' when (v_count >= 490 and v_count < 492) else '1';

    -- Visible area: 640×480
    video_on <= '1' when (h_count < 640 and v_count < 480) else '0';
    pixel_x <= std_logic_vector(h_count);
    pixel_y <= std_logic_vector(v_count);
end Behavioral;
