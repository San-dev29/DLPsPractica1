library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Modulo ruleta: 8 resultados (1..8) en un display de 7 segmentos.
--
-- Funcionamiento:
--   * En reposo el display muestra el ultimo valor obtenido.
--   * Una pulsacion de btn_n (activo bajo) arranca el giro: los numeros
--     1..8 se muestran de forma continua.
--   * Una segunda pulsacion detiene la ruleta y el display queda fijo
--     en el numero obtenido.
--
-- El reset (rst) lo genera el nivel superior, de modo que este modulo
-- pueda reutilizarse dentro de otro diseno.
entity ruleta is
    generic (
        CLK_HZ  : integer := 50_000_000;  -- Reloj de la placa (PIN_17)
        DB_MS   : integer := 20;          -- Tiempo de antirrebote [ms]
        SPIN_HZ : integer := 20           -- Velocidad de giro [Hz]
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;                          -- Reset sincrono, activo alto
        btn_n : in  std_logic;                          -- Pulsador, activo bajo
        seg   : out std_logic_vector(6 downto 0);       -- Segmentos A..G
        led_n : out std_logic_vector(2 downto 0)        -- LEDs D2, D4, D5 (activo bajo)
    );
end ruleta;

architecture rtl of ruleta is

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

    component control_ruleta is
        port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            pulso   : in  std_logic;
            running : out std_logic
        );
    end component;

    component lfsr8 is
        port (
            clk  : in  std_logic;
            tick : in  std_logic;
            load : in  std_logic;
            seed : in  std_logic_vector(7 downto 0);
            q    : out std_logic_vector(7 downto 0)
        );
    end component;

    component BinSieteseg is
        port (
            A : in  std_logic_vector(3 downto 0);
            s : in  std_logic;
            d : out std_logic_vector(7 downto 0)
        );
    end component;

    signal libre     : unsigned(23 downto 0) := (others => '0');

    signal tick_ms   : std_logic;
    signal tick_giro : std_logic;
    signal tick_act  : std_logic;

    signal pulso     : std_logic;
    signal running   : std_logic;
    signal arranque  : std_logic;

    signal q_lfsr    : std_logic_vector(7 downto 0);
    signal seed      : std_logic_vector(7 downto 0);
    signal valor     : std_logic_vector(3 downto 0);
    signal seg_full  : std_logic_vector(7 downto 0);

begin

    -- Contador libre de 50 MHz: fuente de semilla aleatoria
    process (clk)
    begin
        if rising_edge(clk) then
            libre <= libre + 1;
        end if;
    end process;

    seed <= std_logic_vector(libre(15 downto 8));

    -- Solo se avanza el LFSR mientras la ruleta gira
    tick_act <= tick_giro and running;

    -- Un pulso del boton con la ruleta detenida produce un arranque
    arranque <= pulso and (not running);

    -- Numero visible: 1..8 en 4 bits (0 -> 1 ... 7 -> 8)
    valor <= std_logic_vector(unsigned('0' & q_lfsr(2 downto 0)) + 1);

    -- LEDs: espejo binario invertido (activos en bajo).
    -- Nota: al ser solo 3 LEDs, el valor 8 se muestra como "000".
    led_n <= not valor(2 downto 0);

    seg <= seg_full(6 downto 0);  -- DP no se utiliza (conflicto con LED D2)

    u_div : div_frecuencia
        generic map (
            CLK_HZ  => CLK_HZ,
            SPIN_HZ => SPIN_HZ
        )
        port map (
            clk       => clk,
            tick_ms   => tick_ms,
            tick_giro => tick_giro
        );

    u_db : antirrebote
        generic map (
            N_MS => DB_MS
        )
        port map (
            clk     => clk,
            tick_ms => tick_ms,
            btn_n   => btn_n,
            pulso   => pulso
        );

    u_ctrl : control_ruleta
        port map (
            clk     => clk,
            rst     => rst,
            pulso   => pulso,
            running => running
        );

    u_lfsr : lfsr8
        port map (
            clk  => clk,
            tick => tick_act,
            load => arranque,
            seed => seed,
            q    => q_lfsr
        );

    u_dec : BinSieteseg
        port map (
            A => valor,
            s => '0',  -- Segmentos activo alto
            d => seg_full
        );

end rtl;
