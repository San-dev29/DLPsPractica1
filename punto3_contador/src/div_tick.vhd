library ieee;
use ieee.std_logic_1164.all;

-- Genera un pulso de un ciclo de reloj a TICK_HZ.
-- Se usa como habilitacion del contador para que el conteo sea visible
-- en el display (2 Hz por defecto).
entity div_tick is
    generic (
        CLK_HZ  : integer := 50_000_000;  -- Reloj de la placa (PIN_17)
        TICK_HZ : integer := 2            -- Frecuencia del pulso de conteo [Hz]
    );
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;            -- Reset asincrono, activo bajo
        tick  : out std_logic
    );
end div_tick;

architecture rtl of div_tick is
    constant CICLOS : integer := CLK_HZ / TICK_HZ;

    signal cont   : integer range 0 to CICLOS - 1 := 0;
    signal tick_r : std_logic := '0';
begin

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            cont   <= 0;
            tick_r <= '0';
        elsif rising_edge(clk) then
            if cont = CICLOS - 1 then
                cont   <= 0;
                tick_r <= '1';
            else
                cont   <= cont + 1;
                tick_r <= '0';
            end if;
        end if;
    end process;

    tick <= tick_r;

end rtl;
