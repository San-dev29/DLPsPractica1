library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench del punto 3 integrado en el nivel superior Practica1_DLPs.
--
-- Se controla el contador a traves de los pines reales del diseno:
--   * DIP switch 1, bit 2 (pin 126) -> direccion
--   * DIP switch 1, bit 3 (pin 132) -> habilitacion
--   * btn 1 (pin 74)                -> reset
--   * btn 2 (pin 75)                -> start
--   * digito 4 del display          -> valor 0..F
--
-- La ruleta y el registro del punto 2 se mantienen inactivos.
-- Se usa TICK_HZ = 20 (50 ms por cuenta): suficientemente rapido para la
-- simulacion y mucho mayor que el antirrebote (5 ms) y que el periodo de
-- captura del display (2 ms), de modo que cada valor se observa sin
-- ambiguedad. Los tiempos de espera (150 ms) superan un periodo de tick.
entity tb_P3 is
end tb_P3;

architecture sim of tb_P3 is

    constant CLK_HZ  : integer := 10_000;
    constant CLK_PER : time    := 1 sec / CLK_HZ;  -- 100 us

    signal clk   : std_logic := '0';
    signal btn_n : std_logic := '1';               -- Ruleta detenida
    signal seg   : std_logic_vector(6 downto 0);
    signal dig   : std_logic_vector(3 downto 0);
    signal led_n : std_logic_vector(2 downto 0);

    signal dip1 : std_logic_vector(3 downto 0) := "0000";
    signal btn1 : std_logic := '0';                -- Reset del contador
    signal btn2 : std_logic := '0';                -- Start del contador
    signal btn3 : std_logic := '0';                -- Registro P2 inactivo
    signal btn4 : std_logic := '0';
    signal bar1 : std_logic_vector(7 downto 0);

    -- Patrones capturados cuando cada digito esta habilitado
    signal seg_d3 : std_logic_vector(6 downto 0) := (others => '0');
    signal seg_d4 : std_logic_vector(6 downto 0) := (others => '0');

    signal fin : boolean := false;

    -- Decodifica el patron de segmentos (A..G) al valor 0..15.
    -- Devuelve -1 si el patron no corresponde a un valor valido.
    function seg_a_numero (v : std_logic_vector(6 downto 0)) return integer is
    begin
        case v is
            when "0111111" => return 0;
            when "0000110" => return 1;
            when "1011011" => return 2;
            when "1001111" => return 3;
            when "1100110" => return 4;
            when "1101101" => return 5;
            when "1111101" => return 6;
            when "0000111" => return 7;
            when "1111111" => return 8;
            when "1101111" => return 9;
            when "1110111" => return 10;  -- A
            when "1111100" => return 11;  -- b
            when "0111001" => return 12;  -- C
            when "1011110" => return 13;  -- d
            when "1111001" => return 14;  -- E
            when "1110001" => return 15;  -- F
            when others    => return -1;
        end case;
    end function;

