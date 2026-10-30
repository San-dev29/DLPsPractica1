library ieee;
use ieee.std_logic_1164.all;

-- Modulo de prueba de componentes: DIP switch 1, barra de LEDs 1,
-- barra de LEDs 2 y cuatro pulsadores.
--
-- Conexion fija (sin modos):
--   * bar1 = dip1                    (los 8 bits del DIP switch 1)
--   * bar2(3..0) = btn4, btn3, btn2, btn1
--   * bar2(7..4) = 0
--
-- Los pulsadores se sincronizan con dos biestables para evitar
-- metaestabilidad. Como el LED refleja directamente el nivel del
-- pulsador, los rebotes solo producen un parpadeo momentaneo.
--
-- Polaridad (segun la especificacion de hardware de la placa):
--   * DIP switch: activo alto (pull-down).
--   * Pulsadores: activo alto (pull-down).
--   * Barras de LEDs: activo alto.
entity prueba_componentes is
    port (
        clk  : in  std_logic;
        dip1 : in  std_logic_vector(7 downto 0);   -- DIP switch 1
        btn1 : in  std_logic;                      -- Pulsadores, activo alto
        btn2 : in  std_logic;
        btn3 : in  std_logic;
        btn4 : in  std_logic;
        bar1 : out std_logic_vector(7 downto 0);   -- Barra de LEDs 1
        bar2 : out std_logic_vector(7 downto 0)    -- Barra de LEDs 2
    );
end prueba_componentes;

architecture rtl of prueba_componentes is

    -- Cambiar a true si el hardware entrega la logica invertida.
    constant DIP_ACTIVO_BAJO : boolean := false;
    constant BTN_ACTIVO_BAJO : boolean := false;

    signal dip1_i : std_logic_vector(7 downto 0);

    signal btn1_i : std_logic;
    signal btn2_i : std_logic;
    signal btn3_i : std_logic;
    signal btn4_i : std_logic;

    -- Sincronizacion de las entradas asincronas
    signal btn1_meta, btn1_sync : std_logic := '0';
    signal btn2_meta, btn2_sync : std_logic := '0';
    signal btn3_meta, btn3_sync : std_logic := '0';
    signal btn4_meta, btn4_sync : std_logic := '0';

begin

    -- Adaptacion de polaridad
    dip1_i <= not dip1 when DIP_ACTIVO_BAJO else dip1;

    btn1_i <= not btn1 when BTN_ACTIVO_BAJO else btn1;
    btn2_i <= not btn2 when BTN_ACTIVO_BAJO else btn2;
    btn3_i <= not btn3 when BTN_ACTIVO_BAJO else btn3;
    btn4_i <= not btn4 when BTN_ACTIVO_BAJO else btn4;

    -- Dos etapas de sincronizacion (entradas asincronas)
    process (clk)
    begin
        if rising_edge(clk) then
            btn1_meta <= btn1_i;
            btn1_sync <= btn1_meta;
            btn2_meta <= btn2_i;
            btn2_sync <= btn2_meta;
            btn3_meta <= btn3_i;
            btn3_sync <= btn3_meta;
            btn4_meta <= btn4_i;
            btn4_sync <= btn4_meta;
        end if;
    end process;

    -- Conexion fija: DIP switch 1 -> barra 1
    bar1 <= dip1_i;

    -- Conexion fija: 4 pulsadores -> 4 LEDs de la barra 2
    bar2 <= "0000" & btn4_sync & btn3_sync & btn2_sync & btn1_sync;

end rtl;
