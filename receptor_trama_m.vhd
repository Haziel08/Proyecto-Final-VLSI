-- Modulo: Receptor de Trama Optica
--
-- Protocolo:
-- PREAMBULO 10101010 | START 1110 | CMD | POS | FIG | FILETE | RELLENO | CHECK | STOP
--
-- CMD = 0 -> dibujar figura
-- CMD = 1 -> borrar pantalla

library IEEE;
-- Importa la libreria IEEE para tipos logicos.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para STD_LOGIC y vectores.

entity receptor_trama_m is
-- Entidad del receptor de trama optica.
    port (
        clk_50mhz    : in  STD_LOGIC;
        -- Reloj de 50 MHz para la logica secuencial.
        reset_n      : in  STD_LOGIC;
        -- Reset asíncrono activo bajo.
        bit_rx       : in  STD_LOGIC;
        -- Bit recibido desde el muestreador.
        bit_valido   : in  STD_LOGIC;
        -- Indica cuando el bit recibido es válido.

        trama_valida : out STD_LOGIC;
        -- Señal que indica trama recibida y verificada.
        cmd          : out STD_LOGIC;
        -- Comando decodificado: dibujar o borrar.
        posicion     : out STD_LOGIC_VECTOR(3 downto 0);
        -- Posición decodificada de la figura.
        figura       : out STD_LOGIC_VECTOR(1 downto 0);
        -- Tipo de figura decodificado.
        filete       : out STD_LOGIC_VECTOR(1 downto 0);
        -- Color de contorno decodificado.
        relleno      : out STD_LOGIC_VECTOR(1 downto 0)
        -- Color de relleno decodificado.
    );
end entity;

architecture Behavioral of receptor_trama_m is
-- Arquitectura comportamental del receptor de trama.

    constant PATRON_INICIO : STD_LOGIC_VECTOR(11 downto 0) := "101010101110";
    -- Patrón de inicio que combina preámbulo y start.
    constant STOP_ESPERADO : STD_LOGIC_VECTOR(3 downto 0)  := "0000";
    -- Patrón de stop esperado al final de cada trama.

    -- Después del inicio se reciben 19 bits:
    -- payload 11 + checksum 4 + stop 4
    type estado_receptor_t is (BUSCAR_INICIO, LEER_DATOS);
    -- Tipo de estado del receptor.
    signal estado : estado_receptor_t := BUSCAR_INICIO;
    -- Estado inicial: buscar el patrón de inicio.

    signal shift_inicio : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    -- Registro de desplazamiento para detectar el inicio.
    signal buffer_trama : STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
    -- Buffer que almacena los 19 bits de la trama.
    signal cuenta_bits  : integer range 0 to 18 := 0;
    -- Contador de bits leídos en la fase de trama.

    signal trama_ok_reg : STD_LOGIC := '0';
    -- Registro que indica trama válida tras la verificación.
    signal cmd_reg      : STD_LOGIC := '0';
    -- Registro del comando decodificado.
    signal pos_reg      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    -- Registro de la posición decodificada.
    signal fig_reg      : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    -- Registro del tipo de figura decodificado.
    signal fil_reg      : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    -- Registro del color de filete decodificado.
    signal rel_reg      : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    -- Registro del color de relleno decodificado.

