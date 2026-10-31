library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench de la ruleta.
-- Se reduce CLK_HZ para que la simulacion sea rapida, manteniendo
-- los tiempos reales de antirrebote (20 ms) y de giro (20 Hz).
--
-- El display ahora es multiplexado: el valor de la ruleta solo esta
-- presente en los segmentos cuando dig(0)='1'. El testbench captura ese
-- valor en seg_ruleta y comprueba ademas las letras A, B y C de los otros
-- tres digitos.
entity tb_Ruleta is
end tb_Ruleta;

architecture sim of tb_Ruleta is

    constant CLK_HZ  : integer := 10_000;          -- Reloj lento para simular
    constant CLK_PER : time    := 1 sec / CLK_HZ;  -- 100 us

    signal clk   : std_logic := '0';
    signal btn_n : std_logic := '1';
    signal seg   : std_logic_vector(6 downto 0);
    signal dig   : std_logic_vector(3 downto 0);
    signal led_n : std_logic_vector(2 downto 0);
    signal fin   : boolean := false;

    -- Valor de la ruleta capturado cuando esta activo su digito
    signal seg_ruleta : std_logic_vector(6 downto 0) := (others => '0');

    -- Entradas/salidas del punto 2 (sin usar aqui)
    signal dip1  : std_logic_vector(1 downto 0) := "00";
    signal btn3  : std_logic := '0';
    signal btn4  : std_logic := '0';
    signal bar1  : std_logic_vector(7 downto 0);

    -- Traduce el codigo de segmentos (A..G) al numero mostrado.
    -- Devuelve -1 si el codigo no corresponde a un digito valido.
    function seg_a_numero (v : std_logic_vector(6 downto 0)) return integer is
    begin
        case v is
            when "0111111" => return 0;  -- 0x3F
            when "0000110" => return 1;  -- 0x06
            when "1011011" => return 2;  -- 0x5B
            when "1001111" => return 3;  -- 0x4F
            when "1100110" => return 4;  -- 0x66
            when "1101101" => return 5;  -- 0x6D
            when "1111101" => return 6;  -- 0x7D
            when "0000111" => return 7;  -- 0x07
            when "1111111" => return 8;  -- 0x7F
            when others    => return -1;
        end case;
    end function;

