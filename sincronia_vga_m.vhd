-- Modulo: Generador de Sincronia VGA 640x480

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sincronia_vga_m is
    port (
        clk_vga : in  STD_LOGIC;
        vga_hs  : out STD_LOGIC;
        vga_vs  : out STD_LOGIC;
        visible : out STD_LOGIC;
        pixel_x : out integer;
        pixel_y : out integer
    );
end entity;

architecture Behavioral of sincronia_vga_m is

    constant H_VISIBLE : integer := 640;
    constant H_FP      : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BP      : integer := 48;
    constant H_TOTAL   : integer := 800;

    constant V_VISIBLE : integer := 480;
    constant V_FP      : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BP      : integer := 33;
    constant V_TOTAL   : integer := 525;

    signal h_cnt : integer range 0 to H_TOTAL - 1 := 0;
    signal v_cnt : integer range 0 to V_TOTAL - 1 := 0;

begin

    process(clk_vga)
    begin
        if rising_edge(clk_vga) then
            if h_cnt = H_TOTAL - 1 then
                h_cnt <= 0;

                if v_cnt = V_TOTAL - 1 then
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
                end if;

            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;

    vga_hs <= '0' when
        h_cnt >= H_VISIBLE + H_FP and
        h_cnt <  H_VISIBLE + H_FP + H_SYNC
        else '1';

    vga_vs <= '0' when
        v_cnt >= V_VISIBLE + V_FP and
        v_cnt <  V_VISIBLE + V_FP + V_SYNC
        else '1';

    visible <= '1' when h_cnt < H_VISIBLE and v_cnt < V_VISIBLE else '0';

    pixel_x <= h_cnt;
    pixel_y <= v_cnt;

end Behavioral;