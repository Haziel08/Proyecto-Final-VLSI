-- Modulo: Divisor de Frecuencia Modular

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity relojes_m is
    port (
        clk_50mhz  : in  STD_LOGIC;
        clk_vga    : out STD_LOGIC;
        pulso_10ms : out STD_LOGIC
    );
end entity;

architecture Behavioral of relojes_m is
    signal contador_10ms : integer range 0 to 249999 := 0;
    signal r_10ms        : STD_LOGIC := '0';
    signal r_vga         : STD_LOGIC := '0';
begin

    -- Pixel clock aproximado de 25 MHz para VGA 640x480.
    process(clk_50mhz)
    begin
        if rising_edge(clk_50mhz) then
            r_vga <= not r_vga;
        end if;
    end process;

    clk_vga <= r_vga;

    -- Pulso auxiliar para depuracion.
    process(clk_50mhz)
    begin
        if rising_edge(clk_50mhz) then
            if contador_10ms = 249999 then
                contador_10ms <= 0;
                r_10ms <= not r_10ms;
            else
                contador_10ms <= contador_10ms + 1;
            end if;
        end if;
    end process;

    pulso_10ms <= r_10ms;

end Behavioral;