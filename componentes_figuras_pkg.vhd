-- Paquete de Componentes Modulares para Proyecto de Figuras VGA
-- Proyecto: Comunicacion optica movil -> fototransistor -> FPGA -> VGA

library IEEE;
-- Importa la biblioteca estándar IEEE necesaria para tipos lógicos.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 que define STD_LOGIC y STD_LOGIC_VECTOR.

package componentes_figuras_pkg is
-- Define un paquete VHDL que declara componentes reutilizables.

    component relojes_m is
    -- Componente que genera relojes y pulsos de tiempo.
        port (
            clk_50mhz  : in  STD_LOGIC;
            -- Entrada de reloj principal de 50 MHz.
            clk_vga    : out STD_LOGIC;
            -- Salida de reloj para el sincronizador VGA.
            pulso_10ms : out STD_LOGIC
            -- Salida de pulso de 10 ms para temporización.
        );
    end component;

    component sensor_sync_m is
    -- Componente que sincroniza la señal del sensor óptico.
        port (
            clk_50mhz  : in  STD_LOGIC;
            -- Reloj de 50 MHz para el muestreo interno.
            reset_n    : in  STD_LOGIC;
            -- Señal de reset activo en bajo.
            sensor_in  : in  STD_LOGIC;
            -- Entrada de la señal cruda del fototransistor.
            sensor_out : out STD_LOGIC
            -- Salida de la señal sincronizada.
        );
    end component;

    component sensor_filter_m is
    -- Componente que filtra el ruido de la señal sincronizada.
        port (
            clk_50mhz : in  STD_LOGIC;
            -- Reloj de 50 MHz usado para el filtrado.
            reset_n   : in  STD_LOGIC;
            -- Reset activo en bajo para reiniciar el filtro.
            entrada   : in  STD_LOGIC;
            -- Entrada de la señal sincronizada a filtrar.
            salida    : out STD_LOGIC
            -- Salida de la señal filtrada.
        );
    end component;

    component muestreador_bits_m is
    -- Componente que muestrea los bits de la trama óptica.
        port (
            clk_50mhz  : in  STD_LOGIC;
            -- Reloj principal de 50 MHz para el muestreo.
            reset_n    : in  STD_LOGIC;
            -- Reset activo en bajo para reiniciar el muestreador.
            sensor     : in  STD_LOGIC;
            -- Señal de sensor filtrada a muestrear.
            bit_rx     : out STD_LOGIC;
            -- Bit recibido muestreado.
            bit_valido : out STD_LOGIC
            -- Indica cuándo el bit recibido es válido.
        );
    end component;

    component receptor_trama_m is
    -- Componente que recibe y decodifica la trama completa.
        port (
            clk_50mhz    : in  STD_LOGIC;
            -- Reloj de 50 MHz para procesar la trama.
            reset_n      : in  STD_LOGIC;
            -- Reset activo en bajo para reiniciar el receptor.
            bit_rx       : in  STD_LOGIC;
            -- Entrada del bit recibido desde el muestreador.
            bit_valido   : in  STD_LOGIC;
            -- Entrada que indica cuando el bit es válido.
            trama_valida : out STD_LOGIC;
            -- Salida que indica que se recibió una trama válida.
            cmd          : out STD_LOGIC;
            -- Salida del comando decodificado (dibujar o borrar).
            posicion     : out STD_LOGIC_VECTOR(3 downto 0);
            -- Salida de posición decodificada en 4 bits.
            figura       : out STD_LOGIC_VECTOR(1 downto 0);
            -- Salida del tipo de figura en 2 bits.
            filete       : out STD_LOGIC_VECTOR(1 downto 0);
            -- Salida del color del contorno en 2 bits.
            relleno      : out STD_LOGIC_VECTOR(1 downto 0)
            -- Salida del color de relleno en 2 bits.
        );
    end component;

    component control_figura_m is
    -- Componente que controla la visibilidad y parámetros de la figura.
        port (
            clk_50mhz      : in  STD_LOGIC;
            -- Reloj de 50 MHz para la lógica de control.
            reset_n        : in  STD_LOGIC;
            -- Reset activo en bajo para reiniciar el control.
            trama_valida   : in  STD_LOGIC;
            -- Entrada que indica que la trama está lista para usar.
            cmd            : in  STD_LOGIC;
            -- Entrada del comando dibujar/borrar.
            posicion_in    : in  STD_LOGIC_VECTOR(3 downto 0);
            -- Posición de figura recibida desde el receptor.
            figura_in      : in  STD_LOGIC_VECTOR(1 downto 0);
            -- Tipo de figura recibida desde el receptor.
            filete_in      : in  STD_LOGIC_VECTOR(1 downto 0);
            -- Color de contorno recibido desde el receptor.
            relleno_in     : in  STD_LOGIC_VECTOR(1 downto 0);
            -- Color de relleno recibido desde el receptor.
            figura_visible : out STD_LOGIC;
            -- Señal que habilita la visualización de la figura.
            posicion_out   : out STD_LOGIC_VECTOR(3 downto 0);
            -- Posición de figura para el generador VGA.
            figura_out     : out STD_LOGIC_VECTOR(1 downto 0);
            -- Tipo de figura para el generador VGA.
            filete_out     : out STD_LOGIC_VECTOR(1 downto 0);
            -- Color de contorno para el generador VGA.
            relleno_out    : out STD_LOGIC_VECTOR(1 downto 0)
            -- Color de relleno para el generador VGA.
        );
    end component;

    component sincronia_vga_m is
    -- Componente que genera señales de sincronización VGA.
        port (
            clk_vga : in  STD_LOGIC;
            -- Reloj VGA utilizado para avanzar el barrido.
            vga_hs  : out STD_LOGIC;
            -- Señal horizontal de sincronización VGA.
            vga_vs  : out STD_LOGIC;
            -- Señal vertical de sincronización VGA.
            visible : out STD_LOGIC;
            -- Indica cuándo la posición actual está en el área visible.
            pixel_x : out integer;
            -- Coordenada X del píxel actual.
            pixel_y : out integer
            -- Coordenada Y del píxel actual.
        );
    end component;

    component generador_vga_figuras_m is
    -- Componente que genera los valores RGB para dibujar la figura.
        port (
            visible        : in  STD_LOGIC;
            -- Señal que indica visibilidad de la pantalla.
            pixel_x        : in  integer;
            -- Coordenada X actual para el cálculo de la figura.
            pixel_y        : in  integer;
            -- Coordenada Y actual para el cálculo de la figura.
            figura_visible : in  STD_LOGIC;
            -- Indica si la figura debe mostrarse en la pantalla.
            posicion       : in  STD_LOGIC_VECTOR(3 downto 0);
            -- Posición de la figura dentro de la matriz 3x3.
            figura         : in  STD_LOGIC_VECTOR(1 downto 0);
            -- Tipo de figura a dibujar.
            color_filete   : in  STD_LOGIC_VECTOR(1 downto 0);
            -- Color del contorno seleccionado.
            color_relleno  : in  STD_LOGIC_VECTOR(1 downto 0);
            -- Color de relleno seleccionado.
            vga_r          : out STD_LOGIC_VECTOR(3 downto 0);
            -- Salida de intensidad roja para VGA.
            vga_g          : out STD_LOGIC_VECTOR(3 downto 0);
            -- Salida de intensidad verde para VGA.
            vga_b          : out STD_LOGIC_VECTOR(3 downto 0)
            -- Salida de intensidad azul para VGA.
        );
    end component;

end package;
-- Fin del paquete de componentes para el diseño de figuras VGA.