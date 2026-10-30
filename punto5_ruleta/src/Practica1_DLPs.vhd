library ieee;
use ieee.std_logic_1164.all;

-- Practica 1: nivel superior
--
-- Instancia de forma modular:
--   * ruleta             -> punto 5 (display de 7 segmentos y 3 LEDs)
--   * prueba_componentes -> DIP switches, barras de LEDs y 4 pulsadores
--
-- El reset de encendido (~1 ms) se genera aqui y se distribuye a los
-- dos modulos.
entity Practica1_DLPs is
    generic (
        CLK_HZ  : integer := 50_000_000;  -- Reloj de la placa (PIN_17)
        DB_MS   : integer := 20;          -- Tiempo de antirrebote [ms]
        SPIN_HZ : integer := 20           -- Velocidad de giro de la ruleta [Hz]
    );
    port (
        clk   : in  std_logic;
        btn_n : in  std_logic;                          -- Pulsador de la ruleta, activo bajo (pull-up)
        seg   : out std_logic_vector(6 downto 0);       -- Segmentos A..G
        led_n : out std_logic_vector(2 downto 0);       -- LEDs D2, D4, D5 (activo bajo)

        dip1  : in  std_logic_vector(7 downto 0);       -- DIP switch 1
        btn1  : in  std_logic;                          -- Pulsadores de prueba de componentes
        btn2  : in  std_logic;
        btn3  : in  std_logic;
        btn4  : in  std_logic;
        bar1  : out std_logic_vector(7 downto 0);       -- Barra de LEDs 1
        bar2  : out std_logic_vector(7 downto 0)        -- Barra de LEDs 2
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

    component prueba_componentes is
        port (
            clk  : in  std_logic;
            dip1 : in  std_logic_vector(7 downto 0);
            btn1 : in  std_logic;
            btn2 : in  std_logic;
            btn3 : in  std_logic;
            btn4 : in  std_logic;
            bar1 : out std_logic_vector(7 downto 0);
            bar2 : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Reset interno de encendido (~1 ms)
    constant POR_CYCLES : integer := CLK_HZ / 1000;

    signal rst     : std_logic := '1';
    signal por_cnt : integer range 0 to POR_CYCLES := 0;

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
            seg   => seg,
            led_n => led_n
        );

    -- Prueba de componentes: DIP switch 1, barras de LEDs y pulsadores
    u_componentes : prueba_componentes
        port map (
            clk  => clk,
            dip1 => dip1,
            btn1 => btn1,
            btn2 => btn2,
            btn3 => btn3,
            btn4 => btn4,
            bar1 => bar1,
            bar2 => bar2
        );

end rtl;