begin

    clk <= not clk after CLK_PER / 2 when not fin;

    -- Captura el patron de la ruleta cuando su digito esta habilitado
    process (clk)
    begin
        if rising_edge(clk) then
            if dig = "0001" then
                seg_ruleta <= seg;
            end if;
        end if;
    end process;

    dut : entity work.Practica1_DLPs
        generic map (
            CLK_HZ          => CLK_HZ,
            DB_MS           => 20,
            SPIN_HZ         => 20,
            DIGIT_HZ        => 1000,
            BTN_ACTIVO_BAJO => false
        )
        port map (
            clk   => clk,
            btn_n => btn_n,
            seg   => seg,
            dig   => dig,
            led_n => led_n,
            dip1  => dip1,
            btn3  => btn3,
            btn4  => btn4,
            bar1  => bar1
        );

    proceso_pruebas : process
        variable vistos    : std_logic_vector(7 downto 0) := (others => '0');
        variable cambios   : integer;
        variable previo    : std_logic_vector(6 downto 0);
        variable congelado : std_logic_vector(6 downto 0);
        variable n         : integer;
    begin

        ---------------------------------------------------------------
        -- PRUEBA 1: estado de reposo estable
        ---------------------------------------------------------------
        wait for 5 ms;              -- Espera fin del reset de encendido
        previo := seg_ruleta;
        wait for 100 ms;
        assert seg_ruleta = previo
            report "FALLO T1: el display cambia con la ruleta detenida"
            severity error;
        report "T1 OK: reposo estable, display = " & integer'image(seg_a_numero(seg_ruleta))
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: una pulsacion inicia el giro
        ---------------------------------------------------------------
        btn_n <= '0'; wait for 30 ms; btn_n <= '1';   -- Pulsacion limpia
        wait for 20 ms;

        cambios := 0;
        previo  := seg_ruleta;
        for i in 1 to 40 loop
            wait for 10 ms;
            if seg_ruleta /= previo then
                cambios := cambios + 1;
                previo  := seg_ruleta;
            end if;
        end loop;

        assert cambios >= 3
            report "FALLO T2: la ruleta no gira tras la pulsacion"
            severity error;
        report "T2 OK: la ruleta gira (" & integer'image(cambios) & " cambios en 400 ms)"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: segunda pulsacion detiene y congela el valor
        ---------------------------------------------------------------
        btn_n <= '0'; wait for 30 ms; btn_n <= '1';
        wait for 100 ms;             -- Deja terminar el ultimo tick de giro
        congelado := seg_ruleta;
        wait for 500 ms;

        assert seg_ruleta = congelado
            report "FALLO T3: el display no queda congelado al detener"
            severity error;

        n := seg_a_numero(congelado);
        assert (n >= 1) and (n <= 8)
            report "FALLO T3: valor mostrado fuera del rango 1..8"
            severity error;
        report "T3 OK: ruleta detenida en " & integer'image(n)
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: antirrebote (rebotes cortos no generan pulsos)
        ---------------------------------------------------------------
        for i in 1 to 10 loop       -- 10 rebotes de 2 ms (< 20 ms)
            btn_n <= '0'; wait for 2 ms;
            btn_n <= '1'; wait for 2 ms;
        end loop;
        wait for 40 ms;

        previo := seg_ruleta;
        wait for 100 ms;
        assert seg_ruleta = previo
            report "FALLO T4: un rebote arranco la ruleta"
            severity error;
        report "T4 OK: los rebotes no generan pulsos"
            severity note;

        -- Pulsacion limpia posterior: debe arrancar una sola vez
        btn_n <= '0'; wait for 30 ms; btn_n <= '1';
        wait for 100 ms;
        previo := seg_ruleta;
        wait for 200 ms;
        assert seg_ruleta /= previo
            report "FALLO T4: la pulsacion limpia no arranco la ruleta"
            severity error;
        report "T4 OK: pulsacion limpia arranca correctamente"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: cobertura del LFSR (aparecen los 8 valores)
        ---------------------------------------------------------------
        for i in 1 to 300 loop
            wait for 55 ms;
            n := seg_a_numero(seg_ruleta);
            if (n >= 1) and (n <= 8) then
                vistos(n - 1) := '1';
            end if;
        end loop;

        assert vistos = "11111111"
            report "FALLO T5: no aparecen todos los valores 1..8"
            severity error;
        report "T5 OK: cobertura completa de los valores 1..8"
            severity note;

        ---------------------------------------------------------------
        -- PRUEBA 6: multiplexado del display (A, B, C y ruleta)
        ---------------------------------------------------------------
        wait until dig = "0010";     -- Digito 4: letra A
        wait for 1 us;
        assert seg = "1110111"
            report "FALLO T6: el digito 4 no muestra la letra A"
            severity error;

        wait until dig = "0100";     -- Digito 5: letra B
        wait for 1 us;
        assert seg = "1111100"
            report "FALLO T6: el digito 5 no muestra la letra B"
            severity error;

        wait until dig = "1000";     -- Digito 6: letra C
        wait for 1 us;
        assert seg = "0111001"
            report "FALLO T6: el digito 6 no muestra la letra C"
            severity error;

        wait until dig = "0001";     -- Digito 3: valor de la ruleta
        wait for 1 us;
        n := seg_a_numero(seg);
        assert (n >= 1) and (n <= 8)
            report "FALLO T6: el digito de la ruleta no muestra un valor 1..8"
            severity error;
        report "T6 OK: multiplexado correcto (ruleta, A, B y C)"
            severity note;

        ---------------------------------------------------------------
        -- Fin de la simulacion
        ---------------------------------------------------------------
        fin <= true;
        assert false report "SIMULACION FINALIZADA CORRECTAMENTE" severity failure;
        wait;
    end process;

end sim;
