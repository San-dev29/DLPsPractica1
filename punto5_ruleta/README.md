# Práctica 1 — Ruleta + registro de desplazamiento + contador (diseño integrado)

Circuito en VHDL que integra **tres puntos de la práctica en paralelo**, compartiendo
solo el reloj de la placa y el reset de encendido:

1. **Punto 5 — Ruleta** de ocho resultados (1 a 8) en el display de 7 segmentos
   multiplexado. El pulsador de la ruleta inicia y detiene el giro. El dígito 3
   muestra el valor de la ruleta.
2. **Punto 2 — Registro de desplazamiento de 8 bits**: el DIP switch 1 (interruptores
   1 y 2) fija el dato serie y el enable, el pulsador 3 genera el reloj y el pulsador
   4 el reset; la barra de LEDs 1 muestra las 8 etapas.
3. **Punto 3 — Contador binario de 4 bits ascendente/descendente**: el DIP switch 1
   (interruptores 3 y 4) fija la dirección y la habilitación, el pulsador 1 hace el
   reset y el pulsador 2 el arranque; el dígito 4 muestra el valor en hexadecimal
   (`0`–`F`).

Los dígitos 5 y 6 del display quedan **apagados**: ya no se usan las letras A/B/C.

La **prueba de componentes quedó deshabilitada** y sus pines se reparten entre los
puntos 2 y 3. Su código se conserva (sin compilarse) en `legacy/`.

El nivel superior `Practica1_DLPs` genera el reset de encendido e instancia
`ruleta`, `display_mux`, `Punto2_Registro` y `Contador_P3`.

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
| `dig[1]` | 115 | Display, dígito 4 | Salida | Contador P3 (0–F), activo alto |
| `dig[2]` | 114 | Display, dígito 5 | Salida | **Apagado**, activo alto |
| `dig[3]` | 112 | Display, dígito 6 | Salida | **Apagado**, activo alto |
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

### Punto 3: DIP switch 1 y pulsadores 1 y 2

| Señal | Pin | Componente físico | Tipo | Función |
|---|---|---|---|---|
| `dip1[2]` | 126 | DIP switch 1, interruptor 3 | Entrada | Dirección: 1 = ascendente, 0 = descendente |
| `dip1[3]` | 132 | DIP switch 1, interruptor 4 | Entrada | Habilitación maestra: 1 = cuenta, 0 = pausa |
| `btn1` | 74 | Pulsador 1 | Entrada | Reset del contador, activo alto |
| `btn2` | 75 | Pulsador 2 | Entrada | Start del contador, activo alto |
| `dig[1]` | 115 | Display, dígito 4 | Salida | Valor del contador `0`–`F` (ver tabla del display) |

Notas:
- **Pin 73 DEFECTUOSO: no usar.** Aun sin nada conectado entrega 3.3 V (queda fijo
  en alto). No se asigna en el `.qsf`.
- El **DIP switch 1** y la **barra de LEDs 1** son activos en alto (pull-down /
  resistencia a GND). Los **pulsadores 1, 2, 3 y 4** también son activos en alto.
  Si la placa real difiere, ajustar `BTN_ACTIVO_BAJO` en el top.
- Los pines **74 y 75** son entradas de reloj/PLL del EP2C5T144. Se usan como
  **I/O normal** para los pulsadores 1 y 2 del contador, igual que en la antigua
  prueba de componentes. El fitter no reportó conflicto, pero deben confirmarse
  en la placa (ver AGENTS.md, sección 2).
- El pin 76 (`nCEO`) sigue liberado como I/O normal con
  `CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION = USE AS REGULAR IO`.
- El DIP switch 2 se retiró del diseño: su placa está defectuosa (no la FPGA).
  Sus pines (52–72) ya no se usan.
