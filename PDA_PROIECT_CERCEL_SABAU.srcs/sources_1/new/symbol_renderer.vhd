-- TOP layer (includes vga_timing, random_matrix, credit_system & 7-segment display)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity symbol_renderer is
    Port (
        clk100   : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        btnC     : in  STD_LOGIC;
        btnU     : in  STD_LOGIC;  -- Stake increase
        btnD     : in  STD_LOGIC;  -- Stake decrease
        sw15     : in  STD_LOGIC;  -- Display toggle: 0=credits, 1=stake
        VGA_HS   : out STD_LOGIC;
        VGA_VS   : out STD_LOGIC;
        VGA_R    : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G    : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B    : out STD_LOGIC_VECTOR(3 downto 0);
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC_VECTOR(3 downto 0)
    );
end symbol_renderer;

architecture Behavioral of symbol_renderer is

    component vga_controller
        Port ( clk100, reset : in STD_LOGIC;
               hsync, vsync, video_on : out STD_LOGIC;
               pixel_x, pixel_y : out STD_LOGIC_VECTOR(9 downto 0) );
    end component;

    component random_matrix
        Port ( clk, reset, btnC : in STD_LOGIC;
               spin_block : in STD_LOGIC;
               matrix_out : out STD_LOGIC_VECTOR(26 downto 0);
               spin_done  : out STD_LOGIC );
    end component;

    component credit_system
        Port ( clk, reset : in STD_LOGIC;
               spin_done  : in STD_LOGIC;
               stake      : in STD_LOGIC_VECTOR(3 downto 0);
               matrix     : in STD_LOGIC_VECTOR(26 downto 0);
               credits_bcd : out STD_LOGIC_VECTOR(15 downto 0);
               win_rows   : out STD_LOGIC_VECTOR(2 downto 0) );
    end component;

    component win_animation
        Port ( clk, reset : in STD_LOGIC;
               spin_done  : in STD_LOGIC;
               win_rows   : in STD_LOGIC_VECTOR(2 downto 0);
               animating  : out STD_LOGIC;
               flash_on   : out STD_LOGIC;
               active_rows: out STD_LOGIC_VECTOR(2 downto 0) );
    end component;

    component stake_controller
        Port ( clk, reset : in STD_LOGIC;
               btnU, btnD : in STD_LOGIC;
               stake      : out STD_LOGIC_VECTOR(3 downto 0);
               stake_bcd  : out STD_LOGIC_VECTOR(15 downto 0) );
    end component;

    component seven_seg_controller
        Port ( clk, reset : in STD_LOGIC;
               value : in STD_LOGIC_VECTOR(15 downto 0);
               seg   : out STD_LOGIC_VECTOR(6 downto 0);
               an    : out STD_LOGIC_VECTOR(3 downto 0) );
    end component;

    signal video_on : STD_LOGIC;
    signal px, py : STD_LOGIC_VECTOR(9 downto 0);
    signal matrix : STD_LOGIC_VECTOR(26 downto 0);
    signal spin_done : STD_LOGIC;
    signal credits_bcd : STD_LOGIC_VECTOR(15 downto 0);
    signal stake : STD_LOGIC_VECTOR(3 downto 0);
    signal stake_bcd : STD_LOGIC_VECTOR(15 downto 0);
    signal display_value : STD_LOGIC_VECTOR(15 downto 0);
    signal symbol_id : integer range 0 to 4 := 0;
    signal cell_x, cell_y : integer range 0 to 2 := 0;
    signal red, green, blue : std_logic_vector(3 downto 0);
    signal hsync, vsync : std_logic;

    -- Win animation signals
    signal win_rows : STD_LOGIC_VECTOR(2 downto 0);
    signal animating : STD_LOGIC;
    signal flash_on : STD_LOGIC;
    signal active_rows : STD_LOGIC_VECTOR(2 downto 0);
    signal draw_win_line : STD_LOGIC;

begin
    vga_gen : vga_controller port map(
        clk100 => clk100, reset => reset,
        hsync => hsync, vsync => vsync,
        video_on => video_on,
        pixel_x => px, pixel_y => py
    );

    rand_mat : random_matrix port map(
        clk => clk100, reset => reset, btnC => btnC,
        spin_block => animating,
        matrix_out => matrix, spin_done => spin_done
    );

    stake_ctrl : stake_controller port map(
        clk => clk100, reset => reset,
        btnU => btnU, btnD => btnD,
        stake => stake, stake_bcd => stake_bcd
    );

    credits : credit_system port map(
        clk => clk100, reset => reset,
        spin_done => spin_done, stake => stake,
        matrix => matrix, credits_bcd => credits_bcd,
        win_rows => win_rows
    );

    win_anim : win_animation port map(
        clk => clk100, reset => reset,
        spin_done => spin_done, win_rows => win_rows,
        animating => animating, flash_on => flash_on,
        active_rows => active_rows
    );

    -- Display toggle: sw15=0 shows credits, sw15=1 shows stake
    display_value <= stake_bcd when sw15 = '1' else credits_bcd;

    display : seven_seg_controller port map(
        clk => clk100, reset => reset,
        value => display_value,
        seg => seg, an => an
    );

    process(px, py, matrix)
        variable x, y : integer;
        variable cx, cy : integer;
        variable idx : integer;
    begin
        x := to_integer(unsigned(px));
        y := to_integer(unsigned(py));

        -- Compute which cell the pixel is in (3×3 grid)
        -- Clamp to valid range to avoid out-of-bounds during blanking
        cx := x / 213;  -- 640 / 3 ≈ 213
        cy := y / 160;  -- 480 / 3 = 160
        if cx > 2 then cx := 2; end if;
        if cy > 2 then cy := 2; end if;

        cell_x <= cx;
        cell_y <= cy;
        idx := cy * 3 + cx;
        symbol_id <= to_integer(unsigned(matrix((26 - idx*3) downto (24 - idx*3))));  -- 3 bits per cell
    end process;

    -- Determine if we should draw a win line at current pixel
    -- Each row is 160 pixels tall, line is 8 pixels thick in the middle
    -- Row 0: y=76-83, Row 1: y=236-243, Row 2: y=396-403
    process(py, active_rows, flash_on)
        variable y : integer;
    begin
        y := to_integer(unsigned(py));
        draw_win_line <= '0';
        if flash_on = '1' then
            -- Row 0 win line (y = 76-83)
            if active_rows(0) = '1' and y >= 76 and y <= 83 then
                draw_win_line <= '1';
            end if;
            -- Row 1 win line (y = 236-243)
            if active_rows(1) = '1' and y >= 236 and y <= 243 then
                draw_win_line <= '1';
            end if;
            -- Row 2 win line (y = 396-403)
            if active_rows(2) = '1' and y >= 396 and y <= 403 then
                draw_win_line <= '1';
            end if;
        end if;
    end process;

    -- Color mapping for symbols (5 colors) with win line overlay
    process(video_on, symbol_id, draw_win_line)
    begin
        if video_on = '1' then
            if draw_win_line = '1' then
                -- Draw black line for winning row
                red <= "0000"; green <= "0000"; blue <= "0000";
            else
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
            end if;
        else
            red <= (others => '0');
            green <= (others => '0');
            blue <= (others => '0');
        end if;
    end process;

    VGA_HS <= hsync;
    VGA_VS <= vsync;
    VGA_R <= red;
    VGA_G <= green;
    VGA_B <= blue;

end Behavioral;
