-- Double Game Controller: Red/Black gambling mini-game after wins
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity double_game is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        -- Trigger inputs
        spin_done     : in  STD_LOGIC;
        win_rows      : in  STD_LOGIC_VECTOR(2 downto 0);
        animation_done: in  STD_LOGIC;
        -- Button inputs
        btnR          : in  STD_LOGIC;  -- Choose red
        btnL          : in  STD_LOGIC;  -- Choose black
        btnC          : in  STD_LOGIC;  -- Exit double (new spin)
        -- Pixel position for display
        pixel_x       : in  STD_LOGIC_VECTOR(9 downto 0);
        pixel_y       : in  STD_LOGIC_VECTOR(9 downto 0);
        video_on      : in  STD_LOGIC;
        -- Credit interface
        stake         : in  STD_LOGIC_VECTOR(3 downto 0);
        hand_winnings : in  STD_LOGIC_VECTOR(15 downto 0);
        -- Outputs
        double_active : out STD_LOGIC;   -- High during double mode (overrides display)
        double_rgb    : out STD_LOGIC_VECTOR(11 downto 0);  -- RGB for double game
        credits_delta : out STD_LOGIC_VECTOR(15 downto 0);  -- Signed credit adjustment
        apply_delta   : out STD_LOGIC;   -- Pulse to apply credit adjustment
        block_spin    : out STD_LOGIC    -- Block new spins during double
    );
end double_game;

architecture Behavioral of double_game is

    -- State machine
    type state_type is (IDLE, DOUBLE_AVAILABLE, FLASHING, SHOW_RESULT, DISPLAY_WIN, DISPLAY_LOSE);
    signal state : state_type := IDLE;

    -- Timing constants (100 MHz clock)
    constant FLASH_PERIOD    : integer := 25000000;   -- 250ms
    constant RESULT_DURATION : integer := 50000000;   -- 500ms
    constant TEXT_DURATION   : integer := 300000000;  -- 3 seconds
    constant TEXT_FLASH      : integer := 25000000;   -- 250ms text flash

    -- Counters
    signal timer_counter   : integer range 0 to TEXT_DURATION := 0;
    signal flash_counter   : integer range 0 to FLASH_PERIOD := 0;
    signal text_flash_counter : integer range 0 to TEXT_FLASH := 0;

    -- Game state
    signal double_count    : integer range 0 to 5 := 0;
    signal user_choice     : STD_LOGIC := '0';  -- 0=red (btnR), 1=black (btnL)
    signal random_result   : STD_LOGIC := '0';  -- 0=red, 1=black
    signal flash_state     : STD_LOGIC := '0';  -- Current flash color (0=red, 1=black)
    signal text_flash_on   : STD_LOGIC := '0';  -- Text visibility toggle
    signal user_won        : STD_LOGIC := '0';  -- Result of double
    signal accumulated_win : integer range 0 to 9999 := 0;  -- Running winnings
    signal original_winnings : integer range 0 to 9999 := 0;  -- Original hand winnings (for loss calculation)

    -- LFSR for random number (8-bit, runs continuously)
    signal lfsr_reg : STD_LOGIC_VECTOR(7 downto 0) := "10101100";
    signal lfsr_feedback : STD_LOGIC;

    -- Button synchronization and edge detection
    signal btnR_sync, btnR_prev, btnR_pulse : STD_LOGIC := '0';
    signal btnL_sync, btnL_prev, btnL_pulse : STD_LOGIC := '0';
    signal btnC_sync, btnC_prev, btnC_pulse : STD_LOGIC := '0';

    -- Track if win happened (to enable double during animation)
    signal win_detected : STD_LOGIC := '0';
    signal spin_done_d1 : STD_LOGIC := '0';  -- Delayed spin_done by 1 clock

    -- Display signals
    signal rgb_out : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    signal in_text_region : STD_LOGIC := '0';

    -- Pixel coordinates as integers
    signal px, py : integer range 0 to 1023;

