# Práctica 1 — Ruleta electrónica + registro de desplazamiento (diseño integrado)

Circuito en VHDL que integra **dos puntos de la práctica en paralelo**, compartiendo
solo el reloj de la placa y el reset de encendido:

1. **Punto 5 — Ruleta** de ocho resultados (1 a 8) en el display de 7 segmentos
   multiplexado. El pulsador de la ruleta inicia y detiene el giro. El dígito 3
   muestra el valor de la ruleta y los dígitos 4, 5 y 6 muestran **A**, **B** y **C**
   para comprobar el barrido del display.
2. **Punto 2 — Registro de desplazamiento de 8 bits**: el DIP switch 1 fija el dato
   serie y el enable, el pulsador 3 genera el reloj y el pulsador 4 el reset; la
   barra de LEDs 1 muestra las 8 etapas.

La **prueba de componentes quedó deshabilitada** y sus pines se reutilizan para el
punto 2. Su código se conserva (sin compilarse) en `legacy/`.

El nivel superior `Practica1_DLPs` genera el reset de encendido e instancia
`ruleta`, `display_mux` y `Punto2_Registro`.

## 1. Distribución de hardware

Dispositivo: **Cyclone II EP2C5T144C8** (Quartus II 13.0 SP1).

### Reloj, ruleta y LEDs de estado

| Señal | Pin | Componente físico | Tipo | Polaridad / nota |
|---|---|---|---|---|
| `clk` | 17 | Oscilador de la placa | Entrada | 50 MHz |
| `btn_n` | 144 | Pulsador de la ruleta | Entrada | Pull-up, **activo bajo** |
| `seg[0]` = A | 96 | Display 7 segmentos, segmento A | Salida | Activo alto |
| `seg[1]` = B | 94 | Display 7 segmentos, segmento B | Salida | Activo alto |
| `seg[2]` = C | 93 | Display 7 segmentos, segmento C | Salida | Activo alto |
| `seg[3]` = D | 92 | Display 7 segmentos, segmento D | Salida | Activo alto |
| `seg[4]` = E | 87 | Display 7 segmentos, segmento E | Salida | Activo alto |
| `seg[5]` = F | 86 | Display 7 segmentos, segmento F | Salida | Activo alto |
| `seg[6]` = G | 79 | Display 7 segmentos, segmento G | Salida | Activo alto |
| `dig[0]` | 113 | Display, dígito 3 | Salida | Ruleta, activo alto |
| `dig[1]` | 115 | Display, dígito 4 | Salida | Letra A, activo alto |
| `dig[2]` | 114 | Display, dígito 5 | Salida | Letra B, activo alto |
| `dig[3]` | 112 | Display, dígito 6 | Salida | Letra C, activo alto |
| `led_n[2]` | 3 | LED D2 | Salida | **Activo bajo** |
| `led_n[1]` | 7 | LED D4 | Salida | **Activo bajo** |
| `led_n[0]` | 9 | LED D5 | Salida | **Activo bajo** |

### Punto 2: DIP switch 1, barra de LEDs 1 y pulsadores

| Señal | Pin | Componente físico | Tipo | Función |
|---|---|---|---|---|
| `dip1[0]` | 120 | DIP switch 1, interruptor 1 | Entrada | Dato serie `din` |
| `dip1[1]` | 122 | DIP switch 1, interruptor 2 | Entrada | `enable` del registro |
| `btn3` | 100 | Pulsador 3 | Entrada | Reloj del registro (1 pulso por pulsación) |
| `btn4` | 97 | Pulsador 4 | Entrada | Reset del registro, activo alto |
| `bar1[0]` | 121 | Barra de LEDs 1, LED 1 | Salida | `q(0)` — bit más nuevo |
| `bar1[1]` | 125 | Barra de LEDs 1, LED 2 | Salida | `q(1)` |
| `bar1[2]` | 129 | Barra de LEDs 1, LED 3 | Salida | `q(2)` |
| `bar1[3]` | 133 | Barra de LEDs 1, LED 4 | Salida | `q(3)` |
| `bar1[4]` | 135 | Barra de LEDs 1, LED 5 | Salida | `q(4)` |
| `bar1[5]` | 137 | Barra de LEDs 1, LED 6 | Salida | `q(5)` |
| `bar1[6]` | 141 | Barra de LEDs 1, LED 7 | Salida | `q(6)` |
| `bar1[7]` | 143 | Barra de LEDs 1, LED 8 | Salida | `q(7)` — bit más antiguo |

