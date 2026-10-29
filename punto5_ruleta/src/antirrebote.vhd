library ieee;
use ieee.std_logic_1164.all;

-- Sincroniza el pulsador (activo bajo) y elimina los rebotes.
-- Solo se considera una pulsacion valida cuando la entrada permanece
-- presionada durante N_MS muestras consecutivas de 1 ms. La salida
-- 'pulso' dura exactamente un ciclo de reloj y no se repite mientras
-- el boton siga presionado.
entity antirrebote is
    generic (
        N_MS : integer := 20
    );
    port (
        clk     : in  std_logic;
        tick_ms : in  std_logic;
        btn_n   : in  std_logic;
        pulso   : out std_logic
    );
end antirrebote;

architecture rtl of antirrebote is
    signal sync0 : std_logic := '1';
    signal sync1 : std_logic := '1';
    signal cont  : integer range 0 to N_MS := 0;

    signal pulso_reg : std_logic := '0';
begin

    process (clk)
    begin
        if rising_edge(clk) then
            -- Dos etapas de sincronizacion (entrada asincrona)
            sync0 <= btn_n;
            sync1 <= sync0;

            pulso_reg <= '0';

            if tick_ms = '1' then
                if sync1 = '0' then
                    -- Boton presionado: cuenta muestras consecutivas
                    if cont < N_MS then
                        cont <= cont + 1;
                        if cont = N_MS - 1 then
                            pulso_reg <= '1';
                        end if;
                    end if;
                else
                    -- Boton liberado: reinicia el conteo (rebotes)
                    cont <= 0;
                end if;
            end if;
        end if;
    end process;

    pulso <= pulso_reg;

end rtl;
