-- Modulo: Filtro Digital para Sensor Optico
-- Acepta un cambio solo si la entrada permanece estable.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sensor_filter_m is
    port (
        clk_50mhz : in  STD_LOGIC;
        reset_n   : in  STD_LOGIC;
        entrada   : in  STD_LOGIC;
        salida    : out STD_LOGIC
    );
end entity;

architecture Behavioral of sensor_filter_m is

    -- 50,000 ciclos a 50 MHz = 1 ms aproximadamente.
    -- Si hay ruido, subir a 100000.
    -- Si se vuelve lento, bajar a 25000.
    constant TIEMPO_ESTABLE : integer := 50000;

    signal entrada_anterior : STD_LOGIC := '0';
    signal salida_filtrada  : STD_LOGIC := '0';
    signal contador         : integer range 0 to TIEMPO_ESTABLE := 0;

begin

    process(clk_50mhz, reset_n)
    begin
        if reset_n = '0' then
            entrada_anterior <= '0';
            salida_filtrada  <= '0';
            contador         <= 0;

        elsif rising_edge(clk_50mhz) then
            if entrada = entrada_anterior then
                if contador < TIEMPO_ESTABLE then
                    contador <= contador + 1;
                else
                    salida_filtrada <= entrada;
                end if;
            else
                entrada_anterior <= entrada;
                contador <= 0;
            end if;
        end if;
    end process;

    salida <= salida_filtrada;

end Behavioral;