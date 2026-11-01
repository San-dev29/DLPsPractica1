library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Practica 1, punto 3: contador binario de 4 bits ascendente/descendente.
--
--   * rst_n = '0' borra el contador de forma asincrona (reset activo bajo).
--   * ena   = '1' permite contar; con '0' el valor se conserva.
--   * dir   = '1' cuenta ascendente y '0' descendente.
--   * Al llegar a 15 asciende a 0 y al llegar a 0 desciende a 15
--     (desbordamiento natural de 4 bits).
--
-- El reloj es el de la placa (50 MHz). El nivel superior genera el pulso
-- de habilitacion (ena) a una frecuencia visible para el usuario, de modo
-- que el contador no se relojiza con el pulsador.
entity contador_ud is
    generic (
        ANCHO : integer := 4
    );
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;                              -- Reset asincrono, activo bajo
        ena   : in  std_logic;                              -- Habilitacion de conteo
        dir   : in  std_logic;                              -- 1 = ascendente, 0 = descendente
        q     : out std_logic_vector(ANCHO - 1 downto 0)
    );
end contador_ud;

architecture rtl of contador_ud is
    signal cnt : unsigned(ANCHO - 1 downto 0) := (others => '0');
begin

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= (others => '0');
        elsif rising_edge(clk) then
            if ena = '1' then
                if dir = '1' then
                    cnt <= cnt + 1;                         -- Cuenta ascendente
                else
                    cnt <= cnt - 1;                         -- Cuenta descendente
                end if;
            end if;
        end if;
    end process;

    q <= std_logic_vector(cnt);

end rtl;
