-- Modulo: Control Principal de Figura
-- Guarda los datos validos recibidos y ejecuta el comando de borrado.

library IEEE;
-- Importa la biblioteca IEEE con tipos estándar.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para los tipos lógicos.

entity control_figura_m is
-- Declara la entidad del módulo de control de figura.
    port (
        clk_50mhz      : in  STD_LOGIC;
        -- Reloj de 50 MHz para sincronizar la lógica.
        reset_n        : in  STD_LOGIC;
        -- Señal de reset activo en bajo (reset asíncrono).
        trama_valida   : in  STD_LOGIC;
        -- Indica que se recibió una trama completa y válida.
        cmd            : in  STD_LOGIC;
        -- Comando recibido: '0' para dibujar, '1' para borrar.

        posicion_in    : in  STD_LOGIC_VECTOR(3 downto 0);
        -- Posición de la figura en la matriz 3x3 codificada en 4 bits.
        figura_in      : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Tipo de figura recibida codificado en 2 bits.
        filete_in      : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Color de contorno recibido codificado en 2 bits.
        relleno_in     : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Color de relleno recibido codificado en 2 bits.

        figura_visible : out STD_LOGIC;
        -- Indica si la figura debe mostrarse en pantalla.
        posicion_out   : out STD_LOGIC_VECTOR(3 downto 0);
        -- Posición actual de la figura hacia el generador VGA.
        figura_out     : out STD_LOGIC_VECTOR(1 downto 0);
        -- Tipo de figura hacia el generador VGA.
        filete_out     : out STD_LOGIC_VECTOR(1 downto 0);
        -- Color de contorno hacia el generador VGA.
        relleno_out    : out STD_LOGIC_VECTOR(1 downto 0)
        -- Color de relleno hacia el generador VGA.
    );
end entity;

architecture Behavioral of control_figura_m is
-- Arquitectura comportamental del módulo de control de figura.

    signal visible_reg : STD_LOGIC := '0';
    -- Registro interno que guarda si la figura está visible.
    signal pos_reg     : STD_LOGIC_VECTOR(3 downto 0) := "0100";
    -- Registro interno de posición inicial (centro por defecto).
    signal fig_reg     : STD_LOGIC_VECTOR(1 downto 0) := "00";
    -- Registro interno del tipo de figura inicial.
    signal fil_reg     : STD_LOGIC_VECTOR(1 downto 0) := "01";
    -- Registro interno del color de contorno inicial.
    signal rel_reg     : STD_LOGIC_VECTOR(1 downto 0) := "10";
    -- Registro interno del color de relleno inicial.

begin

    process(clk_50mhz, reset_n)
    -- Proceso secuencial que responde a reset asíncrono y flancos de reloj.
    begin
        if reset_n = '0' then
            -- Si reset está activo, reiniciar todos los registros a valores iniciales.
            visible_reg <= '0';
            -- Desactiva la visibilidad de la figura.
            pos_reg     <= "0100";
            -- Posición predeterminada: centro.
            fig_reg     <= "00";
            -- Figura predeterminada: valor neutro.
            fil_reg     <= "01";
            -- Color de filete predeterminado.
            rel_reg     <= "10";
            -- Color de relleno predeterminado.

        elsif rising_edge(clk_50mhz) then
            -- En el flanco de subida del reloj, evaluar señales de entrada.
            if trama_valida = '1' then
                -- Solo actualizar cuando llega una trama válida.

                if cmd = '1' then
                    -- Comando borrar / limpiar VGA.
                    visible_reg <= '0';
                    -- Desactiva la visualización de la figura.

                else
                    -- Comando dibujar.
                    visible_reg <= '1';
                    -- Activa la visualización de la figura.
                    pos_reg     <= posicion_in;
                    -- Actualiza la posición con los datos recibidos.
                    fig_reg     <= figura_in;
                    -- Actualiza el tipo de figura con los datos recibidos.
                    fil_reg     <= filete_in;
                    -- Actualiza el color del contorno con los datos recibidos.
                    rel_reg     <= relleno_in;
                    -- Actualiza el color de relleno con los datos recibidos.
                end if;

            end if;
        end if;
    end process;

    figura_visible <= visible_reg;
    -- Asigna la señal de visibilidad a la salida.
    posicion_out   <= pos_reg;
    -- Asigna la posición actual a la salida.
    figura_out     <= fig_reg;
    -- Asigna el tipo de figura actual a la salida.
    filete_out     <= fil_reg;
    -- Asigna el color de filete actual a la salida.
    relleno_out    <= rel_reg;
    -- Asigna el color de relleno actual a la salida.

end Behavioral;
-- Fin de la arquitectura comportamental del módulo de control de figura.