Notas:
- **Pin 73 DEFECTUOSO: no usar.** Aun sin nada conectado entrega 3.3 V (queda fijo
  en alto). No se asigna en el `.qsf`.
- El **DIP switch 1** y la **barra de LEDs 1** son activos en alto (pull-down /
  resistencia a GND). Los **pulsadores 3 y 4** también son activos en alto.
  Si la placa real difiere, ajustar `BTN_ACTIVO_BAJO` en el top.
- Los pines 74 y 75 (entradas de reloj/PLL) y el 76 (`nCEO`) ya **no se usan**:
  eran la prueba de componentes. El 76 sigue liberado con
  `CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION = USE AS REGULAR IO`.
- El DIP switch 2 se retiró del diseño: su placa está defectuosa (no la FPGA).
  Sus pines (52–72) ya no se usan.
- El display es **multiplexado**: se enciende un dígito a la vez, a 1 kHz por
  dígito (250 Hz por trama). `dig(0)` = pin 113 = dígito 3 (ruleta),
  `dig(1)` = pin 115 = dígito 4 (A), `dig(2)` = pin 114 = dígito 5 (B) y
  `dig(3)` = pin 112 = dígito 6 (C). Si el orden físico de los dígitos en la
  tarjeta es distinto, basta con intercambiar esas asignaciones en el `.qsf`.
- El punto decimal (DP) del display no se usa.
- Los LEDs D2/D4/D5 muestran el número de la ruleta en binario invertido. Con 3
  LEDs, el valor **8 se representa como `000`**.
- `RESERVE_ALL_UNUSED_PINS = AS INPUT TRI-STATED` para no forzar niveles en pines
  libres.

## 2. Arquitectura

```
                  ┌──────────────────────── Practica1_DLPs (top) ───────────────────────┐
                  │  reset de encendido (~1 ms) -> rst                                  │
                  │                                                                     │
 clk ─────────────┼──► u_ruleta : ruleta                                                │
 btn_n ───────────┼──►   div_frecuencia ─► antirrebote ─► control_ruleta ─► lfsr8      │
                  │        └────────────────────────────────────► BinSieteseg ─► seg_ruleta│
                  │                                                     └─► led_n        │
                  │                                                                     │
                  │   u_display : display_mux  (ruleta, A, B, C) ──► seg y dig           │
                  │                                                                     │
 dip1[0] ─────────┼──► u_registro : Punto2_Registro ─► bar1                             │
 dip1[1] ─────────┼──►   din / enable                                                  │
 btn3 ────────────┼──►   debounce_btn (reloj) ─► registro_desplazamiento                │
 btn4 ────────────┼──►   debounce_btn (reset)                                          │
                  └─────────────────────────────────────────────────────────────────────┘
```

