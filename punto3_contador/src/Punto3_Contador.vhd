library ieee;
use ieee.std_logic_1164.all;

-- Practica 1, punto 3: contador binario de 4 bits ascendente/descendente
-- con salida al display de 7 segmentos (0..F).
--
-- Entradas:
--   * clk   : reloj de la placa, 50 MHz (PIN_17).
--   * rst_n : pulsador de reset, activo bajo (PIN_144, pull-up).
--   * dir   : interruptor de direccion (DIP switch 1, int. 3, PIN_126).
--             1 = cuenta ascendente, 0 = cuenta descendente.
--   * hab   : interruptor de habilitacion / inicio (DIP switch 1, int. 4,
--             PIN_132). 1 = cuenta, 0 = mantiene el valor.
--
-- Salidas:
--   * seg    : segmentos A..G del display, activo alto.
--   * digito : habilita el digito 3 del display (PIN_113), activo alto.
--
-- El contador se relojiza con los 50 MHz de la placa y div_tick genera un
-- pulso de habilitacion de TICK_HZ (2 Hz por defecto) para que el conteo
-- sea visible. El pulsador de reset se antirrebota y se usa como reset
-- asincrono activo bajo. Un reset de encendido de ~1 ms garantiza que el
-- contador arranque en cero.
entity Punto3_Contador is
    generic (
        CLK_HZ  : integer := 50_000_000;  -- Reloj de la placa (PIN_17)
        DB_MS   : integer := 20;          -- Tiempo de antirrebote [ms]
        TICK_HZ : integer := 2            -- Frecuencia de conteo [Hz]
    );
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;                          -- Pulsador, activo bajo
        dir    : in  std_logic;                          -- 1 = ascendente, 0 = descendente
        hab    : in  std_logic;                          -- 1 = habilitado
        seg    : out std_logic_vector(6 downto 0);       -- Segmentos A..G
        digito : out std_logic                           -- Digito 3 del display
    );
end Punto3_Contador;

architecture rtl of Punto3_Contador is

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

    -- Reset de encendido (~1 ms)
    constant POR_CYCLES : integer := CLK_HZ / 1000;

    signal por_cnt : integer range 0 to POR_CYCLES := 0;
    signal rst_n_i : std_logic := '0';

    signal pulsado : std_logic;  -- 1 mientras el pulsador esta presionado
    signal tick    : std_logic;
    signal valor   : std_logic_vector(3 downto 0) := (others => '0');
    signal ena     : std_logic;

    -- Sincronizacion de los interruptores del DIP switch
    signal dir_meta, dir_sync : std_logic := '0';
    signal hab_meta, hab_sync : std_logic := '0';

begin

    -- Reset de encendido combinado con el pulsador antirrebotado.
    -- rst_n_i = '0' mantiene el contador en cero.
    process (clk)
    begin
        if rising_edge(clk) then
            if por_cnt < POR_CYCLES then
                por_cnt <= por_cnt + 1;
                rst_n_i <= '0';
            else
                rst_n_i <= not pulsado;
            end if;
        end if;
    end process;

    -- Dos biestables para las entradas asincronas del DIP switch
    process (clk)
    begin
        if rising_edge(clk) then
            dir_meta <= dir;
            dir_sync <= dir_meta;
            hab_meta <= hab;
            hab_sync <= hab_meta;
        end if;
    end process;

    -- Solo se cuenta durante el pulso de tick y con la habilitacion activa
    ena <= tick and hab_sync;

    -- Base de tiempo visible: un pulso cada 1/TICK_HZ segundos
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

    -- Contador de 4 bits
    u_cnt : contador_ud
        generic map (
            ANCHO => 4
        )
        port map (
            clk   => clk,
            rst_n => rst_n_i,
            ena   => ena,
            dir   => dir_sync,
            q     => valor
        );

    -- Decodificacion binario -> 7 segmentos
    u_dec : dec_7seg
        port map (
            bin => valor,
            seg => seg
        );

    -- Antirrebote del pulsador de reset (activo bajo). La salida level
    -- se normaliza a "presionado = 1" y luego se invierte para rst_n_i.
    u_db_rst : debounce_btn
        generic map (
            CLK_HZ     => CLK_HZ,
            DB_MS      => DB_MS,
            ACTIVE_LOW => true
        )
        port map (
            clk   => clk,
            btn   => rst_n,
            level => pulsado,
            pulse => open
        );

    -- El display de la placa es multiplexado; este diseno usa solo el
    -- digito 3, que se deja habilitado permanentemente.
    digito <= '1';

end rtl;
