library ieee;
use ieee.std_logic_1164.all;

-- Genera dos ticks a partir del reloj de la placa:
--   tick_ms   : 1 kHz  -> base de tiempo para el antirrebote
--   tick_giro : 20 Hz  -> velocidad de giro de la ruleta
entity div_frecuencia is
    generic (
        CLK_HZ  : integer := 50_000_000;
        SPIN_HZ : integer := 20
    );
    port (
        clk       : in  std_logic;
        tick_ms   : out std_logic;
        tick_giro : out std_logic
    );
end div_frecuencia;

architecture rtl of div_frecuencia is
    constant MS_CYCLES   : integer := CLK_HZ / 1000;
    constant SPIN_CYCLES : integer := CLK_HZ / SPIN_HZ;

    signal cnt_ms   : integer range 0 to MS_CYCLES - 1   := 0;
    signal cnt_giro : integer range 0 to SPIN_CYCLES - 1 := 0;
begin

    -- Tick de 1 ms
    process (clk)
    begin
        if rising_edge(clk) then
            if cnt_ms = MS_CYCLES - 1 then
                cnt_ms  <= 0;
                tick_ms <= '1';
            else
                cnt_ms  <= cnt_ms + 1;
                tick_ms <= '0';
            end if;
        end if;
    end process;

    -- Tick de giro (20 Hz por defecto)
    process (clk)
    begin
        if rising_edge(clk) then
            if cnt_giro = SPIN_CYCLES - 1 then
                cnt_giro  <= 0;
                tick_giro <= '1';
            else
                cnt_giro  <= cnt_giro + 1;
                tick_giro <= '0';
            end if;
        end if;
    end process;

end rtl;
