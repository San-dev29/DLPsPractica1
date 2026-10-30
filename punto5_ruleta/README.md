# Práctica 1 — Ruleta electrónica y prueba de componentes

Circuito en VHDL con dos bloques independientes que comparten el reloj y el reset:

1. **Ruleta** de ocho resultados (1 a 8) en un display de 7 segmentos. El mismo
   pulsador inicia y detiene el giro.
2. **Prueba de componentes**: el DIP switch 1 conectado a la barra de LEDs 1 y
   cuatro pulsadores conectados a cuatro LEDs de la barra 2.

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

### Pulsadores y barra de LEDs 2

| Señal | Pin | Tipo | Polaridad |
|---|---|---|---|
| `btn1` | 74 | Entrada | Activo alto (pull-down) |
| `btn2` | 75 | Entrada | Activo alto (pull-down) |
| `btn3` | 100 | Entrada | Activo alto (pull-down) |
| `btn4` | 97 | Entrada | Activo alto (pull-down) |
| `bar2[0]` | 71 | Salida | LED de `btn1`, activo alto |
| `bar2[1]` | 69 | Salida | LED de `btn2`, activo alto |
| `bar2[2]` | 65 | Salida | LED de `btn3`, activo alto |
| `bar2[3]` | 63 | Salida | LED de `btn4`, activo alto |
| `bar2[4]` | 59 | Salida | Apagado |
| `bar2[5]` | 57 | Salida | Apagado |
| `bar2[6]` | 53 | Salida | Apagado |
| `bar2[7]` | 51 | Salida | Apagado |

Notas:
- **Pin 73 DEFECTUOSO: no usar.** Aun sin nada conectado entrega 3.3 V (queda fijo
  en alto), por lo que se descartó como entrada. `btn3` se movió al pin 100 y
  `btn4` al 97.
- El DIP switch 2 se retiró del diseño: la placa de ese DIP switch está defectuosa
  (no la FPGA). Sus pines (52–72) ya no se usan.
- **Funciones especiales de pines**: los pines 74 y 75 son entradas de reloj/PLL y
  el pin 76 es `LVDS41p/nCEO`. Los 74/75 funcionan como I/O normal (confirmar en
  la placa); el 76 se liberó con
  `CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION = USE AS REGULAR IO` aunque ya no se
  usa en el diseño actual.
- El punto decimal (DP) del display no se usa: su pin habitual (3) está ocupado
  por el LED D2.
- Los LEDs D2/D4/D5 muestran el número de la ruleta en binario invertido. Al ser
  solo 3 LEDs, el valor **8 se representa como `000`**.
- `RESERVE_ALL_UNUSED_PINS = AS INPUT TRI-STATED` para no forzar niveles en pines libres.
- La polaridad del DIP switch y de los pulsadores se puede invertir con las
  constantes `DIP_ACTIVO_BAJO` y `BTN_ACTIVO_BAJO` de `prueba_componentes.vhd`.

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
 dip1 ──────────────┼──► u_componentes : prueba_componentes                             │
 btn1..btn4 ────────┼──►   sincronizadores ─► bar1 = dip1, bar2(3..0) = btn4..btn1        │
                    └─────────────────────────────────────────────────────────────────────┘
```

| Archivo | Descripción |
|---|---|
| `Practica1_DLPs.vhd` | Top: reset de encendido e instancias de los dos módulos |
| `ruleta.vhd` | Módulo de la ruleta (divisor, antirrebote, control, LFSR y decodificador) |
| `prueba_componentes.vhd` | Conexión fija DIP switch 1 → barra 1 y pulsadores → barra 2 |
| `div_frecuencia.vhd` | Ticks de 1 kHz (antirrebote) y de giro |
| `antirrebote.vhd` | Sincronizador de 2 FF + validación de 20 ms |
| `control_ruleta.vhd` | Biestable T: conmuta RUN/STOP con cada pulsación |
| `lfsr8.vhd` | LFSR Galois `x⁸+x⁶+x⁵+x⁴+1` (0xB8), periodo 255 |
| `BinSieteseg.vhd` | Decodificador binario → 7 segmentos |
| `sim/tb_Ruleta.vhd` | Testbench de la ruleta (5 pruebas) |
| `sim/tb_Componentes.vhd` | Testbench de DIP switch, barras y pulsadores (5 pruebas) |
| `Practica1_DLPs.sdc` | Restricción de reloj de 50 MHz |

### Funcionamiento de la ruleta

1. Al encender, un reset interno de 1 ms deja la ruleta detenida.
2. Primera pulsación de `btn_n`: se siembra el LFSR con un contador libre de 50 MHz
   (el valor depende del instante de la pulsación) y los números avanzan a 20 Hz.
3. Segunda pulsación: el LFSR deja de avanzar y el display queda fijo en el número.

### Funcionamiento de la prueba de componentes

Conexión fija, sin modos:

- `bar1 = dip1`: la barra 1 replica los 8 interruptores del DIP switch 1.
- `bar2(0) = btn1`, `bar2(1) = btn2`, `bar2(2) = btn3`, `bar2(3) = btn4`.
- `bar2(7..4) = 0`: los cuatro LEDs altos de la barra 2 quedan apagados.

Los pulsadores se sincronizan con dos biestables. Como el LED refleja directamente
el nivel del pulsador, los rebotes solo producen un parpadeo momentáneo.

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
| T1 | Conexión fija `dip1` → `bar1` y `bar2` apagada | OK |
| T2 | `bar1` sigue los cambios del DIP switch en vivo | OK |
| T3 | Cada pulsador enciende su LED (`bar2(0..3)`) | OK |
| T4 | Pulsaciones simultáneas se combinan | OK — `0x05` y `0x0A` |
| T5 | `bar2(7..4)` permanece apagado | OK |

## 4. Resultados de síntesis

```
Total logic elements : 140 / 4,608 ( 3 % )
Total registers      : 89
Total pins           : 40 / 89 ( 45 % )
Worst-case setup slack : 13.449 ns   (positivo)
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
tiempos reales de antirrebote (20 ms) y de giro (20 Hz).
