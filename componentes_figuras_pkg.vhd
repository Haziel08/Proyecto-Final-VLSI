-- Paquete de Componentes Modulares para Proyecto de Figuras VGA
-- Proyecto: Comunicacion optica movil -> fototransistor -> FPGA -> VGA

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package componentes_figuras_pkg is

    component relojes_m is
        port (
            clk_50mhz  : in  STD_LOGIC;
            clk_vga    : out STD_LOGIC;
            pulso_10ms : out STD_LOGIC
        );
    end component;

    component sensor_sync_m is
        port (
            clk_50mhz  : in  STD_LOGIC;
            reset_n    : in  STD_LOGIC;
            sensor_in  : in  STD_LOGIC;
            sensor_out : out STD_LOGIC
        );
    end component;

    component sensor_filter_m is
        port (
            clk_50mhz : in  STD_LOGIC;
            reset_n   : in  STD_LOGIC;
            entrada   : in  STD_LOGIC;
            salida    : out STD_LOGIC
        );
    end component;

    component muestreador_bits_m is
        port (
            clk_50mhz  : in  STD_LOGIC;
            reset_n    : in  STD_LOGIC;
            sensor     : in  STD_LOGIC;
            bit_rx     : out STD_LOGIC;
            bit_valido : out STD_LOGIC
        );
    end component;

    component receptor_trama_m is
        port (
            clk_50mhz    : in  STD_LOGIC;
            reset_n      : in  STD_LOGIC;
            bit_rx       : in  STD_LOGIC;
            bit_valido   : in  STD_LOGIC;
            trama_valida : out STD_LOGIC;
            cmd          : out STD_LOGIC;
            posicion     : out STD_LOGIC_VECTOR(3 downto 0);
            figura       : out STD_LOGIC_VECTOR(1 downto 0);
            filete       : out STD_LOGIC_VECTOR(1 downto 0);
            relleno      : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    component control_figura_m is
        port (
            clk_50mhz      : in  STD_LOGIC;
            reset_n        : in  STD_LOGIC;
            trama_valida   : in  STD_LOGIC;
            cmd            : in  STD_LOGIC;
            posicion_in    : in  STD_LOGIC_VECTOR(3 downto 0);
            figura_in      : in  STD_LOGIC_VECTOR(1 downto 0);
            filete_in      : in  STD_LOGIC_VECTOR(1 downto 0);
            relleno_in     : in  STD_LOGIC_VECTOR(1 downto 0);
            figura_visible : out STD_LOGIC;
            posicion_out   : out STD_LOGIC_VECTOR(3 downto 0);
            figura_out     : out STD_LOGIC_VECTOR(1 downto 0);
            filete_out     : out STD_LOGIC_VECTOR(1 downto 0);
            relleno_out    : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    component sincronia_vga_m is
        port (
            clk_vga : in  STD_LOGIC;
            vga_hs  : out STD_LOGIC;
            vga_vs  : out STD_LOGIC;
            visible : out STD_LOGIC;
            pixel_x : out integer;
            pixel_y : out integer
        );
    end component;

    component generador_vga_figuras_m is
        port (
            visible        : in  STD_LOGIC;
            pixel_x        : in  integer;
            pixel_y        : in  integer;
            figura_visible : in  STD_LOGIC;
            posicion       : in  STD_LOGIC_VECTOR(3 downto 0);
            figura         : in  STD_LOGIC_VECTOR(1 downto 0);
            color_filete   : in  STD_LOGIC_VECTOR(1 downto 0);
            color_relleno  : in  STD_LOGIC_VECTOR(1 downto 0);
            vga_r          : out STD_LOGIC_VECTOR(3 downto 0);
            vga_g          : out STD_LOGIC_VECTOR(3 downto 0);
            vga_b          : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

end package;