- El display es **multiplexado**: se enciende un dígito a la vez, a 1 kHz por
  dígito (500 Hz por trama). `dig(0)` = pin 113 = dígito 3 (ruleta) y
  `dig(1)` = pin 115 = dígito 4 (contador P3). `dig(2)` = pin 114 (dígito 5) y
  `dig(3)` = pin 112 (dígito 6) se mantienen en `'0'`; el sintetizador reporta
  esos dos pines como *stuck at GND*, lo cual es intencional. Si el orden físico
  de los dígitos en la tarjeta es distinto, basta con intercambiar las
  asignaciones en el `.qsf`.
- El punto decimal (DP) del display no se usa.
- Los LEDs D2/D4/D5 muestran el número de la ruleta en binario invertido. Con 3
  LEDs, el valor **8 se representa como `000`**.
- `RESERVE_ALL_UNUSED_PINS = AS INPUT TRI-STATED` para no forzar niveles en pines
  libres.

## 2. Arquitectura

```
Practica1_DLPs (top)
├── reset de encendido (~1 ms) -> rst
├── u_ruleta : ruleta ───────────────────────────► seg_ruleta, led_n
├── u_display : display_mux (ruleta, contador) ──► seg, dig
├── u_registro : Punto2_Registro ────────────────► bar1
│     dip1[0..1] = din, enable ; btn3 = reloj ; btn4 = reset
└── u_contador : Contador_P3 ────────────────────► seg_contador
      dip1[2..3] = dir, ena ; btn1 = reset ; btn2 = start
      div_tick (2 Hz) ──► tick
```

| Archivo | Descripción |
|---|---|
| `src/Practica1_DLPs.vhd` | Top: reset de encendido e instancias de los tres puntos y del display |
| `src/ruleta.vhd` | Punto 5: divisor, antirrebote, control, LFSR y decodificador |
| `src/display_mux.vhd` | Barrido de 2 dígitos: ruleta en el dígito 3 y contador en el 4 |
| `src/Contador_P3.vhd` | Punto 3 integrado: reset/start, sincronización del DIP y decodificador |
| `src/div_frecuencia.vhd` | Ticks de 1 kHz (antirrebote) y de giro |
| `src/antirrebote.vhd` | Sincronizador de 2 FF + validación de 20 ms |
| `src/control_ruleta.vhd` | Biestable T: conmuta RUN/STOP con cada pulsación |
| `src/lfsr8.vhd` | LFSR Galois `x⁸+x⁶+x⁵+x⁴+1` (0xB8), periodo 255 |
| `src/BinSieteseg.vhd` | Decodificador binario → 7 segmentos |
| `../punto2_registro_desplazamiento/src/Punto2_Registro.vhd` | Punto 2: sincronización del DIP, antirrebotes y registro |
| `../punto2_registro_desplazamiento/src/debounce_btn.vhd` | Antirrebote genérico con salida `level` y `pulse` |
| `../punto2_registro_desplazamiento/src/registro_desplazamiento.vhd` | Registro de 8 bits con enable y reset |
| `../punto3_contador/src/contador_ud.vhd` | Contador de 4 bits ascendente/descendente |
| `../punto3_contador/src/div_tick.vhd` | Divisor del pulso de conteo (2 Hz por defecto) |
| `../punto3_contador/src/dec_7seg.vhd` | Decodificador binario → 7 segmentos para `0`–`F` |
| `sim/tb_Ruleta.vhd` | Testbench de la ruleta y del multiplexado (6 pruebas) |
| `sim/tb_Registro.vhd` | Testbench del punto 2 integrado (6 pruebas) |
| `sim/tb_P3.vhd` | Testbench del punto 3 integrado (8 pruebas) |
| `legacy/prueba_componentes.vhd` | Prueba de componentes **deshabilitada** (no se compila) |
| `legacy/tb_Componentes.vhd` | Testbench de la prueba de componentes **deshabilitado** |
| `Practica1_DLPs.sdc` | Restricción de reloj de 50 MHz |

El `.qsf` referencia las fuentes de los puntos 2 y 3 con rutas relativas
(`../punto2_registro_desplazamiento/src/...` y `../punto3_contador/src/...`);
no hay copias duplicadas.

