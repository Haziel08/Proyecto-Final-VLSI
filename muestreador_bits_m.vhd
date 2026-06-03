-- Modulo: Muestreador de Bits
-- Toma una muestra en el centro de cada simbolo optico.

library IEEE;
-- Importa la librería IEEE estándar.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para los tipos lógicos.

entity muestreador_bits_m is
-- Entidad del muestreador de bits ópticos.
    port (
        clk_50mhz  : in  STD_LOGIC;
        -- Reloj de 50 MHz para la lógica de muestreo.
        reset_n    : in  STD_LOGIC;
        -- Reset asíncrono activo en bajo.
        sensor     : in  STD_LOGIC;
        -- Señal del sensor óptico filtrada y sincronizada.
        bit_rx     : out STD_LOGIC;
        -- Bit recibido muestreado en el centro del símbolo.
        bit_valido : out STD_LOGIC
        -- Indica cuándo el bit muestreado es válido.
    );
end entity;

architecture Behavioral of muestreador_bits_m is
-- Arquitectura comportamental del muestreador.

    -- BIT_DURATION = 180 ms en HTML.
    -- 50 MHz * 0.180 s = 9,000,000 ciclos.
    constant BIT_TICKS : integer := 9000000;
    -- Número de ciclos de reloj correspondientes a la duración de un bit.

    type estado_muestreo_t is (ESPERA_INICIO, RECIBIENDO);
    -- Define estados del muestreador: espera al inicio o recibiendo bits.
    signal estado : estado_muestreo_t := ESPERA_INICIO;
    -- Estado actual del muestreador, inicializado en espera.

    signal sensor_ant : STD_LOGIC := '0';
    -- Guarda la lectura anterior del sensor para detectar bordes.
    signal contador   : integer range 0 to BIT_TICKS := 0;
    -- Contador de ciclos para temporizar el muestreo.
    signal bit_reg    : STD_LOGIC := '0';
    -- Registro que almacena el bit muestreado.
    signal valido_reg : STD_LOGIC := '0';
    -- Registro que indica cuando el bit está disponible.

begin

    process(clk_50mhz, reset_n)
    -- Proceso síncrono con reset asíncrono.
    begin
        if reset_n = '0' then
            -- Acción de reset: volver a valores iniciales.
            estado     <= ESPERA_INICIO;
            sensor_ant <= '0';
            contador   <= 0;
            bit_reg    <= '0';
            valido_reg <= '0';

        elsif rising_edge(clk_50mhz) then
            -- En cada flanco de subida del reloj.
            valido_reg <= '0';
            -- Borra la bandera de bit válido cada ciclo.
            sensor_ant <= sensor;
            -- Actualiza el valor anterior del sensor.

            case estado is

                when ESPERA_INICIO =>
                    contador <= 0;
                    -- Reinicia el contador mientras espera el inicio.

                    -- El preambulo empieza con 1.
                    -- Por eso se arranca con el primer flanco de luz.
                    if sensor_ant = '0' and sensor = '1' then
                        -- Detecta el flanco de subida del símbolo inicial.
                        estado <= RECIBIENDO;
                        -- Cambia al estado de recepción de bits.
                        contador <= BIT_TICKS / 2;
                        -- Ajusta para muestrear en el centro del siguiente bit.
                    end if;

                when RECIBIENDO =>
                    if contador = BIT_TICKS - 1 then
                        -- Cuando llega el final de un bit.
                        contador   <= 0;
                        -- Reinicia el contador para el siguiente bit.
                        bit_reg    <= sensor;
                        -- Captura el valor del sensor en el centro del bit.
                        valido_reg <= '1';
                        -- Marca el bit como válido para el receptor.
                    else
                        contador <= contador + 1;
                        -- Incrementa el temporizador.
                    end if;

            end case;
        end if;
    end process;

    bit_rx     <= bit_reg;
    -- Salida del bit muestreado.
    bit_valido <= valido_reg;
    -- Salida que indica bit válido.

end Behavioral;
-- Fin de la arquitectura comportamental del muestreador de bits.
