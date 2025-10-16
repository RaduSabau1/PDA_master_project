library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_matrix_display is
    Port (
        clk100   : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        btnC     : in  STD_LOGIC;
        hsync    : out STD_LOGIC;
        vsync    : out STD_LOGIC;
        red      : out STD_LOGIC_VECTOR(3 downto 0);
        green    : out STD_LOGIC_VECTOR(3 downto 0);
        blue     : out STD_LOGIC_VECTOR(3 downto 0)
    );
end vga_matrix_display;

architecture Behavioral of vga_matrix_display is

    component vga_controller
        Port ( clk100, reset : in STD_LOGIC;
               hsync, vsync, video_on : out STD_LOGIC;
               pixel_x, pixel_y : out STD_LOGIC_VECTOR(9 downto 0) );
    end component;

    component random_matrix
        Port ( clk, reset, btnC : in STD_LOGIC;
               matrix_out : out STD_LOGIC_VECTOR(8 downto 0) );
    end component;

    signal video_on : STD_LOGIC;
    signal px, py : STD_LOGIC_VECTOR(9 downto 0);
    signal matrix : STD_LOGIC_VECTOR(8 downto 0);
    signal symbol_id : integer range 0 to 4 := 0;
    signal cell_x, cell_y : integer range 0 to 2 := 0;
begin
    vga_gen : vga_controller port map(clk100 => clk100, reset => reset,
                                      hsync => hsync, vsync => vsync,
                                      video_on => video_on,
                                      pixel_x => px, pixel_y => py);

    rand_mat : random_matrix port map(clk => clk100, reset => reset, btnC => btnC, matrix_out => matrix);

    process(px, py)
        variable x, y : integer;
        variable idx : integer;
    begin
        x := to_integer(unsigned(px));
        y := to_integer(unsigned(py));

        -- Compute which cell the pixel is in (3×3 grid)
        cell_x <= x / 213;  -- 640 / 3 ≈ 213
        cell_y <= y / 160;  -- 480 / 3 = 160
        idx := cell_y * 3 + cell_x;
        symbol_id <= to_integer(unsigned(matrix((8 - idx) downto (8 - idx)))) ; -- 1 bit per cell for now
    end process;

    -- Color mapping for symbols (5 colors)
    process(video_on, symbol_id)
    begin
        if video_on = '1' then
            case symbol_id is
                when 0 =>
                    red <= "1111"; green <= "0000"; blue <= "0000"; -- red
                when 1 =>
                    red <= "0000"; green <= "1111"; blue <= "0000"; -- green
                when 2 =>
                    red <= "0000"; green <= "0000"; blue <= "1111"; -- blue
                when 3 =>
                    red <= "1111"; green <= "1111"; blue <= "0000"; -- yellow
                when 4 =>
                    red <= "1111"; green <= "0000"; blue <= "1111"; -- magenta
                when others =>
                    red <= "0000"; green <= "0000"; blue <= "0000";
            end case;
        else
            red <= (others => '0');
            green <= (others => '0');
            blue <= (others => '0');
        end if;
    end process;
end Behavioral;
