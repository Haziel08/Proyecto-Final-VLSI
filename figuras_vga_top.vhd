-- Entidad de Nivel Superior
-- Proyecto: Comunicacion optica desde interfaz movil hacia FPGA para figuras en VGA.

library IEEE;
-- Importa la librería IEEE estándar.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para tipos lógicos como STD_LOGIC.
use work.componentes_figuras_pkg.all;
-- Importa los componentes definidos en el paquete de figuras.

entity figuras_vga_top is
-- Entidad top-level que conecta todos los módulos del sistema.
    port (
        MAX10_CLK1_50 : in  STD_LOGIC;
        -- Entrada de reloj de 50 MHz desde la placa.
        KEY           : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Entradas de tecla/switch para reset y control.

        -- Entrada desde fototransistor por GPIO.
        SENSOR_IN     : in  STD_LOGIC;
        -- Señal digital del fototransistor.

        VGA_HS        : out STD_LOGIC;
        -- Salida de sincronización horizontal VGA.
        VGA_VS        : out STD_LOGIC;
        -- Salida de sincronización vertical VGA.
        VGA_R         : out STD_LOGIC_VECTOR(3 downto 0);
        -- Salida de 4 bits para el canal rojo VGA.
        VGA_G         : out STD_LOGIC_VECTOR(3 downto 0);
        -- Salida de 4 bits para el canal verde VGA.
        VGA_B         : out STD_LOGIC_VECTOR(3 downto 0);
        -- Salida de 4 bits para el canal azul VGA.

        -- LEDs de depuracion.
        LEDR          : out STD_LOGIC_VECTOR(9 downto 0)
        -- Salida para LEDs en la placa usados como indicadores.
    );
end entity;

architecture Structural of figuras_vga_top is
-- Arquitectura estructural que instancia y conecta submódulos.

    -- Relojes y señales de sincronización VGA.
    signal clk_25mhz, pulso_10ms : STD_LOGIC;
    -- clk_25mhz es el reloj VGA derivado de 50 MHz.
    -- pulso_10ms es un pulso de 10 ms usado por otros módulos.
    signal vga_visible           : STD_LOGIC;
    -- Señal que indica cuando el barrido está en el área visible.
    signal x_pos, y_pos          : integer;
    -- Coordenadas actuales del píxel VGA.

    -- Sensor optico y etapas de procesamiento.
    signal sensor_normalizado : STD_LOGIC;
    -- Señal del sensor invertida/normalizada.
    signal sensor_sync        : STD_LOGIC;
    -- Señal del sensor sincronizada con el reloj.
    signal sensor_filtrado    : STD_LOGIC;
    -- Señal del sensor filtrada para eliminar ruido.

    -- Señales de la comunicación óptica.
    signal bit_rx       : STD_LOGIC;
    -- Bit recibido tras el muestreo.
    signal bit_valido   : STD_LOGIC;
    -- Indica cuándo el bit recibido es válido.
    signal trama_valida : STD_LOGIC;
    -- Indica cuándo la trama completa es válida.

    -- Datos decodificados de la trama.
    signal cmd_rx     : STD_LOGIC;
    -- Comando recibido (dibujar/borrar).
    signal pos_rx     : STD_LOGIC_VECTOR(3 downto 0);
    -- Posición recibida de la figura.
    signal fig_rx     : STD_LOGIC_VECTOR(1 downto 0);
    -- Tipo de figura recibida.
    signal filete_rx  : STD_LOGIC_VECTOR(1 downto 0);
    -- Color de contorno recibido.
    signal relleno_rx : STD_LOGIC_VECTOR(1 downto 0);
    -- Color de relleno recibido.

    -- Registros gráficos para el generador VGA.
    signal figura_visible : STD_LOGIC;
    -- Indica si la figura debe mostrarse en pantalla.
    signal pos_fig        : STD_LOGIC_VECTOR(3 downto 0);
    -- Posición actual de la figura para el generador VGA.
    signal tipo_fig       : STD_LOGIC_VECTOR(1 downto 0);
    -- Tipo de figura actual para el generador VGA.
    signal color_filete   : STD_LOGIC_VECTOR(1 downto 0);
    -- Color de contorno actual para el generador VGA.
    signal color_relleno  : STD_LOGIC_VECTOR(1 downto 0);
    -- Color de relleno actual para el generador VGA.

