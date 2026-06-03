-- Modulo: Divisor de Frecuencia Modular
-- Este módulo genera un reloj VGA aproximado de 25 MHz y un pulso auxiliar de 10 ms.

library IEEE;
-- Importa la librería IEEE estándar.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para los tipos lógicos.

entity relojes_m is
-- Entidad del divisor de frecuencia.
    port (
        clk_50mhz  : in  STD_LOGIC;
        -- Reloj de entrada principal de 50 MHz.
        clk_vga    : out STD_LOGIC;
        -- Salida del reloj VGA dividido.
        pulso_10ms : out STD_LOGIC
        -- Salida de pulso de 10 ms para depuración u otros usos.
    );
end entity;

architecture Behavioral of relojes_m is
-- Arquitectura comportamental del divisor de frecuencia.
    signal contador_10ms : integer range 0 to 249999 := 0;
    -- Contador de ciclos para generar el pulso de 10 ms.
    signal r_10ms        : STD_LOGIC := '0';
    -- Registro interno que guarda el estado del pulso de 10 ms.
    signal r_vga         : STD_LOGIC := '0';
    -- Registro interno que guarda el estado del reloj VGA.
begin

    -- Pixel clock aproximado de 25 MHz para VGA 640x480.
    process(clk_50mhz)
    begin
        if rising_edge(clk_50mhz) then
            r_vga <= not r_vga;
            -- Invierte el bit r_vga en cada flanco para dividir el reloj por 2.
        end if;
    end process;

    clk_vga <= r_vga;
    -- Asigna el registro r_vga a la salida del reloj VGA.

    -- Pulso auxiliar de 10 ms para depuración.
    process(clk_50mhz)
    begin
        if rising_edge(clk_50mhz) then
            if contador_10ms = 249999 then
                -- Si se alcanzaron 250,000 ciclos de 50 MHz -> 10 ms.
                contador_10ms <= 0;
                -- Reinicia el contador.
                r_10ms <= not r_10ms;
                -- Cambia el estado del pulso para crear una señal de 10 ms.
            else
                contador_10ms <= contador_10ms + 1;
                -- Incrementa el contador de ciclos.
            end if;
        end if;
    end process;

    pulso_10ms <= r_10ms;
    -- Asigna el registro de 10 ms a la salida.

end Behavioral;
-- Fin de la arquitectura comportamental del divisor de frecuencia.