| Archivo | Descripción |
|---|---|
| `src/Practica1_DLPs.vhd` | Top: reset de encendido e instancias de ruleta, display y punto 2 |
| `src/ruleta.vhd` | Punto 5: divisor, antirrebote, control, LFSR y decodificador |
| `src/display_mux.vhd` | Barrido de los 4 dígitos: ruleta en el dígito 3 y A/B/C en 4–6 |
| `src/div_frecuencia.vhd` | Ticks de 1 kHz (antirrebote) y de giro |
| `src/antirrebote.vhd` | Sincronizador de 2 FF + validación de 20 ms |
| `src/control_ruleta.vhd` | Biestable T: conmuta RUN/STOP con cada pulsación |
| `src/lfsr8.vhd` | LFSR Galois `x⁸+x⁶+x⁵+x⁴+1` (0xB8), periodo 255 |
| `src/BinSieteseg.vhd` | Decodificador binario → 7 segmentos |
| `../punto2_registro_desplazamiento/src/Punto2_Registro.vhd` | Punto 2: sincronización del DIP, antirrebotes y registro |
| `../punto2_registro_desplazamiento/src/debounce_btn.vhd` | Antirrebote genérico con salida `level` y `pulse` |
| `../punto2_registro_desplazamiento/src/registro_desplazamiento.vhd` | Registro de 8 bits con enable y reset |
| `sim/tb_Ruleta.vhd` | Testbench de la ruleta y del multiplexado (6 pruebas) |
| `sim/tb_Registro.vhd` | Testbench del punto 2 integrado (6 pruebas) |
| `legacy/prueba_componentes.vhd` | Prueba de componentes **deshabilitada** (no se compila) |
| `legacy/tb_Componentes.vhd` | Testbench de la prueba de componentes **deshabilitado** |
| `Practica1_DLPs.sdc` | Restricción de reloj de 50 MHz |

El `.qsf` referencia las fuentes del punto 2 con rutas relativas
(`../punto2_registro_desplazamiento/src/...`); no hay copias duplicadas.

### Funcionamiento de la ruleta (punto 5)

1. Al encender, un reset interno de 1 ms deja la ruleta detenida.
2. Primera pulsación del **pulsador de la ruleta (pin 144)**: se siembra el LFSR con
   un contador libre de 50 MHz (el valor depende del instante de la pulsación) y los
   números avanzan a 20 Hz.
3. Segunda pulsación: el LFSR deja de avanzar y el display queda fijo en el número.

El display es multiplexado: `display_mux` recorre los cuatro dígitos a 1 kHz y
coloca en los segmentos el valor de la ruleta (dígito 3, pin 113) o las letras A, B
y C (dígitos 4, 5 y 6; pines 115, 114 y 112). La persistencia de la visión hace que
se vean los cuatro caracteres a la vez.

### Funcionamiento del registro de desplazamiento (punto 2)

1. **Reset**: con el **pulsador 4 (pin 97)** en alto, el registro se limpia
   (`bar1 = 0x00`) en el siguiente flanco de reloj. Es un reset **síncrono activo
   alto**, ya antirrebotado.
2. **Enable**: el **DIP switch 1, interruptor 2 (pin 122)** habilita el
   desplazamiento. Con el interruptor en bajo, los pulsos de reloj no cambian el
   contenido.
3. **Reloj**: cada pulsación del **pulsador 3 (pin 100)** produce **un solo pulso**
   antirrebotado (`DB_MS = 20 ms`), aunque se mantenga apretado. El registro se
   relojiza con el reloj de 50 MHz y ese pulso actúa como *clock enable*, por lo
   que el pulsador nunca se usa como reloj digital.
4. **Dato serie**: el **DIP switch 1, interruptor 1 (pin 120)** entrega el bit que
   entra por `q(0)`. En cada pulso, el contenido se corre una posición:
   `q(7) <= q(6) <= ... <= q(1) <= q(0) <= din`.
5. **Salidas**: la **barra de LEDs 1 (pines 121, 125, 129, 133, 135, 137, 141 y
   143)** muestra `q(0)`..`q(7)`; `bar1[0]` es el bit más nuevo y `bar1[7]` el más
   antiguo.

Ejemplo: con `din = 1` y `enable = 1`, tras 8 pulsaciones del pulsador 3 la barra
queda en `0xFF`; si luego se pone `din = 0` y se pulsa 8 veces más, la barra se
apaga de a un LED por pulsación.

### Prueba de componentes (deshabilitada)

