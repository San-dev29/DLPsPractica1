library ieee;
use ieee.std_logic_1164.all;

-- Punto 3 integrado en el proyecto del punto 5.
--
-- Contador binario de 4 bits ascendente/descendente con:
--   * btn_rst   : pulsador de reset, activo alto (pull-down). Borra el
--                 contador y lo detiene.
--   * btn_start : pulsador de arranque, activo alto. Pone run = 1; el
--                 conteo comienza en el siguiente tick.
--   * dir       : 1 = ascendente, 0 = descendente.
--   * ena       : habilitacion maestra. El contador solo avanza si
--                 ena = 1 y run = 1.
--   * rst       : reset de encendido del nivel superior (activo alto).
--
-- El contador se relojiza con los 50 MHz de la placa y div_tick genera
-- un pulso de TICK_HZ para que el conteo sea visible. La salida seg
-- entrega el valor en hexadecimal (0..F) para el display multiplexado.
entity Contador_P3 is
    generic (
        CLK_HZ  : integer := 50_000_000;
        DB_MS   : integer := 20;
        TICK_HZ : integer := 2
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;                          -- Reset de encendido, activo alto
        btn_rst   : in  std_logic;                          -- Pulsador reset, activo alto
        btn_start : in  std_logic;                          -- Pulsador start, activo alto
        dir       : in  std_logic;                          -- 1 = ascendente, 0 = descendente
        ena       : in  std_logic;                          -- Habilitacion maestra
        valor     : out std_logic_vector(3 downto 0);       -- Valor binario del contador
        seg       : out std_logic_vector(6 downto 0)        -- Valor en 7 segmentos
    );
end Contador_P3;

architecture rtl of Contador_P3 is

    component debounce_btn is
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
    end component;

    component div_tick is
        generic (
            CLK_HZ  : integer := 50_000_000;
            TICK_HZ : integer := 2
        );
        port (
            clk   : in  std_logic;
            rst_n : in  std_logic;
            tick  : out std_logic
        );
    end component;

    component contador_ud is
        generic (
            ANCHO : integer := 4
        );
        port (
            clk   : in  std_logic;
            rst_n : in  std_logic;
            ena   : in  std_logic;
            dir   : in  std_logic;
            q     : out std_logic_vector(ANCHO - 1 downto 0)
        );
    end component;

    component dec_7seg is
        port (
            bin : in  std_logic_vector(3 downto 0);
            seg : out std_logic_vector(6 downto 0)
        );
    end component;

    signal rst_level   : std_logic;
    signal start_pulse : std_logic;
    signal rst_n_i     : std_logic;

    signal run     : std_logic := '0';
    signal tick    : std_logic;
    signal ena_int : std_logic;

    -- Sincronizacion de los interruptores del DIP switch
    signal dir_meta, dir_sync : std_logic := '0';
    signal ena_meta, ena_sync : std_logic := '0';

    signal valor_i : std_logic_vector(3 downto 0) := (others => '0');

begin

    -- Reset combinado: encendido o pulsador de reset (ambos activos altos)
    rst_n_i <= not (rst or rst_level);

    -- Dos biestables para las entradas asincronas del DIP switch
    process (clk)
    begin
        if rising_edge(clk) then
            dir_meta <= dir;
            dir_sync <= dir_meta;
            ena_meta <= ena;
            ena_sync <= ena_meta;
        end if;
    end process;

    -- Biestable de arranque: start lo activa, reset lo desactiva.
    -- Una pulsacion larga de start no repite la accion.
    process (clk, rst_n_i)
    begin
        if rst_n_i = '0' then
            run <= '0';
        elsif rising_edge(clk) then
            if start_pulse = '1' then
                run <= '1';
            end if;
        end if;
    end process;

    -- Solo se cuenta con el tick, la habilitacion y el arranque activos
    ena_int <= tick and ena_sync and run;

    u_tick : div_tick
        generic map (
            CLK_HZ  => CLK_HZ,
            TICK_HZ => TICK_HZ
        )
        port map (
            clk   => clk,
            rst_n => rst_n_i,
            tick  => tick
        );

    u_cnt : contador_ud
        generic map (
            ANCHO => 4
        )
        port map (
            clk   => clk,
            rst_n => rst_n_i,
            ena   => ena_int,
            dir   => dir_sync,
            q     => valor_i
        );

    u_dec : dec_7seg
        port map (
            bin => valor_i,
            seg => seg
        );

    -- Pulsador de reset (activo alto, pull-down)
    u_db_rst : debounce_btn
        generic map (
            CLK_HZ     => CLK_HZ,
            DB_MS      => DB_MS,
            ACTIVE_LOW => false
        )
        port map (
            clk   => clk,
            btn   => btn_rst,
            level => rst_level,
            pulse => open
        );

    -- Pulsador de arranque (activo alto, pull-down)
    u_db_start : debounce_btn
        generic map (
            CLK_HZ     => CLK_HZ,
            DB_MS      => DB_MS,
            ACTIVE_LOW => false
        )
        port map (
            clk   => clk,
            btn   => btn_start,
            level => open,
            pulse => start_pulse
        );

    valor <= valor_i;

end rtl;
