library ieee;
use ieee.std_logic_1164.all;

-- Testbench del modulo prueba_componentes.
-- Se reduce CLK_HZ para acelerar la simulacion manteniendo los tiempos
-- reales de antirrebote (20 ms) y de parpadeo (2 Hz).
--
-- Se prueba a traves del nivel superior Practica1_DLPs, de modo que
-- tambien se valida la instanciacion modular.
entity tb_Componentes is
end tb_Componentes;

architecture sim of tb_Componentes is

    constant CLK_HZ  : integer := 10_000;          -- Reloj lento para simular
    constant CLK_PER : time    := 1 sec / CLK_HZ;  -- 100 us

    signal clk   : std_logic := '0';
    signal btn_n : std_logic := '1';               -- Ruleta sin usar
    signal seg   : std_logic_vector(6 downto 0);
    signal led_n : std_logic_vector(2 downto 0);

    signal dip1 : std_logic_vector(7 downto 0) := (others => '0');
    signal dip2 : std_logic_vector(7 downto 0) := (others => '0');
    signal btn1 : std_logic := '0';
    signal btn2 : std_logic := '0';
    signal btn3 : std_logic := '0';
    signal btn4 : std_logic := '0';
    signal bar1 : std_logic_vector(7 downto 0);
    signal bar2 : std_logic_vector(7 downto 0);

    signal fin : boolean := false;

begin

    clk <= not clk after CLK_PER / 2 when not fin;

    dut : entity work.Practica1_DLPs
        generic map (
            CLK_HZ   => CLK_HZ,
            DB_MS    => 20,
            SPIN_HZ  => 20,
            BLINK_HZ => 2
        )
        port map (
            clk   => clk,
            btn_n => btn_n,
            seg   => seg,
            led_n => led_n,
            dip1  => dip1,
            dip2  => dip2,
            btn1  => btn1,
            btn2  => btn2,
            btn3  => btn3,
            btn4  => btn4,
            bar1  => bar1,
            bar2  => bar2
        );

    proceso_pruebas : process
        variable cambios : integer;
        variable previo  : std_logic_vector(7 downto 0);
        variable vio_on  : boolean;
        variable vio_off : boolean;
    begin

        dip1 <= X"A5";
        dip2 <= X"3C";
        wait for 5 ms;              -- Fin del reset de encendido

        ---------------------------------------------------------------
        -- PRUEBA 1: tras el reset el modo es 0 (barras apagadas)
        ---------------------------------------------------------------
        assert bar1 = X"00" and bar2 = X"00"
            report "FALLO T1: las barras no arrancan apagadas"
            severity error;
        report "T1 OK: modo inicial 0 (barras apagadas)"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: btn1 -> conexion directa DIP switch -> barra
        ---------------------------------------------------------------
        btn1 <= '1'; wait for 30 ms; btn1 <= '0';
        wait for 10 ms;

        assert bar1 = X"A5" and bar2 = X"3C"
            report "FALLO T2: la conexion directa no refleja los DIP switches"
            severity error;

        -- Cambio en vivo de un DIP: la barra debe seguirlo de inmediato
        dip1 <= X"0F";
        wait for 1 ms;
        assert bar1 = X"0F"
            report "FALLO T2: la barra no sigue los cambios del DIP switch"
            severity error;
        dip1 <= X"A5";
        report "T2 OK: modo 1, bar1 = dip1 y bar2 = dip2"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: btn2 -> las dos barras parpadean
        ---------------------------------------------------------------
        btn2 <= '1'; wait for 30 ms; btn2 <= '0';
        wait for 10 ms;

        cambios := 0;
        previo  := bar1;
        vio_on  := false;
        vio_off := false;
        for i in 1 to 70 loop       -- 700 ms de observacion
            wait for 10 ms;
            if bar1 /= previo then
                cambios := cambios + 1;
                previo  := bar1;
            end if;
            if bar1 = X"FF" then vio_on  := true; end if;
            if bar1 = X"00" then vio_off := true; end if;
            assert bar1 = bar2
                report "FALLO T3: las barras no parpadean sincronizadas"
                severity error;
        end loop;

        assert (cambios >= 2) and vio_on and vio_off
            report "FALLO T3: las barras no parpadean"
            severity error;
        report "T3 OK: modo 2, parpadeo a 2 Hz (" & integer'image(cambios) &
               " transiciones en 700 ms)"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: btn3 -> las dos barras siempre encendidas
        ---------------------------------------------------------------
        btn3 <= '1'; wait for 30 ms; btn3 <= '0';
        wait for 10 ms;

        for i in 1 to 20 loop       -- Comprueba que no parpadean
            wait for 10 ms;
            assert bar1 = X"FF" and bar2 = X"FF"
                report "FALLO T4: las barras no quedan encendidas"
                severity error;
        end loop;
        report "T4 OK: modo 3, barras encendidas permanentemente"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: btn4 -> conexion directa pero intercambiando DIPs
        ---------------------------------------------------------------
        btn4 <= '1'; wait for 30 ms; btn4 <= '0';
        wait for 10 ms;

        assert bar1 = X"3C" and bar2 = X"A5"
            report "FALLO T5: el modo 4 no intercambia las entradas"
            severity error;
        report "T5 OK: modo 4, bar1 = dip2 y bar2 = dip1"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 6: antirrebote del pulsador de modo
        -- 10 rebotes de 2 ms (< 20 ms) no deben cambiar el modo actual (4)
        ---------------------------------------------------------------
        for i in 1 to 10 loop
            btn1 <= '1'; wait for 2 ms;
            btn1 <= '0'; wait for 2 ms;
        end loop;
        wait for 40 ms;

        assert bar1 = X"3C" and bar2 = X"A5"
            report "FALLO T6: un rebote cambio el modo de prueba"
            severity error;

        -- Pulsacion limpia posterior: debe pasar al modo 1
        btn1 <= '1'; wait for 30 ms; btn1 <= '0';
        wait for 10 ms;
        assert bar1 = X"A5" and bar2 = X"3C"
            report "FALLO T6: la pulsacion limpia no cambio de modo"
            severity error;
        report "T6 OK: los rebotes se filtran y la pulsacion limpia cambia de modo"
            severity note;

        ---------------------------------------------------------------
        -- Fin de la simulacion
        ---------------------------------------------------------------
        fin <= true;
        assert false report "SIMULACION FINALIZADA CORRECTAMENTE" severity failure;
        wait;
    end process;

end sim;