begin

    process(clk_50mhz, reset_n)
    -- Proceso sensitivo a reloj y reset asíncrono.
        variable temp        : STD_LOGIC_VECTOR(18 downto 0);
        -- Variable temporal para manipular el buffer.
        variable payload     : STD_LOGIC_VECTOR(10 downto 0);
        -- Payload de 11 bits extraído de la trama.
        variable payload_pad : STD_LOGIC_VECTOR(11 downto 0);
        -- Payload con un bit extra para calcular checksum.
        variable check_rx    : STD_LOGIC_VECTOR(3 downto 0);
        -- Checksum recibido desde la trama.
        variable check_calc  : STD_LOGIC_VECTOR(3 downto 0);
        -- Checksum calculado internamente.
        variable stop_rx     : STD_LOGIC_VECTOR(3 downto 0);
        -- Bits de stop recibidos desde la trama.
    begin
        if reset_n = '0' then
            -- Reset asíncrono: volver a estado inicial y borrar registros.
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
            -- Borra la señal de trama válida cada ciclo, se activa solo cuando hay trama correcta.

            if bit_valido = '1' then
            -- Procesa el bit solo cuando está marcado como válido.
                case estado is

                    when BUSCAR_INICIO =>
                        -- Desplaza el registro del inicio y agrega el bit actual.
                        shift_inicio <= shift_inicio(10 downto 0) & bit_rx;

                        if (shift_inicio(10 downto 0) & bit_rx) = PATRON_INICIO then
                            -- Si detecta el patrón de preámbulo+start, cambia a leer datos.
                            estado <= LEER_DATOS;
                            cuenta_bits <= 0;
                            buffer_trama <= (others => '0');
                        end if;

                    when LEER_DATOS =>
                        -- Copia el buffer a la variable temporal para modificarlo.
                        temp := buffer_trama;
                        -- Inserta el bit en la posición correspondiente.
                        temp(18 - cuenta_bits) := bit_rx;
                        buffer_trama <= temp;

                        if cuenta_bits = 18 then
                            -- Si se recibieron los 19 bits de datos, procesa la trama.
                            payload     := temp(18 downto 8);
                            -- Extrae el payload de 11 bits.
                            check_rx    := temp(7 downto 4);
                            -- Extrae el checksum recibido.
                            stop_rx     := temp(3 downto 0);
                            -- Extrae los bits de stop.
                            payload_pad := payload & '0';
                            -- Agrega un cero al final para formar 12 bits.

                            -- Mismo checksum del HTML:
                            -- XOR de tres nibbles.
                            check_calc := payload_pad(11 downto 8) xor
                                          payload_pad(7 downto 4)  xor
                                          payload_pad(3 downto 0);
                            -- Calcula el checksum usando XOR de cada nibble.

                            if check_rx = check_calc and stop_rx = STOP_ESPERADO then
                                -- Solo acepta la trama si checksum y stop son correctos.
                                cmd_reg      <= payload(10);
                                -- El bit de comando está en la posición 10.
                                pos_reg      <= payload(9 downto 6);
                                -- Los siguientes 4 bits son la posición.
                                fig_reg      <= payload(5 downto 4);
                                -- Los siguientes 2 bits son el tipo de figura.
                                fil_reg      <= payload(3 downto 2);
                                -- Los siguientes 2 bits son el color del filete.
                                rel_reg      <= payload(1 downto 0);
                                -- Los últimos 2 bits son el color de relleno.
                                trama_ok_reg <= '1';
                                -- Marca la trama como válida.
                            end if;

                            estado <= BUSCAR_INICIO;
                            -- Vuelve a buscar el siguiente inicio de trama.
                            cuenta_bits <= 0;
                            -- Reinicia el contador de bits.
                        else
                            cuenta_bits <= cuenta_bits + 1;
                            -- Incrementa el contador de bits mientras recibe.
                        end if;

                end case;
            end if;
        end if;
    end process;

    trama_valida <= trama_ok_reg;
    -- Salida que indica que la trama fue verificada correctamente.
    cmd          <= cmd_reg;
    -- Salida del comando decodificado.
    posicion     <= pos_reg;
    -- Salida de la posición decodificada.
    figura       <= fig_reg;
    -- Salida del tipo de figura decodificada.
    filete       <= fil_reg;
    -- Salida del color de filete decodificado.
    relleno      <= rel_reg;
    -- Salida del color de relleno decodificado.

end Behavioral;
-- Fin de la arquitectura comportamental del receptor de trama.
