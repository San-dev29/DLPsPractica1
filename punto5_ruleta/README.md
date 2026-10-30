# Práctica 1 — Ruleta electrónica de 8 resultados

Circuito en VHDL que simula una ruleta con ocho resultados posibles (1 a 8),
mostrados en un display de 7 segmentos. El mismo pulsador inicia y detiene el giro.

## 1. Distribución de hardware

Dispositivo: **Cyclone II EP2C5T144C8N** (Quartus II 13.0 SP1).

| Señal | Pin | Tipo | Polaridad / nota |
|---|---|---|---|
| `clk` | 17 | Entrada | Oscilador 50 MHz |
| `btn_n` | 144 | Entrada | Pulsador con pull-up, **activo bajo** |
| `seg[0]` = A | 96 | Salida | Segmento, activo alto |
| `seg[1]` = B | 94 | Salida | Segmento, activo alto |
| `seg[2]` = C | 93 | Salida | Segmento, activo alto |
| `seg[3]` = D | 92 | Salida | Segmento, activo alto |
| `seg[4]` = E | 87 | Salida | Segmento, activo alto |
| `seg[5]` = F | 86 | Salida | Segmento, activo alto |
| `seg[6]` = G | 79 | Salida | Segmento, activo alto |
| `led_n[2]` | 3 | Salida | LED D2, **activo bajo** |
| `led_n[1]` | 7 | Salida | LED D4, **activo bajo** |
| `led_n[0]` | 9 | Salida | LED D5, **activo bajo** |

Notas:
- El punto decimal (DP) no se usa: su pin habitual (3) está ocupado por el LED D2.
- Los LEDs muestran el número en binario invertido. Al ser solo 3 LEDs, el valor
  **8 se representa como `000`**.
- `RESERVE_ALL_UNUSED_PINS = AS INPUT TRI-STATED` para no forzar niveles en pines libres.

## 2. Arquitectura

```
clk 50 MHz ──► div_frecuencia ──► tick_ms (1 kHz) ──► antirrebote ──► pulso
                    │                                                   │
                    └──► tick_giro (20 Hz)                              ▼
                                                          control_ruleta (RUN/STOP)
                                                                    │ running
      contador libre ──► seed ──► lfsr8 ◄── tick_act = tick_giro & running
                                    │ q(2..0)
                                    ▼
                        valor = q(2..0) + 1  (1..8)
                                    │
                     ┌──────────────┴──────────────┐
                     ▼                             ▼
              BinSieteseg (s='0')            led_n = not valor(2..0)
                     │
                  seg(6..0)
```

| Archivo | Descripción |
|---|---|
| `Practica1_DLPs.vhd` | Entidad superior: instancias, reset de encendido y semilla |
| `div_frecuencia.vhd` | Ticks de 1 kHz (antirrebote) y 20 Hz (giro) |
| `antirrebote.vhd` | Sincronizador de 2 FF + validación de 20 ms |
| `control_ruleta.vhd` | Biestable T: conmuta RUN/STOP con cada pulsación |
| `lfsr8.vhd` | LFSR Galois `x⁸+x⁶+x⁵+x⁴+1` (0xB8), periodo 255 |
| `BinSieteseg.vhd` | Decodificador binario → 7 segmentos |
| `tb_Ruleta.vhd` | Testbench con 5 pruebas (no se sintetiza) |
| `Practica1_DLPs.sdc` | Restricción de reloj de 50 MHz |

### Funcionamiento

1. Al encender, un reset interno de 1 ms deja la ruleta detenida.
2. Primera pulsación: se siembra el LFSR con un contador libre de 50 MHz (el valor
   depende del instante de la pulsación) y los números avanzan a 20 Hz.
3. Segunda pulsación: el LFSR deja de avanzar y el display queda fijo en el número.

## 3. Resultados de simulación (ModelSim)

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reposo estable (display no cambia) | OK — muestra 2 tras el reset |
| T2 | Una pulsación inicia el giro | OK — 8 cambios en 400 ms |
| T3 | Segunda pulsación detiene y congela | OK — detenida en 1 |
| T4 | Rebotes de 2 ms no generan pulsos | OK — después arranca con pulsación limpia |
| T5 | Cobertura del LFSR | OK — aparecen los 8 valores (1..8) |

## 4. Resultados de síntesis

```
Total logic elements : 132 / 4,608 ( 3 % )
Total registers      : 81
Total pins           : 12 / 89 ( 13 % )
Worst-case setup slack : 13.145 ns   (positivo)
Worst-case hold slack  :  0.499 ns   (positivo)
Full Compilation     : 0 errors
```

## 5. Cómo reproducir

Todo el punto 5 está en esta carpeta:

```
punto5_ruleta/
├── src/                   # VHDL sintetizable
├── sim/tb_Ruleta.vhd      # Testbench
├── Practica1_DLPs.qpf     # Proyecto Quartus
├── Practica1_DLPs.qsf     # Pines
└── Practica1_DLPs.sdc     # Restricción de reloj
```

Desde la raíz del repositorio:

```powershell
# Compilación en Quartus
.\scripts\compilar.ps1 -Modulo punto5_ruleta

# Simulación en ModelSim
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Ruleta
```

También se puede hacer manualmente desde esta carpeta:

```powershell
& "D:\Programas\Quartus ii\quartus\bin64\quartus_sh.exe" --flow compile Practica1_DLPs

vlib work
vcom -93 src/*.vhd sim/*.vhd
vsim -c -do "run -all; quit -f" tb_Ruleta
```

Para simular más rápido, el testbench usa `CLK_HZ = 10_000`, manteniendo los
tiempos reales de antirrebote (20 ms) y de giro (20 Hz).
