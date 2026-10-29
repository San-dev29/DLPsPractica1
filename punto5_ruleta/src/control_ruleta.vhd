library ieee;
use ieee.std_logic_1164.all;

-- Biestable tipo T: cada pulso limpio del boton conmuta entre
-- RUN ('1', la ruleta gira) y STOP ('0', el valor queda congelado).
entity control_ruleta is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        pulso   : in  std_logic;
        running : out std_logic
    );
end control_ruleta;

architecture rtl of control_ruleta is
    signal estado : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                estado <= '0';
            elsif pulso = '1' then
                estado <= not estado;
            end if;
        end if;
    end process;

    running <= estado;

end rtl;
