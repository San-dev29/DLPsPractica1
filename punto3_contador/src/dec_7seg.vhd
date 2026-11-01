library ieee;
use ieee.std_logic_1164.all;

-- Decodificador binario de 4 bits a 7 segmentos (0..F).
-- La salida es activa alta y el orden es seg(6)=G, ..., seg(0)=A,
-- igual que las asignaciones de pines del display de la placa.
--
-- Los valores 11 y 13 se muestran como "b" y "d" en minuscula, que es
-- la representacion habitual en un display de 7 segmentos.
entity dec_7seg is
    port (
        bin : in  std_logic_vector(3 downto 0);
        seg : out std_logic_vector(6 downto 0)
    );
end dec_7seg;

architecture rtl of dec_7seg is
begin

    process (bin)
    begin
        case bin is
            when "0000" => seg <= "0111111";  -- 0
            when "0001" => seg <= "0000110";  -- 1
            when "0010" => seg <= "1011011";  -- 2
            when "0011" => seg <= "1001111";  -- 3
            when "0100" => seg <= "1100110";  -- 4
            when "0101" => seg <= "1101101";  -- 5
            when "0110" => seg <= "1111101";  -- 6
            when "0111" => seg <= "0000111";  -- 7
            when "1000" => seg <= "1111111";  -- 8
            when "1001" => seg <= "1101111";  -- 9
            when "1010" => seg <= "1110111";  -- A
            when "1011" => seg <= "1111100";  -- b
            when "1100" => seg <= "0111001";  -- C
            when "1101" => seg <= "1011110";  -- d
            when "1110" => seg <= "1111001";  -- E
            when "1111" => seg <= "1110001";  -- F
            -- Cubre los valores metaestables ('U', 'X', ...) del primer
            -- delta de simulacion y cualquier valor fuera de 0..15.
            when others => seg <= (others => '0');
        end case;
    end process;

end rtl;
