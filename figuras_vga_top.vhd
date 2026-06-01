-- Entidad de Nivel Superior
-- Proyecto: Comunicacion optica desde interfaz movil hacia FPGA para figuras en VGA.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.componentes_figuras_pkg.all;

entity figuras_vga_top is
    port (
        MAX10_CLK1_50 : in  STD_LOGIC;
        KEY           : in  STD_LOGIC_VECTOR(1 downto 0);

        -- Entrada desde fototransistor por GPIO.
        SENSOR_IN     : in  STD_LOGIC;

        VGA_HS        : out STD_LOGIC;
        VGA_VS        : out STD_LOGIC;
        VGA_R         : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G         : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B         : out STD_LOGIC_VECTOR(3 downto 0);

        -- LEDs de depuracion.
        LEDR          : out STD_LOGIC_VECTOR(9 downto 0)
    );
end entity;

architecture Structural of figuras_vga_top is

    -- Relojes y VGA.
    signal clk_25mhz, pulso_10ms : STD_LOGIC;
    signal vga_visible           : STD_LOGIC;
    signal x_pos, y_pos          : integer;

    -- Sensor optico.
    signal sensor_normalizado : STD_LOGIC;
    signal sensor_sync        : STD_LOGIC;
    signal sensor_filtrado    : STD_LOGIC;

    -- Comunicacion.
    signal bit_rx       : STD_LOGIC;
    signal bit_valido   : STD_LOGIC;
    signal trama_valida : STD_LOGIC;

    -- Datos recibidos.
    signal cmd_rx     : STD_LOGIC;
    signal pos_rx     : STD_LOGIC_VECTOR(3 downto 0);
    signal fig_rx     : STD_LOGIC_VECTOR(1 downto 0);
    signal filete_rx  : STD_LOGIC_VECTOR(1 downto 0);
    signal relleno_rx : STD_LOGIC_VECTOR(1 downto 0);

    -- Registros graficos.
    signal figura_visible : STD_LOGIC;
    signal pos_fig        : STD_LOGIC_VECTOR(3 downto 0);
    signal tipo_fig       : STD_LOGIC_VECTOR(1 downto 0);
    signal color_filete   : STD_LOGIC_VECTOR(1 downto 0);
    signal color_relleno  : STD_LOGIC_VECTOR(1 downto 0);

begin

    -- Con pull-up tipico:
    -- luz fuerte -> SENSOR_IN puede ser 0
    -- oscuridad  -> SENSOR_IN puede ser 1
    --
    -- Por eso se invierte para que internamente:
    -- luz = 1
    -- oscuridad = 0
    --
    -- Si en tu circuito luz ya da 1, cambia esta linea por:
    -- sensor_normalizado <= SENSOR_IN;
    sensor_normalizado <= not SENSOR_IN;

    U_RELOJES: relojes_m
        port map (
            clk_50mhz  => MAX10_CLK1_50,
            clk_vga    => clk_25mhz,
            pulso_10ms => pulso_10ms
        );

    U_SENSOR_SYNC: sensor_sync_m
        port map (
            clk_50mhz  => MAX10_CLK1_50,
            reset_n    => KEY(0),
            sensor_in  => sensor_normalizado,
            sensor_out => sensor_sync
        );

    U_SENSOR_FILTER: sensor_filter_m
        port map (
            clk_50mhz => MAX10_CLK1_50,
            reset_n   => KEY(0),
            entrada   => sensor_sync,
            salida    => sensor_filtrado
        );

    U_MUESTREADOR: muestreador_bits_m
        port map (
            clk_50mhz  => MAX10_CLK1_50,
            reset_n    => KEY(0),
            sensor     => sensor_filtrado,
            bit_rx     => bit_rx,
            bit_valido => bit_valido
        );

    U_RECEPTOR: receptor_trama_m
        port map (
            clk_50mhz    => MAX10_CLK1_50,
            reset_n      => KEY(0),
            bit_rx       => bit_rx,
            bit_valido   => bit_valido,
            trama_valida => trama_valida,
            cmd          => cmd_rx,
            posicion     => pos_rx,
            figura       => fig_rx,
            filete       => filete_rx,
            relleno      => relleno_rx
        );

    U_CONTROL_FIGURA: control_figura_m
        port map (
            clk_50mhz      => MAX10_CLK1_50,
            reset_n        => KEY(0),
            trama_valida   => trama_valida,
            cmd            => cmd_rx,
            posicion_in    => pos_rx,
            figura_in      => fig_rx,
            filete_in      => filete_rx,
            relleno_in     => relleno_rx,
            figura_visible => figura_visible,
            posicion_out   => pos_fig,
            figura_out     => tipo_fig,
            filete_out     => color_filete,
            relleno_out    => color_relleno
        );

    U_SINCRONIA: sincronia_vga_m
        port map (
            clk_vga => clk_25mhz,
            vga_hs  => VGA_HS,
            vga_vs  => VGA_VS,
            visible => vga_visible,
            pixel_x => x_pos,
            pixel_y => y_pos
        );

    U_GRAFICOS: generador_vga_figuras_m
        port map (
            visible        => vga_visible,
            pixel_x        => x_pos,
            pixel_y        => y_pos,
            figura_visible => figura_visible,
            posicion       => pos_fig,
            figura         => tipo_fig,
            color_filete   => color_filete,
            color_relleno  => color_relleno,
            vga_r          => VGA_R,
            vga_g          => VGA_G,
            vga_b          => VGA_B
        );

    -- LEDs de depuracion por bloques.
    LEDR(0) <= SENSOR_IN;
    LEDR(1) <= sensor_normalizado;
    LEDR(2) <= sensor_filtrado;
    LEDR(3) <= bit_rx;
    LEDR(4) <= bit_valido;
    LEDR(5) <= trama_valida;
    LEDR(6) <= figura_visible;
    LEDR(7) <= cmd_rx;
    LEDR(9 downto 8) <= tipo_fig;

end Structural;