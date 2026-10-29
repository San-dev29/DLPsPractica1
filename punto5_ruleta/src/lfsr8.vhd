library ieee;
use ieee.std_logic_1164.all;

-- Generador pseudoaleatorio de 8 bits (LFSR Galois).
-- Polinomio: x^8 + x^6 + x^5 + x^4 + 1  ->  mascara 0xB8, periodo 255.
-- 'load' permite sembrar el registro con un contador libre en el
-- instante en que el usuario arranca la ruleta, de modo que el
-- resultado depende de la pulsacion humana.
entity lfsr8 is
    port (
        clk  : in  std_logic;
        tick : in  std_logic;
        load : in  std_logic;
        seed : in  std_logic_vector(7 downto 0);
        q    : out std_logic_vector(7 downto 0)
    );
end lfsr8;

architecture rtl of lfsr8 is
    constant TAPS : std_logic_vector(7 downto 0) := X"B8";

    signal q_reg : std_logic_vector(7 downto 0) := X"01";
begin

    process (clk)
        variable nxt : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if load = '1' then
                -- Semilla: nunca se permite el estado cero
                if seed = X"00" then
                    q_reg <= X"01";
                else
                    q_reg <= seed;
                end if;
            elsif tick = '1' then
                nxt := '0' & q_reg(7 downto 1);
                if q_reg(0) = '1' then
                    nxt := nxt xor TAPS;
                end if;
                q_reg <= nxt;
            end if;
        end if;
    end process;

    q <= q_reg;

end rtl;