### Funcionamiento de la ruleta (punto 5)

1. Al encender, un reset interno de 1 ms deja la ruleta detenida.
2. Primera pulsación del **pulsador de la ruleta (pin 144)**: se siembra el LFSR con
   un contador libre de 50 MHz (el valor depende del instante de la pulsación) y los
   números avanzan a 20 Hz.
3. Segunda pulsación: el LFSR deja de avanzar y el display queda fijo en el número.

El display es multiplexado: `display_mux` recorre los dos dígitos usados a 1 kHz y
coloca en los segmentos el valor de la ruleta (dígito 3, pin 113) o el del contador
(dígito 4, pin 115). La persistencia de la visión hace que se vean ambos a la vez;
los dígitos 5 y 6 (pines 114 y 112) permanecen apagados.

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

### Funcionamiento del contador (punto 3)

1. **Arranque**: al encender, el reset de encendido borra el contador (`0`) y lo
   deja **detenido** (`run = 0`). El conteo no comienza solo.
2. **Start**: cada pulsación del **pulsador 2 (pin 75)** antirrebotada pone
   `run = 1` y el conteo arranca en el siguiente tick. Una pulsación larga no
   repite la acción.
3. **Reset**: con el **pulsador 1 (pin 74)** en alto, el contador se borra a `0` y
   `run` vuelve a `0` (queda detenido hasta un nuevo start).
4. **Habilitación**: el **DIP switch 1, interruptor 4 (pin 132)** es la
   habilitación maestra. Con `0` el conteo se **pausa** conservando el valor; con
   `1` se reanuda.
5. **Dirección**: el **DIP switch 1, interruptor 3 (pin 126)** elige
   `1 = ascendente` (`0,1,…,15,0,…`) o `0 = descendente` (`0,15,14,…,0,15,…`).
6. **Velocidad**: `div_tick` genera un pulso de **2 Hz** (`TICK_HZ`) que actúa como
   *clock enable*; el contador se relojiza siempre con los 50 MHz de la placa, no
   con los pulsadores. El valor cambia cada 0,5 s.
7. **Display**: el **dígito 4 (pin 115)** muestra el valor en hexadecimal `0`–`F`
   (11 y 13 como `b` y `d` minúsculas).

Ejemplo: con el interruptor 4 en ON y el 3 en ON, pulsa start (pulsador 2) y el
dígito 4 recorre `0,1,2,…`; pon el interruptor 4 en OFF para congelar el valor y
vuelve a ON para continuar. Pulsa reset (pulsador 1) para volver a `0`.

### Prueba de componentes (deshabilitada)

`legacy/prueba_componentes.vhd` conectaba el DIP switch 1 a la barra 1 y los
pulsadores 1–4 a la barra 2. Ya **no se compila** ni se instancia: el **DIP switch
1** y la **barra 1** se reutilizan para el punto 2; los **pulsadores 1 y 2** para
el punto 3 y los **pulsadores 3 y 4** para el punto 2. La barra 2 queda libre. El
archivo se conserva solo como referencia histórica; para volver a usarlo habría
que restaurar sus asignaciones de pines en el `.qsf`.

## 3. Resultados de simulación (ModelSim)

`tb_Ruleta` (ruleta + multiplexado, integrado):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reposo estable (display no cambia) | OK — muestra 2 tras el reset |
| T2 | Una pulsación inicia el giro | OK — 8 cambios en 400 ms |
| T3 | Segunda pulsación detiene y congela | OK — detenida en 1 |
| T4 | Rebotes de 2 ms no generan pulsos | OK — después arranca con pulsación limpia |
| T5 | Cobertura del LFSR | OK — aparecen los 8 valores (1..8) |
| T6 | Multiplexado del display | OK — ruleta en dígito 3, contador en 0 en el dígito 4 y dígitos 5–6 apagados |

