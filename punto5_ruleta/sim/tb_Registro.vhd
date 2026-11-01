library ieee;
use ieee.std_logic_1164.all;

-- Testbench del punto 2 integrado en el nivel superior Practica1_DLPs.
--
-- Se controla el registro a traves de los pines reales del diseno:
--   * DIP switch 1, bit 0 -> din
--   * DIP switch 1, bit 1 -> enable
--   * btn 3 (pin 100)     -> reloj antirrebotado
--   * btn 4 (pin 97)      -> reset antirrebotado
--   * barra de LEDs 1     -> q(7..0)
--
-- La ruleta se mantiene detenida (btn_n='1') y el contador del punto 3 se
-- mantiene apagado (dip1(3)='0' y sin pulsar start) para no interferir.
entity tb_Registro is
end tb_Registro;

architecture sim of tb_Registro is

    constant CLK_HZ  : integer := 10_000;          -- Reloj lento para simular
    constant CLK_PER : time    := 1 sec / CLK_HZ;  -- 100 us

    signal clk   : std_logic := '0';
    signal btn_n : std_logic := '1';               -- Ruleta detenida
    signal seg   : std_logic_vector(6 downto 0);
    signal dig   : std_logic_vector(3 downto 0);
    signal led_n : std_logic_vector(2 downto 0);

    signal dip1 : std_logic_vector(3 downto 0) := "0000";
    signal btn1 : std_logic := '0';   -- Reset del contador P3 (sin usar)
    signal btn2 : std_logic := '0';   -- Start del contador P3 (sin usar)
    signal btn3 : std_logic := '0';
    signal btn4 : std_logic := '0';
    signal bar1 : std_logic_vector(7 downto 0);

    signal fin : boolean := false;

begin

    clk <= not clk after CLK_PER / 2 when not fin;

    dut : entity work.Practica1_DLPs
        generic map (
            CLK_HZ          => CLK_HZ,
            DB_MS           => 5,
            SPIN_HZ         => 20,
            DIGIT_HZ        => 1000,
            TICK_HZ         => 2,
            BTN_ACTIVO_BAJO => false
        )
        port map (
            clk   => clk,
            btn_n => btn_n,
            seg   => seg,
            dig   => dig,
            led_n => led_n,
            dip1  => dip1,
            btn1  => btn1,
            btn2  => btn2,
            btn3  => btn3,
            btn4  => btn4,
            bar1  => bar1
        );

    proceso_pruebas : process
        procedure pulso_clk is
        begin
            btn3 <= '1';
            wait for 10 ms;
            btn3 <= '0';
            wait for 10 ms;
        end procedure;
    begin

        wait for 10 ms;

        ---------------------------------------------------------------
        -- PRUEBA 1: reset con btn 4
        ---------------------------------------------------------------
        btn4 <= '1';
        wait for 10 ms;
        assert bar1 = X"00"
            report "FALLO T1: el reset no limpia el registro"
            severity error;
        btn4 <= '0';
        wait for 10 ms;
        report "T1 OK: btn 4 limpia el registro" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: enable=0 (DIP 1, bit 1) no permite desplazar
        ---------------------------------------------------------------
        dip1(1) <= '0';
        dip1(0) <= '1';
        pulso_clk;
        assert bar1 = X"00"
            report "FALLO T2: el registro se desplazo con enable=0"
            severity error;
        report "T2 OK: enable=0 bloquea el desplazamiento" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: entrada serie de 8 bits por DIP 1, bit 0
        -- Secuencia: 1, 0, 1, 1, 0, 0, 1, 0
        -- Resultado esperado (q7..q0): 1011 0010 = 0xB2
        ---------------------------------------------------------------
        dip1(1) <= '1';

        dip1(0) <= '1'; wait for 1 ms; pulso_clk;
        assert bar1 = X"01"
            report "FALLO T3: primer bit mal desplazado"
            severity error;

        dip1(0) <= '0'; wait for 1 ms; pulso_clk;
        assert bar1 = X"02"
            report "FALLO T3: segundo bit mal desplazado"
            severity error;

        dip1(0) <= '1'; wait for 1 ms; pulso_clk;
        assert bar1 = X"05"
            report "FALLO T3: tercer bit mal desplazado"
            severity error;

        dip1(0) <= '1'; wait for 1 ms; pulso_clk;
        assert bar1 = X"0B"
            report "FALLO T3: cuarto bit mal desplazado"
            severity error;

        dip1(0) <= '0'; wait for 1 ms; pulso_clk;
        assert bar1 = X"16"
            report "FALLO T3: quinto bit mal desplazado"
            severity error;

        dip1(0) <= '0'; wait for 1 ms; pulso_clk;
        assert bar1 = X"2C"
            report "FALLO T3: sexto bit mal desplazado"
            severity error;

        dip1(0) <= '1'; wait for 1 ms; pulso_clk;
        assert bar1 = X"59"
            report "FALLO T3: septimo bit mal desplazado"
            severity error;

        dip1(0) <= '0'; wait for 1 ms; pulso_clk;
        assert bar1 = X"B2"
            report "FALLO T3: octavo bit mal desplazado"
            severity error;

        report "T3 OK: 8 bits desplazados, barra 1 = 0xB2"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: enable=0 conserva el contenido
        ---------------------------------------------------------------
        dip1(1) <= '0';
        dip1(0) <= '1';
        pulso_clk;
        assert bar1 = X"B2"
            report "FALLO T4: enable=0 modifico el registro"
            severity error;
        report "T4 OK: enable=0 conserva el contenido" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: reset limpia aunque el registro tenga datos
        ---------------------------------------------------------------
        btn4 <= '1';
        wait for 10 ms;
        assert bar1 = X"00"
            report "FALLO T5: el reset no limpio el registro cargado"
            severity error;
        btn4 <= '0';
        wait for 10 ms;
        report "T5 OK: reset limpia un registro con datos" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 6: el antirrebote produce un solo pulso por pulsacion
        ---------------------------------------------------------------
        dip1(1) <= '1';
        dip1(0) <= '1';
        btn3 <= '1';
        wait for 50 ms;             -- Pulsacion larga: solo debe contar una vez
        btn3 <= '0';
        wait for 20 ms;

        assert bar1 = X"01"
            report "FALLO T6: una pulsacion larga genero varios desplazamientos"
            severity error;
        report "T6 OK: una pulsacion larga genera un solo desplazamiento"
            severity note;

        ---------------------------------------------------------------
        -- Fin de la simulacion
        ---------------------------------------------------------------
        fin <= true;
        assert false report "SIMULACION FINALIZADA CORRECTAMENTE" severity failure;
        wait;
    end process;

end sim;
