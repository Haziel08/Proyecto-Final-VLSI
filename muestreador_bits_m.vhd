-- Modulo: Muestreador de Bits
-- Toma una muestra en el centro de cada simbolo optico.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity muestreador_bits_m is
    port (
        clk_50mhz  : in  STD_LOGIC;
        reset_n    : in  STD_LOGIC;
        sensor     : in  STD_LOGIC;
        bit_rx     : out STD_LOGIC;
        bit_valido : out STD_LOGIC
    );
end entity;

architecture Behavioral of muestreador_bits_m is

    -- BIT_DURATION = 180 ms en HTML.
    -- 50 MHz * 0.180 s = 9,000,000 ciclos.
    constant BIT_TICKS : integer := 9000000;

    type estado_muestreo_t is (ESPERA_INICIO, RECIBIENDO);
    signal estado : estado_muestreo_t := ESPERA_INICIO;

    signal sensor_ant : STD_LOGIC := '0';
    signal contador   : integer range 0 to BIT_TICKS := 0;
    signal bit_reg    : STD_LOGIC := '0';
    signal valido_reg : STD_LOGIC := '0';

begin

    process(clk_50mhz, reset_n)
    begin
        if reset_n = '0' then
            estado     <= ESPERA_INICIO;
            sensor_ant <= '0';
            contador   <= 0;
            bit_reg    <= '0';
            valido_reg <= '0';

        elsif rising_edge(clk_50mhz) then
            valido_reg <= '0';
            sensor_ant <= sensor;

            case estado is

                when ESPERA_INICIO =>
                    contador <= 0;

                    -- El preambulo empieza con 1.
                    -- Por eso se arranca con el primer flanco de luz.
                    if sensor_ant = '0' and sensor = '1' then
                        estado <= RECIBIENDO;
                        contador <= BIT_TICKS / 2;
                    end if;

                when RECIBIENDO =>
                    if contador = BIT_TICKS - 1 then
                        contador   <= 0;
                        bit_reg    <= sensor;
                        valido_reg <= '1';
                    else
                        contador <= contador + 1;
                    end if;

            end case;
        end if;
    end process;

    bit_rx     <= bit_reg;
    bit_valido <= valido_reg;

end Behavioral;