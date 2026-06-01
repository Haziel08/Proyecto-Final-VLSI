-- Modulo: Control Principal de Figura
-- Guarda los datos validos recibidos y ejecuta el comando de borrado.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_figura_m is
    port (
        clk_50mhz      : in  STD_LOGIC;
        reset_n        : in  STD_LOGIC;
        trama_valida   : in  STD_LOGIC;
        cmd            : in  STD_LOGIC;

        posicion_in    : in  STD_LOGIC_VECTOR(3 downto 0);
        figura_in      : in  STD_LOGIC_VECTOR(1 downto 0);
        filete_in      : in  STD_LOGIC_VECTOR(1 downto 0);
        relleno_in     : in  STD_LOGIC_VECTOR(1 downto 0);

        figura_visible : out STD_LOGIC;
        posicion_out   : out STD_LOGIC_VECTOR(3 downto 0);
        figura_out     : out STD_LOGIC_VECTOR(1 downto 0);
        filete_out     : out STD_LOGIC_VECTOR(1 downto 0);
        relleno_out    : out STD_LOGIC_VECTOR(1 downto 0)
    );
end entity;

architecture Behavioral of control_figura_m is

    signal visible_reg : STD_LOGIC := '0';
    signal pos_reg     : STD_LOGIC_VECTOR(3 downto 0) := "0100";
    signal fig_reg     : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal fil_reg     : STD_LOGIC_VECTOR(1 downto 0) := "01";
    signal rel_reg     : STD_LOGIC_VECTOR(1 downto 0) := "10";

begin

    process(clk_50mhz, reset_n)
    begin
        if reset_n = '0' then
            visible_reg <= '0';
            pos_reg     <= "0100";
            fig_reg     <= "00";
            fil_reg     <= "01";
            rel_reg     <= "10";

        elsif rising_edge(clk_50mhz) then
            if trama_valida = '1' then

                if cmd = '1' then
                    -- Comando borrar / limpiar VGA.
                    visible_reg <= '0';

                else
                    -- Comando dibujar.
                    visible_reg <= '1';
                    pos_reg     <= posicion_in;
                    fig_reg     <= figura_in;
                    fil_reg     <= filete_in;
                    rel_reg     <= relleno_in;
                end if;

            end if;
        end if;
    end process;

    figura_visible <= visible_reg;
    posicion_out   <= pos_reg;
    figura_out     <= fig_reg;
    filete_out     <= fil_reg;
    relleno_out    <= rel_reg;

end Behavioral;