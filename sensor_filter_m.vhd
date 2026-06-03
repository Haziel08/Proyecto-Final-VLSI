-- Modulo: Filtro Digital para Sensor Optico
-- Acepta un cambio solo si la entrada permanece estable.

library IEEE;
-- Importa la libreria estandar IEEE.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para tipos logicos.

entity sensor_filter_m is
-- Entidad del filtro de sensor optico.
    port (
        clk_50mhz : in  STD_LOGIC;
        -- Reloj de 50 MHz para la logica de filtrado.
        reset_n   : in  STD_LOGIC;
        -- Reset activo en bajo para reiniciar el filtro.
        entrada   : in  STD_LOGIC;
        -- Señal de entrada del sensor optico sincronizada.
        salida    : out STD_LOGIC
        -- Señal de salida filtrada.
    );
end entity;

architecture Behavioral of sensor_filter_m is
-- Arquitectura comportamental del filtro.

    -- 50,000 ciclos a 50 MHz = 1 ms aproximadamente.
    -- Si hay ruido, subir a 100000.
    -- Si se vuelve lento, bajar a 25000.
    constant TIEMPO_ESTABLE : integer := 50000;
    -- Tiempo en ciclos que la entrada debe permanecer estable para aceptar el cambio.

    signal entrada_anterior : STD_LOGIC := '0';
    -- Guarda el valor anterior de la entrada para detectar cambios.
    signal salida_filtrada  : STD_LOGIC := '0';
    -- Registro de la salida filtrada.
    signal contador         : integer range 0 to TIEMPO_ESTABLE := 0;
    -- Contador de ciclos de estabilidad.

begin

    process(clk_50mhz, reset_n)
    -- Proceso sensitivo a reloj y reset asíncrono.
    begin
        if reset_n = '0' then
            -- Reset activo: inicializa señales a valores conocidos.
            entrada_anterior <= '0';
            salida_filtrada  <= '0';
            contador         <= 0;

        elsif rising_edge(clk_50mhz) then
            -- En el flanco de subida del reloj.
            if entrada = entrada_anterior then
                -- Si la entrada no cambió desde el ciclo anterior.
                if contador < TIEMPO_ESTABLE then
                    -- Si aun no se cumplió el tiempo de estabilidad.
                    contador <= contador + 1;
                    -- Incrementa el contador.
                else
                    salida_filtrada <= entrada;
                    -- Si ya estuvo estable suficiente tiempo, acepta el valor.
                end if;
            else
                entrada_anterior <= entrada;
                -- Si la entrada cambió, actualiza el valor anterior.
                contador <= 0;
                -- Reinicia el contador para medir la nueva estabilidad.
            end if;
        end if;
    end process;

    salida <= salida_filtrada;
    -- Asigna la señal filtrada a la salida del módulo.

end Behavioral;
-- Fin de la arquitectura comportamental del filtro de sensor optico.
