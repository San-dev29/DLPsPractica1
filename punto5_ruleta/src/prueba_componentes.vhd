library ieee;
use ieee.std_logic_1164.all;

-- Modulo de prueba de componentes: DIP switches, barras de LEDs y
-- pulsadores. El modo se selecciona con un pulsador y queda memorizado
-- (no hace falta mantenerlo presionado):
--
--   btn1 -> modo 1: bar1 = dip1 y bar2 = dip2 (conexion directa)
--   btn2 -> modo 2: las dos barras parpadean a BLINK_HZ
--   btn3 -> modo 3: las dos barras permanecen encendidas
--   btn4 -> modo 4: igual que el modo 1 pero intercambiando entradas:
--                   bar1 = dip2 y bar2 = dip1
--
-- Tras el reset el modo es 0 (barras apagadas).
-- Polaridad (segun la especificacion de hardware de la placa):
--   * DIP switches y pulsadores: activo alto (pull-down).
--   * Barras de LEDs: activo alto.
entity prueba_componentes is
    generic (
        CLK_HZ   : integer := 50_000_000;  -- Reloj de la placa
        DB_MS    : integer := 20;          -- Tiempo de antirrebote [ms]
        BLINK_HZ : integer := 2            -- Frecuencia de parpadeo [Hz]
    );
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;                          -- Reset sincrono, activo alto
        dip1 : in  std_logic_vector(7 downto 0);       -- DIP switch 1
        dip2 : in  std_logic_vector(7 downto 0);       -- DIP switch 2
        btn1 : in  std_logic;                          -- Pulsadores, activo alto
        btn2 : in  std_logic;
        btn3 : in  std_logic;
        btn4 : in  std_logic;
        bar1 : out std_logic_vector(7 downto 0);       -- Barra de LEDs 1
        bar2 : out std_logic_vector(7 downto 0)        -- Barra de LEDs 2
    );
end prueba_componentes;

architecture rtl of prueba_componentes is

    -- Cambiar a true si el hardware entrega la logica invertida.
    constant DIP_ACTIVO_BAJO : boolean := false;
    constant BTN_ACTIVO_BAJO : boolean := false;

    component div_frecuencia is
        generic (
            CLK_HZ  : integer := 50_000_000;
            SPIN_HZ : integer := 20
        );
        port (
            clk       : in  std_logic;
            tick_ms   : out std_logic;
            tick_giro : out std_logic
        );
    end component;

    component antirrebote is
        generic (
            N_MS : integer := 20
        );
        port (
            clk     : in  std_logic;
            tick_ms : in  std_logic;
            btn_n   : in  std_logic;
            pulso   : out std_logic
        );
    end component;

    signal dip1_i : std_logic_vector(7 downto 0);
    signal dip2_i : std_logic_vector(7 downto 0);

    signal btn1_n : std_logic;
    signal btn2_n : std_logic;
    signal btn3_n : std_logic;
    signal btn4_n : std_logic;

    signal tick_ms    : std_logic;
    signal tick_blink : std_logic;

    signal p1 : std_logic;
    signal p2 : std_logic;
    signal p3 : std_logic;
    signal p4 : std_logic;

    signal modo     : integer range 0 to 4 := 0;
    signal parpadeo : std_logic := '0';

begin

    -- Adaptacion de polaridad al bloque antirrebote (que espera activo bajo)
    dip1_i <= not dip1 when DIP_ACTIVO_BAJO else dip1;
    dip2_i <= not dip2 when DIP_ACTIVO_BAJO else dip2;

    btn1_n <= not btn1 when not BTN_ACTIVO_BAJO else btn1;
    btn2_n <= not btn2 when not BTN_ACTIVO_BAJO else btn2;
    btn3_n <= not btn3 when not BTN_ACTIVO_BAJO else btn3;
    btn4_n <= not btn4 when not BTN_ACTIVO_BAJO else btn4;

    -- Seleccion de modo: el ultimo pulsador que se presiona gana.
    -- Ante pulsaciones simultaneas se prioriza btn1 > btn2 > btn3 > btn4.
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                modo <= 0;
            elsif p1 = '1' then
                modo <= 1;
            elsif p2 = '1' then
                modo <= 2;
            elsif p3 = '1' then
                modo <= 3;
            elsif p4 = '1' then
                modo <= 4;
            end if;
        end if;
    end process;

    -- Base de tiempo: tick_ms para los antirrebotes y tick_blink para el
    -- parpadeo. El divisor entrega un tick cada CLK_HZ/SPIN_HZ ciclos; para
    -- obtener BLINK_HZ ciclos completos por segundo (encendido + apagado)
    -- se necesita un tick al doble de esa frecuencia.
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                parpadeo <= '0';
            elsif tick_blink = '1' then
                parpadeo <= not parpadeo;
            end if;
        end if;
    end process;

    -- Salidas combinacionales segun el modo seleccionado
    process (dip1_i, dip2_i, modo, parpadeo)
    begin
        case modo is
            when 1 =>
                bar1 <= dip1_i;
                bar2 <= dip2_i;
            when 2 =>
                bar1 <= (others => parpadeo);
                bar2 <= (others => parpadeo);
            when 3 =>
                bar1 <= (others => '1');
                bar2 <= (others => '1');
            when 4 =>
                bar1 <= dip2_i;
                bar2 <= dip1_i;
            when others =>
                bar1 <= (others => '0');
                bar2 <= (others => '0');
        end case;
    end process;

    u_div : div_frecuencia
        generic map (
            CLK_HZ  => CLK_HZ,
            SPIN_HZ => 2 * BLINK_HZ
        )
        port map (
            clk       => clk,
            tick_ms   => tick_ms,
            tick_giro => tick_blink
        );

    u_db1 : antirrebote
        generic map (N_MS => DB_MS)
        port map (clk => clk, tick_ms => tick_ms, btn_n => btn1_n, pulso => p1);

    u_db2 : antirrebote
        generic map (N_MS => DB_MS)
        port map (clk => clk, tick_ms => tick_ms, btn_n => btn2_n, pulso => p2);

    u_db3 : antirrebote
        generic map (N_MS => DB_MS)
        port map (clk => clk, tick_ms => tick_ms, btn_n => btn3_n, pulso => p3);

    u_db4 : antirrebote
        generic map (N_MS => DB_MS)
        port map (clk => clk, tick_ms => tick_ms, btn_n => btn4_n, pulso => p4);

end rtl;
