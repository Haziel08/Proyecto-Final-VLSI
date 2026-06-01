-- Modulo: Generador VGA de Figuras con Sprite Maps
-- Dibuja una sola figura a la vez en una matriz de 9 cuadrantes.
--
-- Cada figura usa dos mapas:
-- exterior = silueta completa
-- interior = zona de relleno
--
-- exterior=1 e interior=0 -> filete
-- interior=1              -> relleno

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity generador_vga_figuras_m is
    port (
        visible        : in  STD_LOGIC;
        pixel_x        : in  integer;
        pixel_y        : in  integer;

        figura_visible : in  STD_LOGIC;
        posicion       : in  STD_LOGIC_VECTOR(3 downto 0);
        figura         : in  STD_LOGIC_VECTOR(1 downto 0);
        color_filete   : in  STD_LOGIC_VECTOR(1 downto 0);
        color_relleno  : in  STD_LOGIC_VECTOR(1 downto 0);

        vga_r          : out STD_LOGIC_VECTOR(3 downto 0);
        vga_g          : out STD_LOGIC_VECTOR(3 downto 0);
        vga_b          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end entity;

architecture Behavioral of generador_vga_figuras_m is

    type sprite16_t is array(0 to 15) of STD_LOGIC_VECTOR(0 to 15);

    -- Figura 00: circulo
    constant CIRCULO_EXT : sprite16_t := (
        "0000000000000000",
        "0000111111110000",
        "0001111111111000",
        "0011111111111100",
        "0111111111111110",
        "0111111111111110",
        "0111111111111110",
        "0111111111111110",
        "0111111111111110",
        "0111111111111110",
        "0111111111111110",
        "0111111111111110",
        "0011111111111100",
        "0001111111111000",
        "0000111111110000",
        "0000000000000000"
    );

    constant CIRCULO_INT : sprite16_t := (
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000011111100000",
        "0000111111110000",
        "0001111111111000",
        "0001111111111000",
        "0001111111111000",
        "0001111111111000",
        "0001111111111000",
        "0001111111111000",
        "0000111111110000",
        "0000011111100000",
        "0000000000000000",
        "0000000000000000",
        "0000000000000000"
    );

    -- Figura 01: rectangulo
    constant RECT_EXT : sprite16_t := (
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111"
    );

    constant RECT_INT : sprite16_t := (
        "0000000000000000",
        "0000000000000000",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0000000000000000",
        "0000000000000000"
    );

    -- Figura 10: triangulo
    constant TRI_EXT : sprite16_t := (
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000000110000000",
        "0000000110000000",
        "0000001111000000",
        "0000001111000000",
        "0000011111100000",
        "0000011111100000",
        "0000111111110000",
        "0000111111110000",
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0111111111111110"
    );

    constant TRI_INT : sprite16_t := (
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000000110000000",
        "0000000110000000",
        "0000001111000000",
        "0000001111000000",
        "0000011111100000",
        "0000011111100000",
        "0000111111110000",
        "0000000000000000",
        "0000000000000000",
        "0000000000000000"
    );

    constant ESCALA       : integer := 6;
    constant SPRITE_SIZE  : integer := 16;
    constant ANCHO_FIGURA : integer := SPRITE_SIZE * ESCALA;

    function color_rgb(
        codigo     : STD_LOGIC_VECTOR(1 downto 0);
        es_relleno : boolean
    )
        return STD_LOGIC_VECTOR is

        variable rgb : STD_LOGIC_VECTOR(11 downto 0);
    begin
        case codigo is

            when "00" =>
                if es_relleno then
                    rgb := "111111111111"; -- blanco
                else
                    rgb := "000000000000"; -- negro
                end if;

            when "01" =>
                rgb := "111100000000"; -- rojo

            when "10" =>
                rgb := "000000001111"; -- azul

            when others =>
                rgb := "000011110000"; -- verde
        end case;

        return rgb;
    end function;

begin

    process(
        visible,
        pixel_x,
        pixel_y,
        figura_visible,
        posicion,
        figura,
        color_filete,
        color_relleno
    )
        variable centro_x, centro_y : integer;
        variable inicio_x, inicio_y : integer;
        variable local_x, local_y   : integer;
        variable col, fila          : integer;

        variable px_exterior : STD_LOGIC;
        variable px_interior : STD_LOGIC;

        variable color_final : STD_LOGIC_VECTOR(11 downto 0);
        variable color_fil   : STD_LOGIC_VECTOR(11 downto 0);
        variable color_rel   : STD_LOGIC_VECTOR(11 downto 0);
    begin

        -- Fondo negro.
        color_final := "000000000000";
        color_fil   := color_rgb(color_filete, false);
        color_rel   := color_rgb(color_relleno, true);

        -- Centros aproximados de matriz 3x3 en 640x480.
        case posicion is
            when "0000" => centro_x := 106; centro_y := 80;
            when "0001" => centro_x := 320; centro_y := 80;
            when "0010" => centro_x := 533; centro_y := 80;

            when "0011" => centro_x := 106; centro_y := 240;
            when "0100" => centro_x := 320; centro_y := 240;
            when "0101" => centro_x := 533; centro_y := 240;

            when "0110" => centro_x := 106; centro_y := 400;
            when "0111" => centro_x := 320; centro_y := 400;
            when others => centro_x := 533; centro_y := 400;
        end case;

        inicio_x := centro_x - (ANCHO_FIGURA / 2);
        inicio_y := centro_y - (ANCHO_FIGURA / 2);

        px_exterior := '0';
        px_interior := '0';

        if visible = '1' and figura_visible = '1' then

            if pixel_x >= inicio_x and pixel_x < inicio_x + ANCHO_FIGURA and
               pixel_y >= inicio_y and pixel_y < inicio_y + ANCHO_FIGURA then

                local_x := pixel_x - inicio_x;
                local_y := pixel_y - inicio_y;

                col  := local_x / ESCALA;
                fila := local_y / ESCALA;

                case figura is
                    when "00" =>
                        px_exterior := CIRCULO_EXT(fila)(col);
                        px_interior := CIRCULO_INT(fila)(col);

                    when "01" =>
                        px_exterior := RECT_EXT(fila)(col);
                        px_interior := RECT_INT(fila)(col);

                    when others =>
                        px_exterior := TRI_EXT(fila)(col);
                        px_interior := TRI_INT(fila)(col);
                end case;

                if px_interior = '1' then
                    color_final := color_rel;

                elsif px_exterior = '1' then
                    color_final := color_fil;
                end if;

            end if;
        end if;

        if visible = '1' then
            vga_r <= color_final(11 downto 8);
            vga_g <= color_final(7 downto 4);
            vga_b <= color_final(3 downto 0);
        else
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";
        end if;

    end process;

end Behavioral;