library ieee;
use ieee.std_logic_1164.all;

-- Practica 1: nivel superior integrado
--
-- Instancia en paralelo:
--   * ruleta          -> punto 5 (ruleta 1..8 y LEDs D2/D4/D5)
--   * display_mux     -> barrido de los digitos 3 (ruleta) y 4 (contador)
--   * Punto2_Registro -> punto 2 (registro de desplazamiento de 8 bits)
--   * Contador_P3     -> punto 3 (contador binario de 4 bits 0..F)
--
-- Distribucion de controles:
--   * DIP switch 1, int. 1 (pin 120) -> dato serie del punto 2
--   * DIP switch 1, int. 2 (pin 122) -> enable del punto 2
--   * DIP switch 1, int. 3 (pin 126) -> direccion del punto 3
--   * DIP switch 1, int. 4 (pin 132) -> habilitacion del punto 3
--   * btn 1 (pin 74)                 -> reset del punto 3
--   * btn 2 (pin 75)                 -> start del punto 3
--   * btn 3 (pin 100)                -> reloj del punto 2
--   * btn 4 (pin 97)                 -> reset del punto 2
--   * pulsador del pin 144           -> ruleta (punto 5)
--
-- Display multiplexado:
--   * digito 3 (pin 113) -> valor de la ruleta
--   * digito 4 (pin 115) -> contador del punto 3 en hexadecimal (0..F)
--   * digitos 5 y 6      -> apagados
--
-- El reset de encendido (~1 ms) se genera aqui y se distribuye a la
-- ruleta, al display y al contador. El registro del punto 2 usa el reset
-- del pulsador btn 4.
entity Practica1_DLPs is
    generic (
        CLK_HZ          : integer := 50_000_000;  -- Reloj de la placa (PIN_17)
        DB_MS           : integer := 20;          -- Tiempo de antirrebote [ms]
        SPIN_HZ         : integer := 20;          -- Velocidad de giro de la ruleta [Hz]
        DIGIT_HZ        : integer := 1000;        -- Barrido de cada digito [Hz]
        TICK_HZ         : integer := 2;           -- Frecuencia del contador [Hz]
        BTN_ACTIVO_BAJO : boolean := false        -- Pulsadores de prueba: activo alto
    );
    port (
        clk   : in  std_logic;
        btn_n : in  std_logic;                          -- Pulsador de la ruleta, activo bajo (pull-up)
        seg   : out std_logic_vector(6 downto 0);       -- Segmentos A..G (multiplexados)
        dig   : out std_logic_vector(3 downto 0);       -- Habilitacion de los digitos
        led_n : out std_logic_vector(2 downto 0);       -- LEDs D2, D4, D5 (activo bajo)

        dip1  : in  std_logic_vector(3 downto 0);       -- DIP 1: P2 (0,1) y P3 (2,3)
        btn1  : in  std_logic;                          -- Pulsador 1: reset del contador P3
        btn2  : in  std_logic;                          -- Pulsador 2: start del contador P3
        btn3  : in  std_logic;                          -- Pulsador 3: reloj del registro P2
        btn4  : in  std_logic;                          -- Pulsador 4: reset del registro P2
        bar1  : out std_logic_vector(7 downto 0)        -- Barra de LEDs 1: etapas del registro P2
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
            seg_cont   : in  std_logic_vector(6 downto 0);
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

    component Contador_P3 is
        generic (
            CLK_HZ  : integer := 50_000_000;
            DB_MS   : integer := 20;
            TICK_HZ : integer := 2
        );
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            btn_rst   : in  std_logic;
            btn_start : in  std_logic;
            dir       : in  std_logic;
            ena       : in  std_logic;
            valor     : out std_logic_vector(3 downto 0);
            seg       : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Reset interno de encendido (~1 ms)
    constant POR_CYCLES : integer := CLK_HZ / 1000;

    signal rst     : std_logic := '1';
    signal por_cnt : integer range 0 to POR_CYCLES := 0;

    signal seg_ruleta  : std_logic_vector(6 downto 0);
    signal seg_contador : std_logic_vector(6 downto 0);

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

    -- Multiplexado del display: digito 3 = ruleta, digito 4 = contador P3
    u_display : display_mux
        generic map (
            CLK_HZ   => CLK_HZ,
            DIGIT_HZ => DIGIT_HZ
        )
        port map (
            clk        => clk,
            rst        => rst,
            seg_ruleta => seg_ruleta,
            seg_cont   => seg_contador,
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

    -- Punto 3: contador binario de 4 bits.
    -- DIP switch 1, int. 3 (pin 126) = direccion.
    -- DIP switch 1, int. 4 (pin 132) = habilitacion.
    -- btn 1 (pin 74) = reset, btn 2 (pin 75) = start.
    -- La salida se muestra en el digito 4 del display.
    u_contador : Contador_P3
        generic map (
            CLK_HZ  => CLK_HZ,
            DB_MS   => DB_MS,
            TICK_HZ => TICK_HZ
        )
        port map (
            clk       => clk,
            rst       => rst,
            btn_rst   => btn1,
            btn_start => btn2,
            dir       => dip1(2),
            ena       => dip1(3),
            valor     => open,
            seg       => seg_contador
        );

end rtl;
