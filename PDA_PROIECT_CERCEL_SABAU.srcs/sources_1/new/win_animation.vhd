-- Win animation controller: flashes winning rows for 3 seconds
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity win_animation is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        spin_done  : in  STD_LOGIC;
        win_rows   : in  STD_LOGIC_VECTOR(2 downto 0);
        animating  : out STD_LOGIC;   -- High while animation is running
        flash_on   : out STD_LOGIC;   -- Toggles at 250ms intervals
        active_rows: out STD_LOGIC_VECTOR(2 downto 0)  -- Which rows to highlight
    );
end win_animation;

architecture Behavioral of win_animation is
    -- 100 MHz clock: 250ms = 25,000,000 cycles, 3s = 300,000,000 cycles
    constant FLASH_PERIOD : integer := 25000000;  -- 250ms at 100MHz
    constant TOTAL_DURATION : integer := 300000000;  -- 3 seconds at 100MHz

    signal anim_active : STD_LOGIC := '0';
    signal flash_state : STD_LOGIC := '0';
    signal flash_counter : integer range 0 to FLASH_PERIOD := 0;
    signal total_counter : integer range 0 to TOTAL_DURATION := 0;
    signal stored_rows : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal spin_done_d1 : STD_LOGIC := '0';  -- Delayed spin_done by 1 clock

begin

    process(clk, reset)
    begin
        if reset = '1' then
            anim_active <= '0';
            flash_state <= '0';
            flash_counter <= 0;
            total_counter <= 0;
            stored_rows <= "000";
            spin_done_d1 <= '0';
        elsif rising_edge(clk) then
            -- Delay spin_done by 1 clock so win_rows is valid
            spin_done_d1 <= spin_done;

            if anim_active = '0' then
                -- Wait for delayed spin_done so win_rows is updated
                if spin_done_d1 = '1' and win_rows /= "000" then
                    anim_active <= '1';
                    stored_rows <= win_rows;
                    flash_state <= '1';
                    flash_counter <= 0;
                    total_counter <= 0;
                end if;
            else
                -- Animation running
                total_counter <= total_counter + 1;
                flash_counter <= flash_counter + 1;

                -- Toggle flash every 250ms
                if flash_counter = FLASH_PERIOD - 1 then
                    flash_counter <= 0;
                    flash_state <= not flash_state;
                end if;

                -- End animation after 3 seconds
                if total_counter = TOTAL_DURATION - 1 then
                    anim_active <= '0';
                    flash_state <= '0';
                    stored_rows <= "000";
                end if;
            end if;
        end if;
    end process;

    animating <= anim_active;
    flash_on <= flash_state;
    active_rows <= stored_rows;

end Behavioral;