begin

    -- LFSR runs continuously for randomness
    lfsr_feedback <= lfsr_reg(7) xor lfsr_reg(5) xor lfsr_reg(4) xor lfsr_reg(3);

    process(clk, reset)
    begin
        if reset = '1' then
            lfsr_reg <= "10101100";
        elsif rising_edge(clk) then
            lfsr_reg <= lfsr_reg(6 downto 0) & lfsr_feedback;
        end if;
    end process;

    -- Button synchronization and edge detection
    process(clk, reset)
    begin
        if reset = '1' then
            btnR_sync <= '0'; btnR_prev <= '0'; btnR_pulse <= '0';
            btnL_sync <= '0'; btnL_prev <= '0'; btnL_pulse <= '0';
            btnC_sync <= '0'; btnC_prev <= '0'; btnC_pulse <= '0';
        elsif rising_edge(clk) then
            btnR_sync <= btnR; btnR_prev <= btnR_sync;
            btnL_sync <= btnL; btnL_prev <= btnL_sync;
            btnC_sync <= btnC; btnC_prev <= btnC_sync;

            btnR_pulse <= btnR_sync and not btnR_prev;
            btnL_pulse <= btnL_sync and not btnL_prev;
            btnC_pulse <= btnC_sync and not btnC_prev;
        end if;
    end process;

    -- Pixel coordinates
    px <= to_integer(unsigned(pixel_x));
    py <= to_integer(unsigned(pixel_y));

    -- Main state machine
    process(clk, reset)
        variable stake_int : integer;
    begin
        if reset = '1' then
            state <= IDLE;
            timer_counter <= 0;
            flash_counter <= 0;
            text_flash_counter <= 0;
            double_count <= 0;
            user_choice <= '0';
            random_result <= '0';
            flash_state <= '0';
            text_flash_on <= '0';
            user_won <= '0';
            accumulated_win <= 0;
            original_winnings <= 0;
            win_detected <= '0';
            spin_done_d1 <= '0';
            apply_delta <= '0';
            credits_delta <= (others => '0');

        elsif rising_edge(clk) then
            apply_delta <= '0';  -- Default: no credit change
            stake_int := to_integer(unsigned(stake));
            if stake_int = 0 then stake_int := 1; end if;

            -- Delay spin_done by 1 clock so win_rows is valid
            spin_done_d1 <= spin_done;

            case state is
                when IDLE =>
                    double_count <= 0;
                    accumulated_win <= 0;
                    original_winnings <= 0;
                    win_detected <= '0';

                    -- Detect a winning spin (use delayed spin_done so win_rows is updated)
                    if spin_done_d1 = '1' and win_rows /= "000" then
                        win_detected <= '1';
                        accumulated_win <= to_integer(unsigned(hand_winnings));
                        original_winnings <= to_integer(unsigned(hand_winnings));  -- Store for loss calculation
                        state <= DOUBLE_AVAILABLE;
                    end if;

                when DOUBLE_AVAILABLE =>
                    -- User can choose to double (btnR/btnL) or spin again (btnC)
                    if btnR_pulse = '1' then
                        user_choice <= '0';  -- Red
                        flash_state <= '0';
                        flash_counter <= 0;
                        state <= FLASHING;
                    elsif btnL_pulse = '1' then
                        user_choice <= '1';  -- Black
                        flash_state <= '0';
                        flash_counter <= 0;
                        state <= FLASHING;
                    elsif btnC_pulse = '1' then
                        -- User wants new spin, exit double mode
                        state <= IDLE;
                    end if;

                when FLASHING =>
                    -- Flash between red and black
                    flash_counter <= flash_counter + 1;
                    if flash_counter = FLASH_PERIOD - 1 then
                        flash_counter <= 0;
                        flash_state <= not flash_state;
                    end if;

                    -- User presses button to stop and pick
                    if btnR_pulse = '1' or btnL_pulse = '1' then
                        -- Capture random result from LFSR
                        random_result <= lfsr_reg(0);
                        timer_counter <= 0;
                        state <= SHOW_RESULT;
                    end if;

                when SHOW_RESULT =>
                    -- Show the random result for 500ms
                    timer_counter <= timer_counter + 1;
                    if timer_counter = RESULT_DURATION - 1 then
                        timer_counter <= 0;
                        text_flash_counter <= 0;
                        text_flash_on <= '1';
                        double_count <= double_count + 1;

                        -- Check if user won
                        if user_choice = random_result then
                            -- User wins - double the winnings
                            user_won <= '1';
                            accumulated_win <= accumulated_win * 2;
                            -- Add winnings to credits (doubles the previous win)
                            credits_delta <= std_logic_vector(to_signed(accumulated_win, 16));
                            apply_delta <= '1';
                            state <= DISPLAY_WIN;
                        else
                            -- User loses - subtract all accumulated winnings
                            -- This brings credits back to (before_hand - stake)
                            user_won <= '0';
                            credits_delta <= std_logic_vector(to_signed(-accumulated_win, 16));
                            apply_delta <= '1';
                            state <= DISPLAY_LOSE;
                        end if;
                    end if;

                when DISPLAY_WIN =>
                    -- Flash "WIN" text for 3 seconds
                    timer_counter <= timer_counter + 1;
                    text_flash_counter <= text_flash_counter + 1;

                    if text_flash_counter = TEXT_FLASH - 1 then
                        text_flash_counter <= 0;
                        text_flash_on <= not text_flash_on;
                    end if;

                    if timer_counter = TEXT_DURATION - 1 then
                        timer_counter <= 0;
                        if double_count >= 5 then
                            -- Max doubles reached
                            state <= IDLE;
                        else
                            -- Can double again
                            state <= DOUBLE_AVAILABLE;
                        end if;
                    end if;

                when DISPLAY_LOSE =>
                    -- Flash "LOSE" text for 3 seconds
                    timer_counter <= timer_counter + 1;
                    text_flash_counter <= text_flash_counter + 1;

                    if text_flash_counter = TEXT_FLASH - 1 then
                        text_flash_counter <= 0;
                        text_flash_on <= not text_flash_on;
                    end if;

                    if timer_counter = TEXT_DURATION - 1 then
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- Text pattern generator for WIN/LOSE
    -- Blocky text centered on screen
    -- Characters are 48 pixels wide, 64 pixels tall
    -- Screen center is 320x240
    process(px, py, state, text_flash_on)
        variable local_x, local_y : integer;
        variable char_width : integer := 48;
        variable char_height : integer := 64;
        variable char_gap : integer := 16;
        variable total_win_width : integer;
        variable total_lose_width : integer;
        variable start_x, start_y : integer;
    begin
        in_text_region <= '0';

        -- WIN text: 3 chars * 48 + 2 gaps * 16 = 176 pixels wide
        total_win_width := 3 * char_width + 2 * char_gap;
        -- LOSE text: 4 chars * 48 + 3 gaps * 16 = 240 pixels wide
        total_lose_width := 4 * char_width + 3 * char_gap;

        start_y := 240 - char_height / 2;  -- Center vertically

        if state = DISPLAY_WIN and text_flash_on = '1' then
            start_x := 320 - total_win_width / 2;

            -- Check if in WIN text region (y check first)
            if py >= start_y and py < start_y + char_height then
                local_y := py - start_y;

                -- W character (start_x to start_x + 47)
                if px >= start_x and px < start_x + char_width then
                    local_x := px - start_x;
                    -- W pattern: vertical bars at edges and middle, connected at bottom
                    if local_x < 8 or local_x > 40 or (local_x >= 20 and local_x <= 28) then
                        in_text_region <= '1';
                    elsif local_y > 48 then
                        if (local_x >= 8 and local_x < 20) or (local_x > 28 and local_x <= 40) then
                            in_text_region <= '1';
                        end if;
                    end if;
                end if;

                -- I character
                if px >= start_x + char_width + char_gap and px < start_x + 2*char_width + char_gap then
                    local_x := px - (start_x + char_width + char_gap);
                    -- I pattern: horizontal top/bottom, vertical center
                    if local_y < 8 or local_y > 56 then
                        in_text_region <= '1';  -- Top and bottom bars
                    elsif local_x >= 16 and local_x <= 32 then
                        in_text_region <= '1';  -- Vertical stem
                    end if;
                end if;

                -- N character
                if px >= start_x + 2*(char_width + char_gap) and px < start_x + 3*char_width + 2*char_gap then
                    local_x := px - (start_x + 2*(char_width + char_gap));
                    -- N pattern: two vertical bars with diagonal
                    if local_x < 8 or local_x > 40 then
                        in_text_region <= '1';  -- Left and right verticals
                    elsif local_x >= (local_y * 36 / 64) and local_x <= (local_y * 36 / 64) + 8 then
                        in_text_region <= '1';  -- Diagonal
                    end if;
                end if;
            end if;

        elsif state = DISPLAY_LOSE and text_flash_on = '1' then
            start_x := 320 - total_lose_width / 2;

            if py >= start_y and py < start_y + char_height then
                local_y := py - start_y;

                -- L character
                if px >= start_x and px < start_x + char_width then
                    local_x := px - start_x;
                    -- L pattern: vertical left, horizontal bottom
                    if local_x < 8 then
                        in_text_region <= '1';
                    elsif local_y > 56 then
                        in_text_region <= '1';
                    end if;
                end if;

                -- O character
                if px >= start_x + char_width + char_gap and px < start_x + 2*char_width + char_gap then
                    local_x := px - (start_x + char_width + char_gap);
                    -- O pattern: rectangle outline
                    if local_x < 8 or local_x > 40 or local_y < 8 or local_y > 56 then
                        in_text_region <= '1';
                    end if;
                end if;

                -- S character
                if px >= start_x + 2*(char_width + char_gap) and px < start_x + 3*char_width + 2*char_gap then
                    local_x := px - (start_x + 2*(char_width + char_gap));
                    -- S pattern: top bar, left top half, middle bar, right bottom half, bottom bar
                    if local_y < 8 or local_y > 56 or (local_y >= 28 and local_y <= 36) then
                        in_text_region <= '1';  -- Horizontal bars
                    elsif local_y < 32 and local_x < 8 then
                        in_text_region <= '1';  -- Left top
                    elsif local_y > 32 and local_x > 40 then
                        in_text_region <= '1';  -- Right bottom
                    end if;
                end if;

                -- E character
                if px >= start_x + 3*(char_width + char_gap) and px < start_x + 4*char_width + 3*char_gap then
                    local_x := px - (start_x + 3*(char_width + char_gap));
                    -- E pattern: left vertical, three horizontal bars
                    if local_x < 8 then
                        in_text_region <= '1';
                    elsif local_y < 8 or local_y > 56 or (local_y >= 28 and local_y <= 36) then
                        in_text_region <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- RGB output generation
    process(state, video_on, flash_state, random_result, in_text_region)
    begin
        rgb_out <= (others => '0');

        if video_on = '1' then
            case state is
                when FLASHING =>
                    -- Flash between red and black
                    if flash_state = '0' then
                        rgb_out <= "111100000000";  -- Red
                    else
                        rgb_out <= "000000000000";  -- Black
                    end if;

                when SHOW_RESULT =>
                    -- Show the random result
                    if random_result = '0' then
                        rgb_out <= "111100000000";  -- Red
                    else
                        rgb_out <= "000000000000";  -- Black
                    end if;

                when DISPLAY_WIN =>
                    -- Show WIN text on top of the random result color
                    if in_text_region = '1' then
                        rgb_out <= "111111111111";  -- White text
                    else
                        -- Background is the random result color
                        if random_result = '0' then
                            rgb_out <= "111100000000";  -- Red background
                        else
                            rgb_out <= "000000000000";  -- Black background
                        end if;
                    end if;

                when DISPLAY_LOSE =>
                    -- Show LOSE text on top of the random result color
                    if in_text_region = '1' then
                        rgb_out <= "111111111111";  -- White text
                    else
                        -- Background is the random result color
                        if random_result = '0' then
                            rgb_out <= "111100000000";  -- Red background
                        else
                            rgb_out <= "000000000000";  -- Black background
                        end if;
                    end if;

                when others =>
                    rgb_out <= (others => '0');
            end case;
        end if;
    end process;

    -- Output assignments
    double_active <= '1' when state /= IDLE and state /= DOUBLE_AVAILABLE else '0';
    double_rgb <= rgb_out;
    block_spin <= '1' when state /= IDLE else '0';

end Behavioral;