`legacy/prueba_componentes.vhd` conectaba el DIP switch 1 a la barra 1 y los
pulsadores 1–4 a la barra 2. Ya **no se compila** ni se instancia: sus pines
(pulsadores 1 y 2 y la barra 2) quedaron libres y el DIP switch 1 y la barra 1 se
reutilizan para el punto 2. El archivo se conserva solo como referencia histórica;
para volver a usarlo habría que restaurar sus asignaciones de pines en el `.qsf`.

## 3. Resultados de simulación (ModelSim)

`tb_Ruleta` (ruleta + multiplexado, integrado):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reposo estable (display no cambia) | OK — muestra 2 tras el reset |
| T2 | Una pulsación inicia el giro | OK — 8 cambios en 400 ms |
| T3 | Segunda pulsación detiene y congela | OK — detenida en 1 |
| T4 | Rebotes de 2 ms no generan pulsos | OK — después arranca con pulsación limpia |
| T5 | Cobertura del LFSR | OK — aparecen los 8 valores (1..8) |
| T6 | Multiplexado del display | OK — ruleta en dígito 3 y A/B/C en dígitos 4–6 |

`tb_Registro` (punto 2 dentro del top integrado):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reset con el pulsador 4 (pin 97) | OK — `bar1 = 0x00` |
| T2 | `enable = 0` (DIP 1, interruptor 2) no desplaza | OK |
| T3 | 8 bits serie por DIP 1, interruptor 1 | OK — `bar1 = 0xB2` |
| T4 | `enable = 0` conserva el contenido | OK — sigue en `0xB2` |
| T5 | Reset limpia un registro con datos | OK |
| T6 | Una pulsación larga del pulsador 3 = un solo desplazamiento | OK |

## 4. Resultados de síntesis

```
Total logic elements   : 200 / 4,608 ( 4 % )
Total registers        : 139
Total pins             :  28 / 89  (31 %)
Worst-case setup slack : 13.966 ns   (positivo, reloj de 50 MHz)
Worst-case hold slack  :  0.499 ns   (positivo)
Full Compilation       : 0 errors, 7 warnings (ninguno de pines)
```

Los warnings son informativos: compilación en paralelo sin licencia, LogicLock sin
licencia, jitter no soportado por Cyclone II, falta de capacitancia de carga en las
salidas y restricciones de setup/hold no exhaustivas. No hay conflictos de pines
dedicados.

## 5. Cómo reproducir

```
punto5_ruleta/
├── src/                      # VHDL sintetizable de los puntos 5 y top
│   ├── Practica1_DLPs.vhd    # Top integrado
│   ├── ruleta.vhd
│   ├── display_mux.vhd
│   └── ...
├── sim/
│   ├── tb_Ruleta.vhd
│   └── tb_Registro.vhd
├── legacy/                   # Prueba de componentes deshabilitada
│   ├── prueba_componentes.vhd
│   └── tb_Componentes.vhd
├── Practica1_DLPs.qpf        # Proyecto Quartus
├── Practica1_DLPs.qsf        # Pines y fuentes (incluye ../punto2.../src)
└── Practica1_DLPs.sdc        # Restricción de reloj
```

Desde la raíz del repositorio:

```powershell
# Compilación en Quartus
.\scripts\compilar.ps1 -Modulo punto5_ruleta

# Simulación de la ruleta y el display
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Ruleta

# Simulación del punto 2 integrado
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Registro
```

`simular.ps1` lee las entradas `VHDL_FILE` del `.qsf` del módulo, por lo que compila
también las fuentes externas del punto 2 además de `src/` y `sim/`.

También se puede hacer manualmente desde esta carpeta:

```powershell
& "D:\Programas\Quartus ii\quartus\bin64\quartus_sh.exe" --flow compile Practica1_DLPs

vlib work
vcom -93 src/*.vhd sim/*.vhd ../punto2_registro_desplazamiento/src/*.vhd
vsim -c -do "run -all; quit -f" tb_Ruleta
```

Para simular más rápido, los testbenches usan `CLK_HZ = 10_000`, manteniendo los
tiempos reales de antirrebote y de giro.
