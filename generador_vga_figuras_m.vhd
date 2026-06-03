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
-- Importa la librería estándar IEEE.
use IEEE.STD_LOGIC_1164.ALL;
-- Usa el paquete STD_LOGIC_1164 para los tipos lógicos.

entity generador_vga_figuras_m is
-- Entidad del módulo generador VGA para figuras.
    port (
        visible        : in  STD_LOGIC;
        -- Indica si el pixel actual está en el área visible VGA.
        pixel_x        : in  integer;
        -- Coordenada X actual del pixel VGA.
        pixel_y        : in  integer;
        -- Coordenada Y actual del pixel VGA.

        figura_visible : in  STD_LOGIC;
        -- Señal que habilita el dibujado de la figura.
        posicion       : in  STD_LOGIC_VECTOR(3 downto 0);
        -- Posición de la figura dentro de la matriz 3x3.
        figura         : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Tipo de figura a dibujar (círculo, rectángulo, triángulo).
        color_filete   : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Código de color del contorno.
        color_relleno  : in  STD_LOGIC_VECTOR(1 downto 0);
        -- Código de color del relleno.

        vga_r          : out STD_LOGIC_VECTOR(3 downto 0);
        -- Salida de color rojo VGA de 4 bits.
        vga_g          : out STD_LOGIC_VECTOR(3 downto 0);
        -- Salida de color verde VGA de 4 bits.
        vga_b          : out STD_LOGIC_VECTOR(3 downto 0)
        -- Salida de color azul VGA de 4 bits.
    );
end entity;

