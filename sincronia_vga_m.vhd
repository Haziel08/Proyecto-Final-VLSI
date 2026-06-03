-- Modulo: Generador de Sincronia VGA 640x480
-- Genera HS, VS y señales de visibilidad para la pantalla VGA standard.

library IEEE;
-- Importa la libreria estandar IEEE.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para tipos logicos.

entity sincronia_vga_m is
-- Entidad del generador de sincronía VGA.
    port (
        clk_vga : in  STD_LOGIC;
        -- Reloj de 25 MHz para VGA.
        vga_hs  : out STD_LOGIC;
        -- Señal de sincronización horizontal VGA.
        vga_vs  : out STD_LOGIC;
        -- Señal de sincronización vertical VGA.
        visible : out STD_LOGIC;
        -- Señal que indica si el pixel actual está en el área visible.
        pixel_x : out integer;
        -- Coordenada X del pixel actual.
        pixel_y : out integer
        -- Coordenada Y del pixel actual.
    );
end entity;

architecture Behavioral of sincronia_vga_m is
-- Arquitectura comportamental que implementa el temporizador VGA.

    constant H_VISIBLE : integer := 640;
    -- Ancho visible de la pantalla en píxeles.
    constant H_FP      : integer := 16;
    -- Front porch horizontal en píxeles.
    constant H_SYNC    : integer := 96;
    -- Ancho del pulso de sincronización horizontal.
    constant H_BP      : integer := 48;
    -- Back porch horizontal en píxeles.
    constant H_TOTAL   : integer := 800;
    -- Total de píxeles por línea (visible + front porch + sync + back porch).

    constant V_VISIBLE : integer := 480;
    -- Alto visible de la pantalla en líneas.
    constant V_FP      : integer := 10;
    -- Front porch vertical en líneas.
    constant V_SYNC    : integer := 2;
    -- Altura del pulso de sincronización vertical.
    constant V_BP      : integer := 33;
    -- Back porch vertical en líneas.
    constant V_TOTAL   : integer := 525;
    -- Total de líneas por cuadro (visible + front porch + sync + back porch).

    signal h_cnt : integer range 0 to H_TOTAL - 1 := 0;
    -- Contador horizontal actual.
    signal v_cnt : integer range 0 to V_TOTAL - 1 := 0;
    -- Contador vertical actual.

begin

    process(clk_vga)
    -- Proceso síncrono que avanza los contadores VGA en cada flanco de reloj.
    begin
        if rising_edge(clk_vga) then
            if h_cnt = H_TOTAL - 1 then
                -- Si se llega al final de la línea VGA.
                h_cnt <= 0;
                -- Reinicia el contador horizontal.

                if v_cnt = V_TOTAL - 1 then
                    -- Si se llega al final del cuadro VGA.
                    v_cnt <= 0;
                    -- Reinicia el contador vertical.
                else
                    v_cnt <= v_cnt + 1;
                    -- Avanza una línea vertical.
                end if;

            else
                h_cnt <= h_cnt + 1;
                -- Avanza el contador horizontal en la línea actual.
            end if;
        end if;
    end process;

    vga_hs <= '0' when
        h_cnt >= H_VISIBLE + H_FP and
        h_cnt <  H_VISIBLE + H_FP + H_SYNC
        else '1';
    -- Genera el pulso activo bajo HS durante el periodo de sincronización horizontal.

    vga_vs <= '0' when
        v_cnt >= V_VISIBLE + V_FP and
        v_cnt <  V_VISIBLE + V_FP + V_SYNC
        else '1';
    -- Genera el pulso activo bajo VS durante el periodo de sincronización vertical.

    visible <= '1' when h_cnt < H_VISIBLE and v_cnt < V_VISIBLE else '0';
    -- Señal visible alta solo durante la región visible de la pantalla.

    pixel_x <= h_cnt;
    -- Asigna la coordenada X del píxel actual.
    pixel_y <= v_cnt;
    -- Asigna la coordenada Y del píxel actual.

end Behavioral;
-- Fin de la arquitectura comportamental del generador de sincronía VGA.
