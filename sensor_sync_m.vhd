-- Modulo: Sincronizador de Entrada del Sensor Optico
-- Evita meter una entrada asincrona directamente a la maquina de estados.

library IEEE;
-- Importa la libreria IEEE estandar.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para tipos logicos.

entity sensor_sync_m is
-- Entidad del sincronizador de señal de sensor.
    port (
        clk_50mhz  : in  STD_LOGIC;
        -- Reloj de 50 MHz para el sincronizador.
        reset_n    : in  STD_LOGIC;
        -- Reset asíncrono activo en bajo.
        sensor_in  : in  STD_LOGIC;
        -- Entrada asíncrona proveniente del sensor óptico.
        sensor_out : out STD_LOGIC
        -- Salida sincrona lista para la FSM posterior.
    );
end entity;

architecture Behavioral of sensor_sync_m is
-- Arquitectura comportamental de doble etapa de sincronización.
    signal etapa_1 : STD_LOGIC := '0';
    -- Primera etapa de sincronización.
    signal etapa_2 : STD_LOGIC := '0';
    -- Segunda etapa de sincronización.
begin

    process(clk_50mhz, reset_n)
    -- Proceso sensitivo a reloj y reset asíncrono.
    begin
        if reset_n = '0' then
            -- Si reset está activo, inicializa ambas etapas a 0.
            etapa_1 <= '0';
            etapa_2 <= '0';

        elsif rising_edge(clk_50mhz) then
            -- En cada flanco de subida del reloj.
            etapa_1 <= sensor_in;
            -- Captura la entrada asíncrona en la primera etapa.
            etapa_2 <= etapa_1;
            -- Pasa la primera etapa a la segunda para sincronizar.
        end if;
    end process;

    sensor_out <= etapa_2;
    -- La salida sincronizada se toma desde la segunda etapa.

end Behavioral;
-- Fin de la arquitectura comportamental del sincronizador.
