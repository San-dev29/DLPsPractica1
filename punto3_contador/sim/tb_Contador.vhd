library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench del punto 3: contador binario de 4 bits ascendente/descendente.
--
-- Se prueban por separado el contador y el decodificador, y despues el
-- nivel superior completo (antirrebote, reset de encendido, divisor de
-- frecuencia, sincronizacion del DIP switch y display).
--
--   1. Reset asincrono activo bajo.
--   2. Cuenta ascendente 0..15 con desbordamiento a 0.
--   3. Cuenta descendente 15..0 con desbordamiento a 15.
--   4. Habilitacion en 0 congela el conteo.
--   5. Cambio de direccion en marcha.
--   6. Decodificador binario -> 7 segmentos para 0..F.
--   7. Nivel superior: arranque en 0, conteo, habilitacion, direccion,
--      reset con pulsador antirrebotado y visualizacion de 0 y F.
entity tb_Contador is
end tb_Contador;

architecture sim of tb_Contador is

    constant CLK_HZ  : integer := 10_000;          -- Reloj lento para simular
    constant CLK_PER : time    := 1 sec / CLK_HZ;  -- 100 us
    constant TICK_HZ : integer := 1000;            -- 1 ms en simulacion
    constant DB_MS   : integer := 5;               -- Antirrebote de 5 ms

    signal clk : std_logic := '0';
    signal fin : boolean   := false;

    -- Contador aislado
    signal rst_cnt_n : std_logic := '0';
    signal ena_cnt   : std_logic := '0';
    signal dir_cnt   : std_logic := '1';
    signal q_cnt     : std_logic_vector(3 downto 0);

    -- Decodificador aislado
    signal bin_dec : std_logic_vector(3 downto 0) := (others => '0');
    signal seg_dec : std_logic_vector(6 downto 0);

    -- Nivel superior
    signal rst_n   : std_logic := '1';
    signal dir_top : std_logic := '1';
    signal hab     : std_logic := '0';
    signal seg     : std_logic_vector(6 downto 0);
    signal digito  : std_logic;

    type tabla_t is array (0 to 15) of std_logic_vector(6 downto 0);
    constant SEG_TABLA : tabla_t := (
        "0111111",  -- 0
        "0000110",  -- 1
        "1011011",  -- 2
        "1001111",  -- 3
        "1100110",  -- 4
        "1101101",  -- 5
        "1111101",  -- 6
        "0000111",  -- 7
        "1111111",  -- 8
        "1101111",  -- 9
        "1110111",  -- A
        "1111100",  -- b
        "0111001",  -- C
        "1011110",  -- d
        "1111001",  -- E
        "1110001"   -- F
    );

