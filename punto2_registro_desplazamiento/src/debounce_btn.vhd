library ieee;
use ieee.std_logic_1164.all;

-- Antirrebote generico para pulsadores.
--
-- La entrada se sincroniza con dos biestables y solo se acepta un cambio
-- cuando se mantiene estable durante DB_MS milisegundos. La salida level
-- entrega el estado ya filtrado (util para un reset) y pulse entrega un
-- unico pulso de un ciclo de reloj en cada flanco de subida del pulsador
-- (util como reloj habilitado).
--
-- ACTIVE_LOW = true para pulsadores con pull-up (activos en bajo).
-- ACTIVE_LOW = false para pulsadores con pull-down (activos en alto).
entity debounce_btn is
    generic (
        CLK_HZ     : integer := 50_000_000;
        DB_MS      : integer := 20;
        ACTIVE_LOW : boolean := false
    );
    port (
        clk   : in  std_logic;
        btn   : in  std_logic;
        level : out std_logic;
        pulse : out std_logic
    );
end debounce_btn;

architecture rtl of debounce_btn is

    constant MS_CYCLES : integer := CLK_HZ / 1000;

    signal cnt_ms   : integer range 0 to MS_CYCLES - 1 := 0;
    signal tick_ms  : std_logic := '0';

    signal sync0    : std_logic := '0';
    signal sync1    : std_logic := '0';
    signal btn_i    : std_logic;

    signal filtrado : std_logic := '0';
    signal cont     : integer range 0 to DB_MS := 0;
    signal pulso_r  : std_logic := '0';

begin

    -- Adaptacion de polaridad
    btn_i <= not btn when ACTIVE_LOW else btn;

    process (clk)
    begin
        if rising_edge(clk) then
            -- Base de tiempo de 1 ms
            if cnt_ms = MS_CYCLES - 1 then
                cnt_ms  <= 0;
                tick_ms <= '1';
            else
                cnt_ms  <= cnt_ms + 1;
                tick_ms <= '0';
            end if;

            -- Sincronizacion de la entrada asincrona
            sync0 <= btn_i;
            sync1 <= sync0;

            pulso_r <= '0';

            if tick_ms = '1' then
                if sync1 = filtrado then
                    -- Mismo estado: reinicia el contador de estabilidad
                    cont <= 0;
                elsif cont = DB_MS - 1 then
                    -- Estado estable durante DB_MS: se acepta
                    filtrado <= sync1;
                    cont     <= 0;
                    if sync1 = '1' then
                        pulso_r <= '1';
                    end if;
                else
                    cont <= cont + 1;
                end if;
            end if;
        end if;
    end process;

    level <= filtrado;
    pulse <= pulso_r;

end rtl;
