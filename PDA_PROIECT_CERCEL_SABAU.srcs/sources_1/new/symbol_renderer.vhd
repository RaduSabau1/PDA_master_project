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
        btnR     : in  STD_LOGIC;  -- Double game: choose red
        btnL     : in  STD_LOGIC;  -- Double game: choose black
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
               double_adjust : in STD_LOGIC_VECTOR(15 downto 0);
               apply_adjust  : in STD_LOGIC;
               credits_bcd : out STD_LOGIC_VECTOR(15 downto 0);
               win_rows   : out STD_LOGIC_VECTOR(2 downto 0);
               hand_winnings : out STD_LOGIC_VECTOR(15 downto 0) );
    end component;

    component win_animation
        Port ( clk, reset : in STD_LOGIC;
               spin_done  : in STD_LOGIC;
               win_rows   : in STD_LOGIC_VECTOR(2 downto 0);
               animating  : out STD_LOGIC;
               flash_on   : out STD_LOGIC;
               active_rows: out STD_LOGIC_VECTOR(2 downto 0);
               animation_done : out STD_LOGIC );
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

    component double_game
        Port ( clk           : in  STD_LOGIC;
               reset         : in  STD_LOGIC;
               spin_done     : in  STD_LOGIC;
               win_rows      : in  STD_LOGIC_VECTOR(2 downto 0);
               animation_done: in  STD_LOGIC;
               btnR          : in  STD_LOGIC;
               btnL          : in  STD_LOGIC;
               btnC          : in  STD_LOGIC;
               pixel_x       : in  STD_LOGIC_VECTOR(9 downto 0);
               pixel_y       : in  STD_LOGIC_VECTOR(9 downto 0);
               video_on      : in  STD_LOGIC;
               stake         : in  STD_LOGIC_VECTOR(3 downto 0);
               hand_winnings : in  STD_LOGIC_VECTOR(15 downto 0);
               double_active : out STD_LOGIC;
               double_rgb    : out STD_LOGIC_VECTOR(11 downto 0);
               credits_delta : out STD_LOGIC_VECTOR(15 downto 0);
               apply_delta   : out STD_LOGIC;
               block_spin    : out STD_LOGIC );
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
    signal animation_done : STD_LOGIC;

    -- Double game signals
    signal double_active : STD_LOGIC;
    signal double_rgb : STD_LOGIC_VECTOR(11 downto 0);
    signal credits_delta : STD_LOGIC_VECTOR(15 downto 0);
    signal apply_delta : STD_LOGIC;
    signal block_spin : STD_LOGIC;
    signal hand_winnings : STD_LOGIC_VECTOR(15 downto 0);

    -- Final RGB output
    signal final_red, final_green, final_blue : std_logic_vector(3 downto 0);

    -- Combined spin block signal
    signal spin_block_combined : STD_LOGIC;

begin
    -- Combine spin blocking signals
    spin_block_combined <= animating or block_spin;
    vga_gen : vga_controller port map(
        clk100 => clk100, reset => reset,
        hsync => hsync, vsync => vsync,
        video_on => video_on,
        pixel_x => px, pixel_y => py
    );

    rand_mat : random_matrix port map(
        clk => clk100, reset => reset, btnC => btnC,
        spin_block => spin_block_combined,
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
        matrix => matrix,
        double_adjust => credits_delta,
        apply_adjust => apply_delta,
        credits_bcd => credits_bcd,
        win_rows => win_rows,
        hand_winnings => hand_winnings
    );

    win_anim : win_animation port map(
        clk => clk100, reset => reset,
        spin_done => spin_done, win_rows => win_rows,
        animating => animating, flash_on => flash_on,
        active_rows => active_rows,
        animation_done => animation_done
    );

    -- Double game controller
    double_ctrl : double_game port map(
        clk => clk100, reset => reset,
        spin_done => spin_done, win_rows => win_rows,
        animation_done => animation_done,
        btnR => btnR, btnL => btnL, btnC => btnC,
        pixel_x => px, pixel_y => py,
        video_on => video_on,
        stake => stake,
        hand_winnings => hand_winnings,
        double_active => double_active,
        double_rgb => double_rgb,
        credits_delta => credits_delta,
        apply_delta => apply_delta,
        block_spin => block_spin
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

    -- Display multiplexer: double game overrides normal display
    final_red   <= double_rgb(11 downto 8) when double_active = '1' else red;
    final_green <= double_rgb(7 downto 4)  when double_active = '1' else green;
    final_blue  <= double_rgb(3 downto 0)  when double_active = '1' else blue;

    VGA_HS <= hsync;
    VGA_VS <= vsync;
    VGA_R <= final_red;
    VGA_G <= final_green;
    VGA_B <= final_blue;

end Behavioral;
