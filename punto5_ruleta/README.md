# Práctica 1 — Ruleta electrónica y prueba de componentes

Circuito en VHDL con dos bloques independientes que comparten el reloj y el reset:

1. **Ruleta** de ocho resultados (1 a 8) en un display de 7 segmentos. El mismo
   pulsador inicia y detiene el giro.
2. **Prueba de componentes**: dos DIP switches, dos barras de 8 LEDs y cuatro
   pulsadores que seleccionan distintos modos de visualización.

El nivel superior `Practica1_DLPs` solo genera el reset de encendido e instancia
ambos módulos.

## 1. Distribución de hardware

Dispositivo: **Cyclone II EP2C5T144C8N** (Quartus II 13.0 SP1).

### Reloj, ruleta y LEDs de estado

| Señal | Pin | Tipo | Polaridad / nota |
|---|---|---|---|
| `clk` | 17 | Entrada | Oscilador 50 MHz |
| `btn_n` | 144 | Entrada | Pulsador de la ruleta con pull-up, **activo bajo** |
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

### DIP switch 1 y barra de LEDs 1

| Señal | Pin | Tipo | Polaridad |
|---|---|---|---|
| `dip1[0]` | 120 | Entrada | Activo alto |
| `dip1[1]` | 122 | Entrada | Activo alto |
| `dip1[2]` | 126 | Entrada | Activo alto |
| `dip1[3]` | 132 | Entrada | Activo alto |
| `dip1[4]` | 134 | Entrada | Activo alto |
| `dip1[5]` | 136 | Entrada | Activo alto |
| `dip1[6]` | 139 | Entrada | Activo alto |
| `dip1[7]` | 142 | Entrada | Activo alto |
| `bar1[0]` | 121 | Salida | Activo alto |
| `bar1[1]` | 125 | Salida | Activo alto |
| `bar1[2]` | 129 | Salida | Activo alto |
| `bar1[3]` | 133 | Salida | Activo alto |
| `bar1[4]` | 135 | Salida | Activo alto |
| `bar1[5]` | 137 | Salida | Activo alto |
| `bar1[6]` | 141 | Salida | Activo alto |
| `bar1[7]` | 143 | Salida | Activo alto |

### DIP switch 2 y barra de LEDs 2

| Señal | Pin | Tipo | Polaridad |
|---|---|---|---|
| `dip2[0]` | 72 | Entrada | Activo alto |
| `dip2[1]` | 70 | Entrada | Activo alto |
| `dip2[2]` | 67 | Entrada | Activo alto |
| `dip2[3]` | 64 | Entrada | Activo alto |
| `dip2[4]` | 60 | Entrada | Activo alto |
| `dip2[5]` | 58 | Entrada | Activo alto |
| `dip2[6]` | 55 | Entrada | Activo alto |
| `dip2[7]` | 52 | Entrada | Activo alto |
| `bar2[0]` | 71 | Salida | Activo alto |
| `bar2[1]` | 69 | Salida | Activo alto |
| `bar2[2]` | 65 | Salida | Activo alto |
| `bar2[3]` | 63 | Salida | Activo alto |
| `bar2[4]` | 59 | Salida | Activo alto |
| `bar2[5]` | 57 | Salida | Activo alto |
| `bar2[6]` | 53 | Salida | Activo alto |
| `bar2[7]` | 51 | Salida | Activo alto |

### Pulsadores de prueba de componentes

| Señal | Pin | Tipo | Polaridad |
|---|---|---|---|
| `btn1` | 81 | Entrada | Activo alto (pull-down) |
| `btn2` | 88 | Entrada | Activo alto (pull-down) |
| `btn3` | 89 | Entrada | Activo alto (pull-down) |
| `btn4` | 90 | Entrada | Activo alto (pull-down) |

Notas:
- El punto decimal (DP) del display no se usa: su pin habitual (3) está ocupado
  por el LED D2.
- Los LEDs D2/D4/D5 muestran el número de la ruleta en binario invertido. Al ser
  solo 3 LEDs, el valor **8 se representa como `000`**.
- `RESERVE_ALL_UNUSED_PINS = AS INPUT TRI-STATED` para no forzar niveles en pines libres.
- La polaridad de DIP switches y pulsadores se puede invertir con las constantes
  `DIP_ACTIVO_BAJO` y `BTN_ACTIVO_BAJO` de `prueba_componentes.vhd`.

## 2. Arquitectura

```
                    ┌──────────────────────── Practica1_DLPs (top) ───────────────────────┐
                    │  reset de encendido (~1 ms) -> rst                                  │
                    │                                                                     │
 clk ───────────────┼──► u_ruleta : ruleta                                                │
 btn_n ─────────────┼──►   div_frecuencia ─► antirrebote ─► control_ruleta ─► lfsr8     │
                    │        └────────────────────────────────────► BinSieteseg ─► seg      │
                    │                                                     └─► led_n        │
                    │                                                                     │
 dip1, dip2 ────────┼──► u_componentes : prueba_componentes                             │
 btn1..btn4 ────────┼──►   4 x antirrebote ─► registro de modo ─► mux ─► bar1, bar2       │
                    │       div_frecuencia (tick 1 ms y parpadeo)                         │
                    └─────────────────────────────────────────────────────────────────────┘
```