`tb_Registro` (punto 2 dentro del top integrado):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reset con el pulsador 4 (pin 97) | OK — `bar1 = 0x00` |
| T2 | `enable = 0` (DIP 1, interruptor 2) no desplaza | OK |
| T3 | 8 bits serie por DIP 1, interruptor 1 | OK — `bar1 = 0xB2` |
| T4 | `enable = 0` conserva el contenido | OK — sigue en `0xB2` |
| T5 | Reset limpia un registro con datos | OK |
| T6 | Una pulsación larga del pulsador 3 = un solo desplazamiento | OK |

`tb_P3` (punto 3 dentro del top integrado; tick acelerado a 20 Hz):

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Estado inicial: contador en 0 y detenido; dígitos 5–6 apagados | OK |
| T2 | Start arranca el conteo ascendente (0 → 1 → 2) | OK |
| T3 | DIP de habilitación en 0 pausa el conteo | OK |
| T4 | Al reanudar continúa desde el valor pausado | OK |
| T5 | Dirección descendente al cambiar el DIP | OK |
| T6 | Reset borra y detiene el contador | OK |
| T7 | Start descendente desde 0 desborda a F (15) | OK |
| T8 | Reset + start ascendente; dígitos 5 y 6 apagados y ruleta en el dígito 3 | OK |

## 4. Resultados de síntesis

```
Total logic elements   : 281 / 4,608 ( 6 % )
Total registers        : 188
Total pins             :  32 / 89  (36 %)
Worst-case setup slack : 13.349 ns   (positivo, reloj de 50 MHz)
Worst-case hold slack  :  0.499 ns   (positivo)
Full Compilation       : 0 errors, 10 warnings
```

Los warnings son informativos: compilación en paralelo sin licencia, LogicLock sin
licencia, jitter no soportado por Cyclone II, falta de capacitancia de carga en las
salidas, restricciones de setup/hold no exhaustivas y `dig[2]`/`dig[3]` *stuck at
GND* (intencional: los dígitos 5 y 6 quedan apagados). No hay conflictos de pines
dedicados; los pines 74 y 75 se usan como I/O normal sin advertencia del fitter,
pero deben confirmarse en la placa.

## 5. Cómo reproducir

```
punto5_ruleta/
├── src/                      # VHDL sintetizable de los puntos 5 y 3, y top
│   ├── Practica1_DLPs.vhd    # Top integrado
│   ├── Contador_P3.vhd       # Envoltorio integrado del punto 3
│   ├── ruleta.vhd
│   ├── display_mux.vhd
│   └── ...
├── sim/
│   ├── tb_Ruleta.vhd
│   ├── tb_Registro.vhd
│   └── tb_P3.vhd
├── legacy/                   # Prueba de componentes deshabilitada
│   ├── prueba_componentes.vhd
│   └── tb_Componentes.vhd
├── Practica1_DLPs.qpf        # Proyecto Quartus
├── Practica1_DLPs.qsf        # Pines y fuentes (incluye ../punto2... y ../punto3...)
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

# Simulación del punto 3 integrado
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_P3
```

`simular.ps1` lee las entradas `VHDL_FILE` del `.qsf` del módulo, por lo que compila
también las fuentes externas de los puntos 2 y 3 además de `src/` y `sim/`.

También se puede hacer manualmente desde esta carpeta:

```powershell
& "D:\Programas\Quartus ii\quartus\bin64\quartus_sh.exe" --flow compile Practica1_DLPs

vlib work
vcom -93 src/*.vhd sim/*.vhd ../punto2_registro_desplazamiento/src/*.vhd `
          ../punto3_contador/src/*.vhd
vsim -c -do "run -all; quit -f" tb_Ruleta
```

Para simular más rápido, los testbenches usan `CLK_HZ = 10_000`, manteniendo los
tiempos reales de antirrebote y de giro. `tb_P3` usa `TICK_HZ = 20` (50 ms por
cuenta) para que cada valor sea observable sin ambigüedad con el display
multiplexado.
