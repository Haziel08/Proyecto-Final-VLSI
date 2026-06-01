-- Modulo: Sincronizador de Entrada del Sensor Optico
-- Evita meter una entrada asincrona directamente a la maquina de estados.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sensor_sync_m is
    port (
        clk_50mhz  : in  STD_LOGIC;
        reset_n    : in  STD_LOGIC;
        sensor_in  : in  STD_LOGIC;
        sensor_out : out STD_LOGIC
    );
end entity;

architecture Behavioral of sensor_sync_m is
    signal etapa_1 : STD_LOGIC := '0';
    signal etapa_2 : STD_LOGIC := '0';
begin

    process(clk_50mhz, reset_n)
    begin
        if reset_n = '0' then
            etapa_1 <= '0';
            etapa_2 <= '0';

        elsif rising_edge(clk_50mhz) then
            etapa_1 <= sensor_in;
            etapa_2 <= etapa_1;
        end if;
    end process;

    sensor_out <= etapa_2;

end Behavioral;