library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench del punto 2: registro de desplazamiento de 8 bits.
--
-- Se prueba:
--   1. Reset con pulsador.
--   2. Enable en 0 bloquea el desplazamiento.
--   3. Entrada serie de 8 bits y salida paralela correcta.
--   4. El enable en 0 sigue bloqueando despues de haber cargado datos.
--   5. Reset limpia el registro en cualquier momento.
--   6. El antirrebote del pulsador de reloj genera un solo
--      desplazamiento aunque se mantenga presionado.
entity tb_Registro is
end tb_Registro;

architecture sim of tb_Registro is

    constant CLK_HZ  : integer := 10_000;          -- Reloj lento para simular
    constant CLK_PER : time    := 1 sec / CLK_HZ;  -- 100 us

    signal clk     : std_logic := '0';
    signal btn_clk : std_logic := '0';
    signal btn_rst : std_logic := '0';
    signal din     : std_logic := '0';
    signal enable  : std_logic := '0';
    signal led     : std_logic_vector(7 downto 0);
    signal fin     : boolean := false;

begin

    clk <= not clk after CLK_PER / 2 when not fin;

    dut : entity work.Punto2_Registro
        generic map (
            CLK_HZ          => CLK_HZ,
            DB_MS           => 5,
            BTN_ACTIVO_BAJO => false
        )
        port map (
            clk     => clk,
            btn_clk => btn_clk,
            btn_rst => btn_rst,
            din     => din,
            enable  => enable,
            led     => led
        );

    proceso_pruebas : process
        procedure pulso_clk is
        begin
            btn_clk <= '1';
            wait for 10 ms;
            btn_clk <= '0';
            wait for 10 ms;
        end procedure;
    begin

        wait for 10 ms;

        ---------------------------------------------------------------
        -- PRUEBA 1: reset con el pulsador
        ---------------------------------------------------------------
        btn_rst <= '1';
        wait for 10 ms;
        assert led = X"00"
            report "FALLO T1: el reset no limpia el registro"
            severity error;
        btn_rst <= '0';
        wait for 10 ms;
        report "T1 OK: reset limpia el registro" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: enable en 0 no permite desplazar
        ---------------------------------------------------------------
        enable <= '0';
        din    <= '1';
        pulso_clk;
        assert led = X"00"
            report "FALLO T2: el registro se desplazo con enable=0"
            severity error;
        report "T2 OK: enable=0 bloquea el desplazamiento" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: entrada serie de 8 bits
        -- Secuencia: 1, 0, 1, 1, 0, 0, 1, 0
        -- Resultado esperado (q7..q0): 1011 0010 = 0xB2
        ---------------------------------------------------------------
        enable <= '1';

        din <= '1'; wait for 1 ms; pulso_clk;
        assert led = X"01"
            report "FALLO T3: primer bit mal desplazado, led=" &
                   integer'image(to_integer(unsigned(led)))
            severity error;

        din <= '0'; wait for 1 ms; pulso_clk;
        assert led = X"02"
            report "FALLO T3: segundo bit mal desplazado"
            severity error;

        din <= '1'; wait for 1 ms; pulso_clk;
        assert led = X"05"
            report "FALLO T3: tercer bit mal desplazado"
            severity error;

        din <= '1'; wait for 1 ms; pulso_clk;
        assert led = X"0B"
            report "FALLO T3: cuarto bit mal desplazado"
            severity error;

        din <= '0'; wait for 1 ms; pulso_clk;
        assert led = X"16"
            report "FALLO T3: quinto bit mal desplazado"
            severity error;

        din <= '0'; wait for 1 ms; pulso_clk;
        assert led = X"2C"
            report "FALLO T3: sexto bit mal desplazado"
            severity error;

        din <= '1'; wait for 1 ms; pulso_clk;
        assert led = X"59"
            report "FALLO T3: septimo bit mal desplazado"
            severity error;

        din <= '0'; wait for 1 ms; pulso_clk;
        assert led = X"B2"
            report "FALLO T3: octavo bit mal desplazado"
            severity error;

        report "T3 OK: 8 bits desplazados, salida paralela = 0xB2"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: enable en 0 conserva el contenido
        ---------------------------------------------------------------
        enable <= '0';
        din    <= '1';
        pulso_clk;
        assert led = X"B2"
            report "FALLO T4: enable=0 modifico el registro"
            severity error;
        report "T4 OK: enable=0 conserva el contenido" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: reset limpia aunque el registro tenga datos
        ---------------------------------------------------------------
        btn_rst <= '1';
        wait for 10 ms;
        assert led = X"00"
            report "FALLO T5: el reset no limpio el registro cargado"
            severity error;
        btn_rst <= '0';
        wait for 10 ms;
        report "T5 OK: reset limpia un registro con datos" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 6: el antirrebote produce un solo pulso por pulsacion
        ---------------------------------------------------------------
        enable <= '1';
        din    <= '1';
        btn_clk <= '1';
        wait for 50 ms;             -- Pulsacion larga: solo debe contar una vez
        btn_clk <= '0';
        wait for 20 ms;

        assert led = X"01"
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
