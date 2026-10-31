library ieee;
use ieee.std_logic_1164.all;

-- Practica 1, punto 2: registro de desplazamiento de 8 bits.
--
-- Entradas:
--   * din    : dato serie, 1 bit del DIP switch 1.
--   * enable : habilitacion del desplazamiento, 1 bit del DIP switch 1.
--   * btn_clk: pulsador de reloj; se antirrebota y genera un unico pulso
--              por pulsacion.
--   * btn_rst: pulsador de reset; se antirrebota y su nivel se usa como
--              reset sincrono activo alto.
--
-- Salidas:
--   * led(7..0): una salida por cada etapa del registro, conectada a la
--                barra de LEDs 1 de la tarjeta (activa alta).
--
-- El registro se relojiza con el reloj de 50 MHz de la placa y el pulso
-- antirrebotado del pulsador actua como habilitacion de un solo ciclo.
-- Asi se evita usar un pulsador directamente como reloj digital.
entity Punto2_Registro is
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
end Punto2_Registro;

architecture rtl of Punto2_Registro is

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

    component registro_desplazamiento is
        port (
            clk    : in  std_logic;
            rst    : in  std_logic;
            enable : in  std_logic;
            din    : in  std_logic;
            q      : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk_pulse : std_logic;
    signal rst_level : std_logic;

    -- Sincronizacion de los bits del DIP switch
    signal din_meta, din_sync       : std_logic := '0';
    signal enable_meta, enable_sync : std_logic := '0';

    signal enable_pulse : std_logic;

begin

    -- Dos biestables para las entradas asincronas del DIP switch
    process (clk)
    begin
        if rising_edge(clk) then
            din_meta    <= din;
            din_sync    <= din_meta;
            enable_meta <= enable;
            enable_sync <= enable_meta;
        end if;
    end process;

    -- Un pulso de reloj solo desplaza si el enable esta activo
    enable_pulse <= clk_pulse and enable_sync;

    u_db_clk : debounce_btn
        generic map (
            CLK_HZ     => CLK_HZ,
            DB_MS      => DB_MS,
            ACTIVE_LOW => BTN_ACTIVO_BAJO
        )
        port map (
            clk   => clk,
            btn   => btn_clk,
            level => open,
            pulse => clk_pulse
        );

    u_db_rst : debounce_btn
        generic map (
            CLK_HZ     => CLK_HZ,
            DB_MS      => DB_MS,
            ACTIVE_LOW => BTN_ACTIVO_BAJO
        )
        port map (
            clk   => clk,
            btn   => btn_rst,
            level => rst_level,
            pulse => open
        );

    u_reg : registro_desplazamiento
        port map (
            clk    => clk,
            rst    => rst_level,
            enable => enable_pulse,
            din    => din_sync,
            q      => led
        );

end rtl;
