library ieee;
use ieee.std_logic_1164.all;

-- Testbench del modulo prueba_componentes.
-- Se prueba a traves del nivel superior Practica1_DLPs para validar
-- tambien la instanciacion modular.
--
-- Conexion esperada (fija, sin modos):
--   bar1      = dip1
--   bar2(3..0) = btn4, btn3, btn2, btn1
--   bar2(7..4) = 0
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
            CLK_HZ  => CLK_HZ,
            DB_MS   => 20,
            SPIN_HZ => 20
        )
        port map (
            clk   => clk,
            btn_n => btn_n,
            seg   => seg,
            led_n => led_n,
            dip1  => dip1,
            btn1  => btn1,
            btn2  => btn2,
            btn3  => btn3,
            btn4  => btn4,
            bar1  => bar1,
            bar2  => bar2
        );

    proceso_pruebas : process
    begin

        dip1 <= X"A5";
        wait for 5 ms;              -- Fin del reset de encendido
        wait for 1 ms;              -- Latencia de los sincronizadores

        ---------------------------------------------------------------
        -- PRUEBA 1: conexion fija dip1 -> bar1 y bar2 apagada
        ---------------------------------------------------------------
        assert bar1 = X"A5"
            report "FALLO T1: bar1 no refleja dip1"
            severity error;
        assert bar2 = X"00"
            report "FALLO T1: bar2 no esta apagada sin pulsadores"
            severity error;
        report "T1 OK: bar1 = dip1 y bar2 apagada"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: la barra 1 sigue los cambios del DIP switch
        ---------------------------------------------------------------
        dip1 <= X"0F"; wait for 1 ms;
        assert bar1 = X"0F"
            report "FALLO T2: bar1 no sigue los cambios de dip1"
            severity error;
        dip1 <= X"3C"; wait for 1 ms;
        assert bar1 = X"3C"
            report "FALLO T2: bar1 no sigue los cambios de dip1"
            severity error;
        report "T2 OK: bar1 sigue en vivo al DIP switch 1"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: cada pulsador enciende su LED de la barra 2
        ---------------------------------------------------------------
        btn1 <= '1'; wait for 1 ms;
        assert bar2 = "00000001"
            report "FALLO T3: btn1 no enciende bar2(0)"
            severity error;
        btn1 <= '0'; wait for 1 ms;

        btn2 <= '1'; wait for 1 ms;
        assert bar2 = "00000010"
            report "FALLO T3: btn2 no enciende bar2(1)"
            severity error;
        btn2 <= '0'; wait for 1 ms;

        btn3 <= '1'; wait for 1 ms;
        assert bar2 = "00000100"
            report "FALLO T3: btn3 no enciende bar2(2)"
            severity error;
        btn3 <= '0'; wait for 1 ms;

        btn4 <= '1'; wait for 1 ms;
        assert bar2 = "00001000"
            report "FALLO T3: btn4 no enciende bar2(3)"
            severity error;
        btn4 <= '0'; wait for 1 ms;

        assert bar2 = X"00"
            report "FALLO T3: bar2 no se apaga al soltar los pulsadores"
            severity error;
        report "T3 OK: btn1..btn4 encienden bar2(0..3) de forma independiente"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: pulsaciones simultaneas
        ---------------------------------------------------------------
        btn1 <= '1';
        btn3 <= '1';
        wait for 1 ms;
        assert bar2 = "00000101"
            report "FALLO T4: las pulsaciones simultaneas no se combinan"
            severity error;

        btn1 <= '0'; btn3 <= '0';
        btn2 <= '1'; btn4 <= '1';
        wait for 1 ms;
        assert bar2 = "00001010"
            report "FALLO T4: las pulsaciones simultaneas no se combinan"
            severity error;
        btn2 <= '0'; btn4 <= '0';
        wait for 1 ms;
        report "T4 OK: las pulsaciones simultaneas se reflejan combinadas"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: los 4 bits altos de bar2 permanecen apagados
        ---------------------------------------------------------------
        for i in 1 to 16 loop
            btn1 <= '1'; btn2 <= '1'; btn3 <= '1'; btn4 <= '1';
            wait for 500 us;
            assert bar2(7 downto 4) = "0000"
                report "FALLO T5: los bits altos de bar2 no estan a cero"
                severity error;
            btn1 <= '0'; btn2 <= '0'; btn3 <= '0'; btn4 <= '0';
            wait for 500 us;
        end loop;
        report "T5 OK: bar2(7..4) permanecen apagados"
            severity note;

        ---------------------------------------------------------------
        -- Fin de la simulacion
        ---------------------------------------------------------------
        fin <= true;
        assert false report "SIMULACION FINALIZADA CORRECTAMENTE" severity failure;
        wait;
    end process;

end sim;