| Archivo | Descripción |
|---|---|
| `Practica1_DLPs.vhd` | Top: reset de encendido e instancias de los dos módulos |
| `ruleta.vhd` | Módulo de la ruleta (divisor, antirrebote, control, LFSR y decodificador) |
| `prueba_componentes.vhd` | Modos de prueba con DIP switches, barras de LEDs y 4 pulsadores |
| `div_frecuencia.vhd` | Ticks de 1 kHz (antirrebote) y de giro/parpadeo |
| `antirrebote.vhd` | Sincronizador de 2 FF + validación de 20 ms |
| `control_ruleta.vhd` | Biestable T: conmuta RUN/STOP con cada pulsación |
| `lfsr8.vhd` | LFSR Galois `x⁸+x⁶+x⁵+x⁴+1` (0xB8), periodo 255 |
| `BinSieteseg.vhd` | Decodificador binario → 7 segmentos |
| `sim/tb_Ruleta.vhd` | Testbench de la ruleta (5 pruebas) |
| `sim/tb_Componentes.vhd` | Testbench de DIP switches, barras y pulsadores (6 pruebas) |
| `Practica1_DLPs.sdc` | Restricción de reloj de 50 MHz |

### Funcionamiento de la ruleta

1. Al encender, un reset interno de 1 ms deja la ruleta detenida.
2. Primera pulsación de `btn_n`: se siembra el LFSR con un contador libre de 50 MHz
   (el valor depende del instante de la pulsación) y los números avanzan a 20 Hz.
3. Segunda pulsación: el LFSR deja de avanzar y el display queda fijo en el número.

### Funcionamiento de la prueba de componentes

El modo se selecciona con un pulsador y **queda memorizado** (no hay que mantenerlo
presionado). Tras el reset el modo es 0 (barras apagadas).

| Pulsador | Modo | Comportamiento |
|---|---|---|
| `btn1` | 1 | `bar1 = dip1` y `bar2 = dip2` (conexión directa) |
| `btn2` | 2 | Las dos barras parpadean a 2 Hz |
| `btn3` | 3 | Las dos barras permanecen encendidas |
| `btn4` | 4 | Igual que el modo 1 pero intercambiando entradas: `bar1 = dip2`, `bar2 = dip1` |

Los cuatro pulsadores pasan por su propio antirrebote de 20 ms. Si se presionan
varios a la vez, la prioridad es `btn1 > btn2 > btn3 > btn4`.

## 3. Resultados de simulación (ModelSim)

`tb_Ruleta` (ruleta):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reposo estable (display no cambia) | OK — muestra 2 tras el reset |
| T2 | Una pulsación inicia el giro | OK — 8 cambios en 400 ms |
| T3 | Segunda pulsación detiene y congela | OK — detenida en 1 |
| T4 | Rebotes de 2 ms no generan pulsos | OK — después arranca con pulsación limpia |
| T5 | Cobertura del LFSR | OK — aparecen los 8 valores (1..8) |

`tb_Componentes` (prueba de componentes):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Modo inicial 0 | OK — barras apagadas |
| T2 | `btn1`: conexión directa | OK — la barra sigue los DIP switches en vivo |
| T3 | `btn2`: parpadeo | OK — 3 transiciones en 700 ms a 2 Hz |
| T4 | `btn3`: encendidas siempre | OK — `0xFF` estable durante 200 ms |
| T5 | `btn4`: entradas intercambiadas | OK — `bar1 = dip2`, `bar2 = dip1` |
| T6 | Antirrebote de los pulsadores de modo | OK — los rebotes no cambian el modo |

## 4. Resultados de síntesis

```
Total logic elements : 252 / 4,608 ( 5 % )
Total registers      : 137
Total pins           : 48 / 89 ( 54 % )
Worst-case setup slack : 13.135 ns   (positivo)
Worst-case hold slack  :  0.499 ns   (positivo)
Full Compilation     : 0 errors
```

## 5. Cómo reproducir

```
punto5_ruleta/
├── src/                      # VHDL sintetizable
│   ├── Practica1_DLPs.vhd    # Top
│   ├── ruleta.vhd
│   ├── prueba_componentes.vhd
│   └── ...
├── sim/
│   ├── tb_Ruleta.vhd
│   └── tb_Componentes.vhd
├── Practica1_DLPs.qpf        # Proyecto Quartus
├── Practica1_DLPs.qsf        # Pines
└── Practica1_DLPs.sdc        # Restricción de reloj
```

Desde la raíz del repositorio:

```powershell
# Compilación en Quartus
.\scripts\compilar.ps1 -Modulo punto5_ruleta

# Simulación de la ruleta
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Ruleta

# Simulación de la prueba de componentes
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Componentes
```

También se puede hacer manualmente desde esta carpeta:

```powershell
& "D:\Programas\Quartus ii\quartus\bin64\quartus_sh.exe" --flow compile Practica1_DLPs

vlib work
vcom -93 src/*.vhd sim/*.vhd
vsim -c -do "run -all; quit -f" tb_Ruleta
```

Para simular más rápido, los testbenches usan `CLK_HZ = 10_000`, manteniendo los
tiempos reales de antirrebote (20 ms), de giro (20 Hz) y de parpadeo (2 Hz).