begin

    clk <= not clk after CLK_PER / 2 when not fin;

    u_cnt : entity work.contador_ud
        generic map (
            ANCHO => 4
        )
        port map (
            clk   => clk,
            rst_n => rst_cnt_n,
            ena   => ena_cnt,
            dir   => dir_cnt,
            q     => q_cnt
        );

    u_dec : entity work.dec_7seg
        port map (
            bin => bin_dec,
            seg => seg_dec
        );

    u_top : entity work.Punto3_Contador
        generic map (
            CLK_HZ  => CLK_HZ,
            DB_MS   => DB_MS,
            TICK_HZ => TICK_HZ
        )
        port map (
            clk    => clk,
            rst_n  => rst_n,
            dir    => dir_top,
            hab    => hab,
            seg    => seg,
            digito => digito
        );

    proceso_pruebas : process

        -- Espera el proximo cambio del display y comprueba el digito.
        procedure esperar_cambio (esperado : integer) is
            variable seg_antes : std_logic_vector(6 downto 0);
        begin
            seg_antes := seg;
            wait until seg /= seg_antes for 5 ms;
            assert seg = SEG_TABLA(esperado)
                report "FALLO T7: se esperaba el digito " &
                       integer'image(esperado) &
                       " y el display mostro otro patron"
                severity error;
        end procedure;

    begin

        wait for 1 us;

        ---------------------------------------------------------------
        -- PRUEBA 1: reset asincrono activo bajo
        ---------------------------------------------------------------
        rst_cnt_n <= '1';
        ena_cnt   <= '1';
        dir_cnt   <= '1';

        for k in 1 to 3 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;
        assert q_cnt = X"3"
            report "FALLO T1: el contador no conto antes del reset"
            severity error;

        rst_cnt_n <= '0';
        wait for 1 ns;  -- Sin flanco de reloj: el reset debe actuar igual
        assert q_cnt = X"0"
            report "FALLO T1: el reset activo bajo no es asincrono"
            severity error;

        wait for 500 ns;
        assert q_cnt = X"0"
            report "FALLO T1: el contador conto con el reset activo"
            severity error;

        rst_cnt_n <= '1';
        wait for 1 ns;
        report "T1 OK: reset asincrono activo bajo" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 2: cuenta ascendente 0..15 y desbordamiento
        ---------------------------------------------------------------
        dir_cnt <= '1';

        for i in 1 to 15 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert q_cnt = std_logic_vector(to_unsigned(i, 4))
                report "FALLO T2: se esperaba " & integer'image(i) &
                       " en la cuenta ascendente"
                severity error;
        end loop;

        wait until rising_edge(clk);
        wait for 1 ns;
        assert q_cnt = X"0"
            report "FALLO T2: no desbordo de 15 a 0"
            severity error;

        report "T2 OK: cuenta ascendente 0..15 y desborda a 0" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 3: cuenta descendente 15..0 y desbordamiento
        ---------------------------------------------------------------
        rst_cnt_n <= '0';
        wait for 1 ns;
        rst_cnt_n <= '1';
        dir_cnt   <= '0';

        for i in 15 downto 0 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert q_cnt = std_logic_vector(to_unsigned(i, 4))
                report "FALLO T3: se esperaba " & integer'image(i) &
                       " en la cuenta descendente"
                severity error;
        end loop;

        report "T3 OK: cuenta descendente 15..0 y desborda a 15" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 4: habilitacion en 0 congela el conteo
        ---------------------------------------------------------------
        ena_cnt <= '0';
        for k in 1 to 5 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;
        assert q_cnt = X"0"
            report "FALLO T4: el contador cambio con ena=0"
            severity error;

        dir_cnt <= '1';
        ena_cnt <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert q_cnt = X"1"
            report "FALLO T4: el contador no reanudo con ena=1"
            severity error;

        report "T4 OK: ena=0 congela y ena=1 reanuda" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 5: cambio de direccion en marcha
        ---------------------------------------------------------------
        dir_cnt <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;
        assert q_cnt = X"0"
            report "FALLO T5: no decremento al cambiar la direccion"
            severity error;

        wait until rising_edge(clk);
        wait for 1 ns;
        assert q_cnt = X"F"
            report "FALLO T5: no desbordo de 0 a 15 al bajar"
            severity error;

        ena_cnt <= '0';
        report "T5 OK: cambio de direccion en marcha" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 6: decodificador 0..F
        ---------------------------------------------------------------
        for i in 0 to 15 loop
            bin_dec <= std_logic_vector(to_unsigned(i, 4));
            wait for 1 ns;
            assert seg_dec = SEG_TABLA(i)
                report "FALLO T6: patron incorrecto para el valor " &
                       integer'image(i)
                severity error;
        end loop;

        report "T6 OK: decodificador 0..F" severity note;

        ---------------------------------------------------------------
        -- PRUEBA 7: nivel superior integrado
        ---------------------------------------------------------------
        hab     <= '0';
        dir_top <= '1';
        rst_n   <= '1';
        wait for 3 ms;  -- Deja terminar el reset de encendido (1 ms)

        assert seg = SEG_TABLA(0)
            report "FALLO T7: el contador no arranca en 0"
            severity error;
        assert digito = '1'
            report "FALLO T7: el digito 3 del display no esta habilitado"
            severity error;

        hab <= '1';
        esperar_cambio(1);
        esperar_cambio(2);

        hab <= '0';
        wait for 5 ms;
        assert seg = SEG_TABLA(2)
            report "FALLO T7: hab=0 no congelo el conteo en el top"
            severity error;

        dir_top <= '0';
        hab     <= '1';
        esperar_cambio(1);
        esperar_cambio(0);

        rst_n <= '0';
        wait for 10 ms;
        assert seg = SEG_TABLA(0)
            report "FALLO T7: el pulsador de reset no limpio el contador"
            severity error;
        assert digito = '1'
            report "FALLO T7: el digito 3 se deshabilito con el reset"
            severity error;

        rst_n <= '1';
        hab   <= '0';
        wait for 10 ms;  -- Espera el fin del antirrebote de liberacion

        assert seg = SEG_TABLA(0)
            report "FALLO T7: el contador conto durante la liberacion del reset"
            severity error;

        -- Direccion descendente desde 0: el primer valor debe ser F (15)
        hab <= '1';
        esperar_cambio(15);

        report "T7 OK: top integrado (reset, tick, habilitacion, direccion y display)"
            severity note;

        ---------------------------------------------------------------
        -- Fin de la simulacion
        ---------------------------------------------------------------
        fin <= true;
        assert false report "SIMULACION FINALIZADA CORRECTAMENTE" severity failure;
        wait;
    end process;

end sim;
