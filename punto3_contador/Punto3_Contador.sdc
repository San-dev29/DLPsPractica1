# Restriccion de reloj: oscilador de 50 MHz (PIN_17)
create_clock -name clk -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]

derive_clock_uncertainty