begin

    -- Normaliza la señal del sensor óptico.
    -- Con pull-up típico: luz fuerte produce 0 y oscuridad produce 1.
    -- Se invierte aquí para que internamente luz = 1 y oscuridad = 0.
    -- Si tu circuito ya entrega luz = 1, usar sensor_normalizado <= SENSOR_IN.
    sensor_normalizado <= not SENSOR_IN;

    U_RELOJES: relojes_m
    -- Instancia del módulo generador de relojes.
        port map (
            clk_50mhz  => MAX10_CLK1_50,
            -- Conecta reloj 50 MHz externo.
            clk_vga    => clk_25mhz,
            -- Salida de reloj VGA de 25 MHz.
            pulso_10ms => pulso_10ms
            -- Salida de pulso de 10 ms para sincronización.
        );

    U_SENSOR_SYNC: sensor_sync_m
    -- Instancia del módulo que sincroniza la entrada del sensor.
        port map (
            clk_50mhz  => MAX10_CLK1_50,
            -- Reloj de 50 MHz para sincronización.
            reset_n    => KEY(0),
            -- Reset activo en bajo desde la tecla KEY(0).
            sensor_in  => sensor_normalizado,
            -- Señal normalizada del sensor.
            sensor_out => sensor_sync
            -- Salida sincronizada del sensor.
        );

    U_SENSOR_FILTER: sensor_filter_m
    -- Instancia del filtro que suaviza la señal del sensor.
        port map (
            clk_50mhz => MAX10_CLK1_50,
            -- Reloj de 50 MHz para el filtro.
            reset_n   => KEY(0),
            -- Reset activo en bajo para el filtro.
            entrada   => sensor_sync,
            -- Entrada sincronizada del sensor.
            salida    => sensor_filtrado
            -- Señal filtrada libre de ruido.
        );

    U_MUESTREADOR: muestreador_bits_m
    -- Instancia del muestreador que convierte la señal en bits.
        port map (
            clk_50mhz  => MAX10_CLK1_50,
            -- Reloj para el muestreo de bits.
            reset_n    => KEY(0),
            -- Reset activo en bajo.
            sensor     => sensor_filtrado,
            -- Señal filtrada proveniente del sensor.
            bit_rx     => bit_rx,
            -- Bit recibido muestreado.
            bit_valido => bit_valido
            -- Indica bit válido.
        );

    U_RECEPTOR: receptor_trama_m
    -- Instancia del receptor de tramas que decodifica la comunicación.
        port map (
            clk_50mhz    => MAX10_CLK1_50,
            -- Reloj de procesamiento del receptor.
            reset_n      => KEY(0),
            -- Reset activo en bajo para el receptor.
            bit_rx       => bit_rx,
            -- Bit muestreado por el muestreador.
            bit_valido   => bit_valido,
            -- Señal que indica bit válido.
            trama_valida => trama_valida,
            -- Salida que indica trama válida.
            cmd          => cmd_rx,
            -- Comando decodificado de la trama.
            posicion     => pos_rx,
            -- Posición decodificada de la figura.
            figura       => fig_rx,
            -- Tipo de figura decodificado.
            filete       => filete_rx,
            -- Color de contorno decodificado.
            relleno      => relleno_rx
            -- Color de relleno decodificado.
        );

    U_CONTROL_FIGURA: control_figura_m
    -- Instancia del controlador que guarda y aplica datos de la figura.
        port map (
            clk_50mhz      => MAX10_CLK1_50,
            -- Reloj de control de figura.
            reset_n        => KEY(0),
            -- Reset activo en bajo.
            trama_valida   => trama_valida,
            -- Traza válida para actualizar registros.
            cmd            => cmd_rx,
            -- Comando recibido.
            posicion_in    => pos_rx,
            -- Posición de figura recibida.
            figura_in      => fig_rx,
            -- Tipo de figura recibida.
            filete_in      => filete_rx,
            -- Color de contorno recibido.
            relleno_in     => relleno_rx,
            -- Color de relleno recibido.
            figura_visible => figura_visible,
            -- Señal de visibilidad hacia el generador VGA.
            posicion_out   => pos_fig,
            -- Posición actual de figura.
            figura_out     => tipo_fig,
            -- Tipo de figura actual.
            filete_out     => color_filete,
            -- Color de contorno actual.
            relleno_out    => color_relleno
            -- Color de relleno actual.
        );

    U_SINCRONIA: sincronia_vga_m
    -- Instancia del módulo de sincronización VGA.
        port map (
            clk_vga => clk_25mhz,
            -- Reloj de 25 MHz para la generación de VGA.
            vga_hs  => VGA_HS,
            -- Salida de sincronización horizontal VGA.
            vga_vs  => VGA_VS,
            -- Salida de sincronización vertical VGA.
            visible => vga_visible,
            -- Señal que indica área visible.
            pixel_x => x_pos,
            -- Coordenada X del píxel actual.
            pixel_y => y_pos
            -- Coordenada Y del píxel actual.
        );

    U_GRAFICOS: generador_vga_figuras_m
    -- Instancia del generador gráfico que dibuja la figura en VGA.
        port map (
            visible        => vga_visible,
            -- Indica si el píxel está en el área visible.
            pixel_x        => x_pos,
            -- Coordenada X actual para el cálculo gráfico.
            pixel_y        => y_pos,
            -- Coordenada Y actual para el cálculo gráfico.
            figura_visible => figura_visible,
            -- Indica si se debe dibujar la figura.
            posicion       => pos_fig,
            -- Posición de la figura en la cuadrícula.
            figura         => tipo_fig,
            -- Tipo de figura a dibujar.
            color_filete   => color_filete,
            -- Color de contorno seleccionado.
            color_relleno  => color_relleno,
            -- Color de relleno seleccionado.
            vga_r          => VGA_R,
            -- Salida roja al conector VGA.
            vga_g          => VGA_G,
            -- Salida verde al conector VGA.
            vga_b          => VGA_B
            -- Salida azul al conector VGA.
        );

    -- LEDs de depuracion por bloques.
    LEDR(0) <= SENSOR_IN;
    -- Muestra la señal bruta del sensor.
    LEDR(1) <= sensor_normalizado;
    -- Muestra la señal del sensor normalizada.
    LEDR(2) <= sensor_filtrado;
    -- Muestra la señal tras el filtro.
    LEDR(3) <= bit_rx;
    -- Muestra el bit recibido.
    LEDR(4) <= bit_valido;
    -- Muestra si el bit es válido.
    LEDR(5) <= trama_valida;
    -- Muestra si la trama completa es válida.
    LEDR(6) <= figura_visible;
    -- Muestra si la figura está activa para dibujar.
    LEDR(7) <= cmd_rx;
    -- Muestra el comando recibido (0 dibujar, 1 borrar).
    LEDR(9 downto 8) <= tipo_fig;
    -- Muestra el tipo de figura recibido en dos LEDs.

end Structural;
-- Fin de la arquitectura estructural del top-level.
