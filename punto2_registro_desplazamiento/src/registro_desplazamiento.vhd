library ieee;
use ieee.std_logic_1164.all;

-- Registro de desplazamiento de 8 bits con entrada serie.
--
-- En cada flanco de subida de clk:
--   * rst = '1'        -> todas las etapas se ponen a 0 (reset sincrono)
--   * enable = '1'     -> el bit din entra en q(0) y las etapas avanzan
--                         hacia q(7): q <= q(6 downto 0) & din
--
-- Por tanto q(0) contiene el bit mas reciente y q(7) el mas antiguo.
-- Cada salida q(i) corresponde a una etapa del registro y se conecta a
-- un LED de la barra externa.
entity registro_desplazamiento is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        enable : in  std_logic;
        din    : in  std_logic;
        q      : out std_logic_vector(7 downto 0)
    );
end registro_desplazamiento;

architecture rtl of registro_desplazamiento is
    signal reg : std_logic_vector(7 downto 0) := (others => '0');
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            elsif enable = '1' then
                reg <= reg(6 downto 0) & din;
            end if;
        end if;
    end process;

    q <= reg;

end rtl;