begin

    clk <= not clk after CLK_PER / 2 when not fin;

    -- Captura el patron de cada digito cuando el multiplexado lo habilita
    process (clk)
    begin
        if rising_edge(clk) then
            if dig = "0001" then
                seg_d3 <= seg;
            end if;
            if dig = "0010" then
                seg_d4 <= seg;
            end if;
        end if;
    end process;

    dut : entity work.Practica1_DLPs
        generic map (
            CLK_HZ          => CLK_HZ,
            DB_MS           => 5,
            SPIN_HZ         => 20,
            DIGIT_HZ        => 1000,
            TICK_HZ         => 20,        -- 50 ms por cuenta
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
        variable previo   : std_logic_vector(6 downto 0);
        variable esperado : integer;
    begin

        wait for 5 ms;  -- Deja terminar el reset de encendido

        ---------------------------------------------------------------
        -- PRUEBA 1: estado inicial (contador en 0, detenido)
        ---------------------------------------------------------------
        assert seg_d4 = "0111111"
            report "FALLO T1: el contador no arranca en 0"
            severity error;
        assert dig(3 downto 2) = "00"
            report "FALLO T1: los digitos 5 o 6 estan habilitados"
            severity error;

        wait for 150 ms;
        assert seg_d4 = "0111111"
            report "FALLO T1: el contador avanza sin pulsar start"
            severity error;
        report "T1 OK: contador en 0 y detenido tras el encendido"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: start arranca el conteo ascendente
        ---------------------------------------------------------------
        dip1(2) <= '1';                  -- Direccion ascendente
        dip1(3) <= '1';                  -- Habilitacion maestra
        btn2 <= '1'; wait for 10 ms; btn2 <= '0';
        wait for 2 ms;

        previo := seg_d4;
        wait until seg_d4 /= previo for 150 ms;
        assert seg_a_numero(seg_d4) = 1
            report "FALLO T2: tras start se esperaba 1, valor=" &
                   integer'image(seg_a_numero(seg_d4))
            severity error;

        previo := seg_d4;
        wait until seg_d4 /= previo for 150 ms;
        assert seg_a_numero(seg_d4) = 2
            report "FALLO T2: se esperaba 2, valor=" &
                   integer'image(seg_a_numero(seg_d4))
            severity error;
        report "T2 OK: start arranca el conteo ascendente (0 -> 1 -> 2)"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: la habilitacion en 0 pausa el conteo
        ---------------------------------------------------------------
        dip1(3) <= '0';
        wait for 2 ms;                   -- Deja pasar el tick en curso
        previo := seg_d4;
        wait for 150 ms;
        assert seg_d4 = previo
            report "FALLO T3: el contador avanzo con habilitacion en 0"
            severity error;
        report "T3 OK: DIP de habilitacion en 0 pausa el conteo"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: al reanudar continua desde el valor pausado
        ---------------------------------------------------------------
        esperado := (seg_a_numero(previo) + 1) mod 16;
        dip1(3) <= '1';
        wait until seg_d4 /= previo for 150 ms;
        assert seg_a_numero(seg_d4) = esperado
            report "FALLO T4: se esperaba " & integer'image(esperado) &
                   ", valor=" & integer'image(seg_a_numero(seg_d4))
            severity error;
        report "T4 OK: la habilitacion reanuda el conteo"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: direccion descendente
        ---------------------------------------------------------------
        previo   := seg_d4;
        esperado := (seg_a_numero(previo) - 1) mod 16;
        dip1(2) <= '0';                  -- Direccion descendente
        wait until seg_d4 /= previo for 150 ms;
        assert seg_a_numero(seg_d4) = esperado
            report "FALLO T5: se esperaba " & integer'image(esperado) &
                   ", valor=" & integer'image(seg_a_numero(seg_d4))
            severity error;
        report "T5 OK: direccion descendente"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 6: reset borra y detiene el contador
        ---------------------------------------------------------------
        btn1 <= '1'; wait for 10 ms;
        assert seg_d4 = "0111111"
            report "FALLO T6: el reset no borro el contador"
            severity error;
        btn1 <= '0'; wait for 10 ms;

        previo := seg_d4;
        wait for 150 ms;
        assert seg_d4 = previo
            report "FALLO T6: el contador siguio contando tras el reset"
            severity error;
        assert seg_a_numero(seg_d4) = 0
            report "FALLO T6: el contador no quedo en 0, valor=" &
                   integer'image(seg_a_numero(seg_d4))
            severity error;
        report "T6 OK: reset borra y detiene el contador"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 7: start descendente desde 0 desborda a F (15)
        ---------------------------------------------------------------
        btn2 <= '1'; wait for 10 ms; btn2 <= '0';
        wait for 2 ms;

        previo := seg_d4;
        wait until seg_d4 /= previo for 150 ms;
        assert seg_a_numero(seg_d4) = 15
            report "FALLO T7: desde 0 en descendente se esperaba 15, valor=" &
                   integer'image(seg_a_numero(seg_d4))
            severity error;
        report "T7 OK: desbordamiento 0 -> F en descendente"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 8: reset y start ascendente; digitos 5 y 6 apagados
        ---------------------------------------------------------------
        btn1 <= '1'; wait for 10 ms; btn1 <= '0'; wait for 10 ms;
        dip1(2) <= '1';                  -- Direccion ascendente
        btn2 <= '1'; wait for 10 ms; btn2 <= '0';
        wait for 2 ms;

        previo := seg_d4;
        wait until seg_d4 /= previo for 150 ms;
        assert seg_a_numero(seg_d4) = 1
            report "FALLO T8: tras reset y start ascendente se esperaba 1, valor=" &
                   integer'image(seg_a_numero(seg_d4))
            severity error;

        for i in 1 to 10 loop
            wait for 1 ms;
            assert dig(3 downto 2) = "00"
                report "FALLO T8: se habilito un digito apagado (5 o 6)"
                severity error;
        end loop;

        assert (seg_a_numero(seg_d3) >= 1) and (seg_a_numero(seg_d3) <= 8)
            report "FALLO T8: el digito 3 no muestra un valor de la ruleta"
            severity error;

        report "T8 OK: reset + start ascendente y digitos 5 y 6 apagados"
            severity note;

        ---------------------------------------------------------------
        -- Fin de la simulacion
        ---------------------------------------------------------------
        fin <= true;
        assert false report "SIMULACION FINALIZADA CORRECTAMENTE" severity failure;
        wait;
    end process;

end sim;
