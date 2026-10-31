library ieee;
use ieee.std_logic_1164.all;

-- Multiplexor de 4 digitos para el display de 7 segmentos.
--
-- El display de la placa es multiplexado: los segmentos A..G son comunes
-- y cada digito se habilita con una salida independiente (activa alta,
-- transistor NPN). Este modulo recorre los cuatro digitos a DIGIT_HZ y
-- coloca en los segmentos el patron que corresponde a cada uno:
--
--   dig(0) = digito 3 -> valor de la ruleta
--   dig(1) = digito 4 -> letra A
--   dig(2) = digito 5 -> letra B
--   dig(3) = digito 6 -> letra C
--
-- La frecuencia de barrido es de 1 kHz por digito (250 Hz por trama),
-- suficiente para que la persistencia de la vision no muestre parpadeo.
entity display_mux is
    generic (
        CLK_HZ   : integer := 50_000_000;  -- Reloj de la placa
        DIGIT_HZ : integer := 1000         -- Frecuencia de cada digito [Hz]
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;                          -- Reset sincrono, activo alto
        seg_ruleta : in  std_logic_vector(6 downto 0);       -- Segmentos del valor de la ruleta
        seg        : out std_logic_vector(6 downto 0);       -- Segmentos multiplexados
        dig        : out std_logic_vector(3 downto 0)        -- Habilitacion de cada digito
    );
end display_mux;

architecture rtl of display_mux is

    constant DIGIT_CYCLES : integer := CLK_HZ / DIGIT_HZ;

    -- Patrones de las letras A, B y C (segmentos A..G, activo alto)
    constant SEG_A : std_logic_vector(6 downto 0) := "1110111";
    constant SEG_B : std_logic_vector(6 downto 0) := "1111100";
    constant SEG_C : std_logic_vector(6 downto 0) := "0111001";

    signal cont : integer range 0 to DIGIT_CYCLES - 1 := 0;
    signal idx  : integer range 0 to 3 := 0;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cont <= 0;
                idx  <= 0;
                seg  <= (others => '0');
                dig  <= (others => '0');
            else
                -- Base de tiempo del multiplexado
                if cont = DIGIT_CYCLES - 1 then
                    cont <= 0;
                    if idx = 3 then
                        idx <= 0;
                    else
                        idx <= idx + 1;
                    end if;
                else
                    cont <= cont + 1;
                end if;

                -- Salidas registradas: evitan glitches entre digitos
                dig <= (others => '0');
                case idx is
                    when 0 =>
                        dig(0) <= '1';
                        seg    <= seg_ruleta;
                    when 1 =>
                        dig(1) <= '1';
                        seg    <= SEG_A;
                    when 2 =>
                        dig(2) <= '1';
                        seg    <= SEG_B;
                    when others =>
                        dig(3) <= '1';
                        seg    <= SEG_C;
                end case;
            end if;
        end if;
    end process;

end rtl;
