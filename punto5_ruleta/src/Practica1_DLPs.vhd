library ieee;
use ieee.std_logic_1164.all;

-- Practica 1: nivel superior integrado
--
-- Instancia en paralelo:
--   * ruleta          -> punto 5 (display de 7 segmentos y 3 LEDs)
--   * display_mux     -> barrido de los 4 digitos (ruleta, A, B, C)
--   * Punto2_Registro -> punto 2 (registro de desplazamiento de 8 bits)
--
-- La prueba de componentes quedo deshabilitada; su codigo se conserva en
-- legacy/ y sus pines se reutilizan para el punto 2:
--
--   * DIP switch 1, bit 0 -> dato serie
--   * DIP switch 1, bit 1 -> enable
--   * btn 3               -> reloj antirrebotado
--   * btn 4               -> reset antirrebotado
--   * barra de LEDs 1     -> salidas de las 8 etapas
--
-- El reset de encendido (~1 ms) se genera aqui y se distribuye a ruleta y
-- display_mux. El registro del punto 2 usa el reset del pulsador btn 4.
entity Practica1_DLPs is
    generic (
        CLK_HZ          : integer := 50_000_000;  -- Reloj de la placa (PIN_17)
        DB_MS           : integer := 20;          -- Tiempo de antirrebote [ms]
        SPIN_HZ         : integer := 20;          -- Velocidad de giro de la ruleta [Hz]
        DIGIT_HZ        : integer := 1000;        -- Barrido de cada digito [Hz]
        BTN_ACTIVO_BAJO : boolean := false        -- Pulsadores de prueba: activo alto
    );
    port (
        clk   : in  std_logic;
        btn_n : in  std_logic;                          -- Pulsador de la ruleta, activo bajo (pull-up)
        seg   : out std_logic_vector(6 downto 0);       -- Segmentos A..G (multiplexados)
        dig   : out std_logic_vector(3 downto 0);       -- Habilitacion de los 4 digitos
        led_n : out std_logic_vector(2 downto 0);       -- LEDs D2, D4, D5 (activo bajo)

        dip1  : in  std_logic_vector(1 downto 0);       -- DIP switch 1: bit 0 = dato, bit 1 = enable
        btn3  : in  std_logic;                          -- Pulsador 3: reloj del registro
        btn4  : in  std_logic;                          -- Pulsador 4: reset del registro
        bar1  : out std_logic_vector(7 downto 0)        -- Barra de LEDs 1: etapas del registro
    );
end Practica1_DLPs;

architecture rtl of Practica1_DLPs is

    component ruleta is
        generic (
            CLK_HZ  : integer := 50_000_000;
            DB_MS   : integer := 20;
            SPIN_HZ : integer := 20
        );
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            btn_n : in  std_logic;
            seg   : out std_logic_vector(6 downto 0);
            led_n : out std_logic_vector(2 downto 0)
        );
    end component;

    component display_mux is
        generic (
            CLK_HZ   : integer := 50_000_000;
            DIGIT_HZ : integer := 1000
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            seg_ruleta : in  std_logic_vector(6 downto 0);
            seg        : out std_logic_vector(6 downto 0);
            dig        : out std_logic_vector(3 downto 0)
        );
    end component;

    component Punto2_Registro is
        generic (
            CLK_HZ          : integer := 50_000_000;
            DB_MS           : integer := 20;
            BTN_ACTIVO_BAJO : boolean := false
        );
        port (
            clk     : in  std_logic;
            btn_clk : in  std_logic;
            btn_rst : in  std_logic;
            din     : in  std_logic;
            enable  : in  std_logic;
            led     : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Reset interno de encendido (~1 ms)
    constant POR_CYCLES : integer := CLK_HZ / 1000;

    signal rst     : std_logic := '1';
    signal por_cnt : integer range 0 to POR_CYCLES := 0;

    signal seg_ruleta : std_logic_vector(6 downto 0);

begin

    -- Reset de encendido: mantiene rst='1' durante 1 ms
    process (clk)
    begin
        if rising_edge(clk) then
            if por_cnt < POR_CYCLES then
                por_cnt <= por_cnt + 1;
                rst     <= '1';
            else
                rst     <= '0';
            end if;
        end if;
    end process;

    -- Punto 5: ruleta de 8 resultados
    u_ruleta : ruleta
        generic map (
            CLK_HZ  => CLK_HZ,
            DB_MS   => DB_MS,
            SPIN_HZ => SPIN_HZ
        )
        port map (
            clk   => clk,
            rst   => rst,
            btn_n => btn_n,
            seg   => seg_ruleta,
            led_n => led_n
        );

    -- Multiplexado del display: digito 3 = ruleta, digitos 4..6 = A, B, C
    u_display : display_mux
        generic map (
            CLK_HZ   => CLK_HZ,
            DIGIT_HZ => DIGIT_HZ
        )
        port map (
            clk        => clk,
            rst        => rst,
            seg_ruleta => seg_ruleta,
            seg        => seg,
            dig        => dig
        );

    -- Punto 2: registro de desplazamiento de 8 bits.
    -- DIP switch 1: bit 0 = din, bit 1 = enable.
    -- btn 3 (pin 100) = reloj, btn 4 (pin 97) = reset.
    -- barra de LEDs 1 = q(7..0).
    u_registro : Punto2_Registro
        generic map (
            CLK_HZ          => CLK_HZ,
            DB_MS           => DB_MS,
            BTN_ACTIVO_BAJO => BTN_ACTIVO_BAJO
        )
        port map (
            clk     => clk,
            btn_clk => btn3,
            btn_rst => btn4,
            din     => dip1(0),
            enable  => dip1(1),
            led     => bar1
        );

end rtl;
