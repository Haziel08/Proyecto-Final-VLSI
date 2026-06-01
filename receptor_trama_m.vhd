-- Modulo: Receptor de Trama Optica
--
-- Protocolo:
-- PREAMBULO 10101010 | START 1110 | CMD | POS | FIG | FILETE | RELLENO | CHECK | STOP
--
-- CMD = 0 -> dibujar figura
-- CMD = 1 -> borrar pantalla

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity receptor_trama_m is
    port (
        clk_50mhz    : in  STD_LOGIC;
        reset_n      : in  STD_LOGIC;
        bit_rx       : in  STD_LOGIC;
        bit_valido   : in  STD_LOGIC;

        trama_valida : out STD_LOGIC;
        cmd          : out STD_LOGIC;
        posicion     : out STD_LOGIC_VECTOR(3 downto 0);
        figura       : out STD_LOGIC_VECTOR(1 downto 0);
        filete       : out STD_LOGIC_VECTOR(1 downto 0);
        relleno      : out STD_LOGIC_VECTOR(1 downto 0)
    );
end entity;

architecture Behavioral of receptor_trama_m is

    constant PATRON_INICIO : STD_LOGIC_VECTOR(11 downto 0) := "101010101110";
    constant STOP_ESPERADO : STD_LOGIC_VECTOR(3 downto 0)  := "0000";

    -- Despues del inicio se reciben 19 bits:
    -- payload 11 + checksum 4 + stop 4
    type estado_receptor_t is (BUSCAR_INICIO, LEER_DATOS);
    signal estado : estado_receptor_t := BUSCAR_INICIO;

    signal shift_inicio : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    signal buffer_trama : STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
    signal cuenta_bits  : integer range 0 to 18 := 0;

    signal trama_ok_reg : STD_LOGIC := '0';
    signal cmd_reg      : STD_LOGIC := '0';
    signal pos_reg      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal fig_reg      : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal fil_reg      : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal rel_reg      : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');

begin

    process(clk_50mhz, reset_n)
        variable temp        : STD_LOGIC_VECTOR(18 downto 0);
        variable payload     : STD_LOGIC_VECTOR(10 downto 0);
        variable payload_pad : STD_LOGIC_VECTOR(11 downto 0);
        variable check_rx    : STD_LOGIC_VECTOR(3 downto 0);
        variable check_calc  : STD_LOGIC_VECTOR(3 downto 0);
        variable stop_rx     : STD_LOGIC_VECTOR(3 downto 0);
    begin
        if reset_n = '0' then
            estado        <= BUSCAR_INICIO;
            shift_inicio  <= (others => '0');
            buffer_trama  <= (others => '0');
            cuenta_bits   <= 0;
            trama_ok_reg  <= '0';
            cmd_reg       <= '0';
            pos_reg       <= (others => '0');
            fig_reg       <= (others => '0');
            fil_reg       <= (others => '0');
            rel_reg       <= (others => '0');

        elsif rising_edge(clk_50mhz) then
            trama_ok_reg <= '0';

            if bit_valido = '1' then
                case estado is

                    when BUSCAR_INICIO =>
                        shift_inicio <= shift_inicio(10 downto 0) & bit_rx;

                        if (shift_inicio(10 downto 0) & bit_rx) = PATRON_INICIO then
                            estado <= LEER_DATOS;
                            cuenta_bits <= 0;
                            buffer_trama <= (others => '0');
                        end if;

                    when LEER_DATOS =>
                        temp := buffer_trama;
                        temp(18 - cuenta_bits) := bit_rx;
                        buffer_trama <= temp;

                        if cuenta_bits = 18 then
                            payload     := temp(18 downto 8);
                            check_rx    := temp(7 downto 4);
                            stop_rx     := temp(3 downto 0);
                            payload_pad := payload & '0';

                            -- Mismo checksum del HTML:
                            -- XOR de tres nibbles.
                            check_calc := payload_pad(11 downto 8) xor
                                          payload_pad(7 downto 4)  xor
                                          payload_pad(3 downto 0);

                            if check_rx = check_calc and stop_rx = STOP_ESPERADO then
                                cmd_reg      <= payload(10);
                                pos_reg      <= payload(9 downto 6);
                                fig_reg      <= payload(5 downto 4);
                                fil_reg      <= payload(3 downto 2);
                                rel_reg      <= payload(1 downto 0);
                                trama_ok_reg <= '1';
                            end if;

                            estado <= BUSCAR_INICIO;
                            cuenta_bits <= 0;
                        else
                            cuenta_bits <= cuenta_bits + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    trama_valida <= trama_ok_reg;
    cmd          <= cmd_reg;
    posicion     <= pos_reg;
    figura       <= fig_reg;
    filete       <= fil_reg;
    relleno      <= rel_reg;

end Behavioral;