architecture Behavioral of generador_vga_figuras_m is
-- Arquitectura que implementa la lógica de dibujo de figuras.

    type sprite16_t is array(0 to 15) of STD_LOGIC_VECTOR(0 to 15);
    -- Define un tipo de sprite de 16x16 bits.

    -- Figura 00: circulo
    constant CIRCULO_EXT : sprite16_t := (
        -- Mapa de bits para el contorno del círculo.
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
        -- Mapa de bits para el área interior del círculo.
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
        -- Mapa de bits para el contorno del rectángulo.
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
        -- Mapa de bits para el interior del rectángulo.
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
        -- Mapa de bits para el contorno del triángulo.
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
        -- Mapa de bits para el interior del triángulo.
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
    -- Tamaño del sprite multiplicado para ajustar a la pantalla.
    constant SPRITE_SIZE  : integer := 16;
    -- Dimensión original del sprite en pixeles.
    constant ANCHO_FIGURA : integer := SPRITE_SIZE * ESCALA;
    -- Ancho total de la figura escalada.

    function color_rgb(
        codigo     : STD_LOGIC_VECTOR(1 downto 0);
        es_relleno : boolean
    )
        return STD_LOGIC_VECTOR is
        -- Función que convierte un código de color en valor RGB de 12 bits.

        variable rgb : STD_LOGIC_VECTOR(11 downto 0);
        -- Variable temporal para almacenar el color.
    begin
        case codigo is
            when "00" =>
                if es_relleno then
                    rgb := "111111111111"; -- blanco
                    -- Relleno blanco.
                else
                    rgb := "000000000000"; -- negro
                    -- Contorno negro.
                end if;
            when "01" =>
                rgb := "111100000000"; -- rojo
                -- Canal rojo alto.
            when "10" =>
                rgb := "000000001111"; -- azul
                -- Canal azul alto.
            when others =>
                rgb := "000011110000"; -- verde
                -- Canal verde alto.
        end case;

        return rgb;
        -- Devuelve el color codificado en RGB de 12 bits.
    end function;

begin
-- Inicio de la arquitectura comportamental.

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
        -- Coordenadas del centro de la figura en pantalla.
        variable inicio_x, inicio_y : integer;
        -- Coordenadas iniciales de la esquina superior izquierda.
        variable local_x, local_y   : integer;
        -- Coordenadas dentro del sprite escalado.
        variable col, fila          : integer;
        -- Columnas y filas del sprite sin escalar.

        variable px_exterior : STD_LOGIC;
        -- Valor del pixel del mapa exterior.
        variable px_interior : STD_LOGIC;
        -- Valor del pixel del mapa interior.

        variable color_final : STD_LOGIC_VECTOR(11 downto 0);
        -- Color final que se asignará a VGA.
        variable color_fil   : STD_LOGIC_VECTOR(11 downto 0);
        -- Color del filete convertido a RGB.
        variable color_rel   : STD_LOGIC_VECTOR(11 downto 0);
        -- Color del relleno convertido a RGB.
    begin

        -- Fondo negro por defecto.
        color_final := "000000000000";
        -- Inicializa el color final en negro.
        color_fil   := color_rgb(color_filete, false);
        -- Calcula el color de contorno.
        color_rel   := color_rgb(color_relleno, true);
        -- Calcula el color de relleno.

        -- Centros aproximados de matriz 3x3 en resolución 640x480.
        case posicion is
            when "0000" => centro_x := 106; centro_y := 80;
            -- Posición superior izquierda.
            when "0001" => centro_x := 320; centro_y := 80;
            -- Posición superior centro.
            when "0010" => centro_x := 533; centro_y := 80;
            -- Posición superior derecha.
            when "0011" => centro_x := 106; centro_y := 240;
            -- Posición medio izquierda.
            when "0100" => centro_x := 320; centro_y := 240;
            -- Posición centro.
            when "0101" => centro_x := 533; centro_y := 240;
            -- Posición medio derecha.
            when "0110" => centro_x := 106; centro_y := 400;
            -- Posición inferior izquierda.
            when "0111" => centro_x := 320; centro_y := 400;
            -- Posición inferior centro.
            when others => centro_x := 533; centro_y := 400;
            -- Posición inferior derecha.
        end case;

        inicio_x := centro_x - (ANCHO_FIGURA / 2);
        -- Calcula el borde izquierdo de la figura.
        inicio_y := centro_y - (ANCHO_FIGURA / 2);
        -- Calcula el borde superior de la figura.

        px_exterior := '0';
        -- Inicializa el valor exterior en 0 (apagado).
        px_interior := '0';
        -- Inicializa el valor interior en 0 (apagado).

        if visible = '1' and figura_visible = '1' then
            -- Solo dibuja si el pixel está visible y la figura está activa.

            if pixel_x >= inicio_x and pixel_x < inicio_x + ANCHO_FIGURA and
               pixel_y >= inicio_y and pixel_y < inicio_y + ANCHO_FIGURA then
                -- Comprueba si el pixel actual está dentro del área de la figura.

                local_x := pixel_x - inicio_x;
                -- Coordenada X relativa dentro del sprite escalado.
                local_y := pixel_y - inicio_y;
                -- Coordenada Y relativa dentro del sprite escalado.

                col  := local_x / ESCALA;
                -- Convierte la coordenada local X a columna de sprite.
                fila := local_y / ESCALA;
                -- Convierte la coordenada local Y a fila de sprite.

                case figura is
                    when "00" =>
                        -- Si la figura es círculo.
                        px_exterior := CIRCULO_EXT(fila)(col);
                        -- Lee el bit del contorno del círculo.
                        px_interior := CIRCULO_INT(fila)(col);
                        -- Lee el bit del interior del círculo.
                    when "01" =>
                        -- Si la figura es rectángulo.
                        px_exterior := RECT_EXT(fila)(col);
                        -- Lee el bit del contorno del rectángulo.
                        px_interior := RECT_INT(fila)(col);
                        -- Lee el bit del interior del rectángulo.
                    when others =>
                        -- Si la figura es triángulo o cualquier otro valor.
                        px_exterior := TRI_EXT(fila)(col);
                        -- Lee el bit del contorno del triángulo.
                        px_interior := TRI_INT(fila)(col);
                        -- Lee el bit del interior del triángulo.
                end case;

                if px_interior = '1' then
                    color_final := color_rel;
                    -- Si el píxel pertenece al interior, usa el color de relleno.
                elsif px_exterior = '1' then
                    color_final := color_fil;
                    -- Si el píxel pertenece al contorno, usa el color de filete.
                end if;

            end if;
        end if;

        if visible = '1' then
            -- Si el pixel está visible, asigna los canales RGB.
            vga_r <= color_final(11 downto 8);
            -- Bits más altos: rojo.
            vga_g <= color_final(7 downto 4);
            -- Bits medios: verde.
            vga_b <= color_final(3 downto 0);
            -- Bits más bajos: azul.
        else
            -- Si no está visible, pinta negro.
            vga_r <= "0000";
            vga_g <= "0000";
            vga_b <= "0000";
        end if;

    end process;

end Behavioral;
-- Fin de la arquitectura comportamental del generador VGA de figuras.
