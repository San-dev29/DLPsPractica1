library ieee;
use ieee.std_logic_1164.all;

-- Decodificador binario a 7 segmentos.
-- s = '1' invierte la salida (display de catodo comun).
-- El orden de d es: d(6..0) = A,B,C,D,E,F,G y d(7) = DP.
entity BinSieteseg is
    port (
        A : in  std_logic_vector(3 downto 0);
        s : in  std_logic;
        d : out std_logic_vector(7 downto 0)
    );
end BinSieteseg;

architecture arqBinSieteseg of BinSieteseg is
    signal A_sel : std_logic_vector(3 downto 0);
begin
    A_sel <= (not A) when s = '1' else
             A; -- Invierte la senal cuando s es 1

    process (A_sel)
    begin
        case A_sel is
            when X"0" => d <= X"3F";
            when X"1" => d <= X"06";
            when X"2" => d <= X"5B";
            when X"3" => d <= X"4F";
            when X"4" => d <= X"66";
            when X"5" => d <= X"6D";
            when X"6" => d <= X"7D";
            when X"7" => d <= X"07";
            when X"8" => d <= X"7F";
            when X"9" => d <= X"6F";
            when X"A" => d <= X"77";
            when X"B" => d <= X"7C";
            when X"C" => d <= X"39";
            when X"D" => d <= X"5E";
            when X"E" => d <= X"79";
            when X"F" => d <= X"71";
            when others => d <= (others => '0');
        end case;
    end process;
end arqBinSieteseg;
