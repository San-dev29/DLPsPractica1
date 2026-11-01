# Punto 3 — Contador binario de 4 bits ascendente/descendente

Contador binario de 4 bits con dirección y habilitación por interruptores del
**DIP switch 1**, reset por pulsador **activo bajo** y salida al **display de
7 segmentos** (0–F), implementado en VHDL para la tarjeta
**Cyclone II EP2C5T144C8N**.

## 1. Funcionamiento

- **Dirección (`dir`)**: se toma del **DIP switch 1, interruptor 3 (pin 126)**.
  - `dir = '1'`: cuenta ascendente (`0, 1, 2, ..., 15, 0, ...`).
  - `dir = '0'`: cuenta descendente (`0, 15, 14, ..., 0, 15, ...`).
- **Habilitación / inicio (`hab`)**: se toma del **DIP switch 1, interruptor 4
  (pin 132)**.
  - `hab = '1'`: el contador avanza.
  - `hab = '0'`: el contador conserva el valor actual.
- **Reset (`rst_n`)**: se toma del **pulsador con pull-up (pin 144)**, activo
  bajo.
  - `rst_n = '0'` (pulsador presionado): el contador se borra a `0`. El módulo
    `contador_ud` tiene un **reset asíncrono activo bajo**; en el nivel superior
    el pulsador se antirrebota (20 ms) antes de aplicarlo.
  - `rst_n = '1'` (pulsador liberado): el contador funciona normalmente.
- **Display**: el valor binario se decodifica a 7 segmentos y se muestra en el
  **dígito 3 del display (pin 113)**. La salida cubre los 16 valores `0`–`F`
  (los valores 11 y 13 se muestran como `b` y `d` en minúscula).

El contador se relojiza con el **reloj de 50 MHz (pin 17)**, pero un divisor
genera un pulso de habilitación de **2 Hz** (`TICK_HZ`), de modo que el conteo
sea visible. El pulso se usa como *clock enable*; el reloj del contador nunca es
un pulsador.

Al desbordar, el contador da la vuelta de forma natural en 4 bits: asciende de
`15` a `0` y desciende de `0` a `15`.

### Prueba rápida en la tarjeta

1. Verifica que el **pulsador del pin 144** esté liberado (reset inactivo).
2. Coloca el **DIP switch 1, interruptor 3 (pin 126)** en **ON** para contar
   ascendente o en **OFF** para descendente.
3. Coloca el **DIP switch 1, interruptor 4 (pin 132)** en **ON** para habilitar
   el conteo.
4. Observa el **dígito 3 del display (pin 113)**: cambia cada 0,5 s y recorre
   `0`–`F`.
5. Pulsa el **pulsador del pin 144** para llevar el contador a `0`.
6. Pon la habilitación en **OFF**: el display mantiene el último valor.

## 2. Distribución de pines

| Señal | Pin | Componente físico | Tipo | Función / polaridad |
|---|---|---|---|---|
| `clk` | 17 | Oscilador de la placa | Entrada | Reloj de 50 MHz |
| `rst_n` | 144 | Pulsador PB (pull-up; el mismo de la ruleta) | Entrada | Reset **activo bajo** |
| `dir` | 126 | DIP switch 1, interruptor 3 | Entrada | Dirección: 1 = ascendente, 0 = descendente; activo alto |
| `hab` | 132 | DIP switch 1, interruptor 4 | Entrada | Habilitación: 1 = cuenta, 0 = mantiene; activo alto |
| `seg[0]` = A | 96 | Display 7 segmentos, segmento A | Salida | Activo alto |
| `seg[1]` = B | 94 | Display 7 segmentos, segmento B | Salida | Activo alto |
| `seg[2]` = C | 93 | Display 7 segmentos, segmento C | Salida | Activo alto |
| `seg[3]` = D | 92 | Display 7 segmentos, segmento D | Salida | Activo alto |
| `seg[4]` = E | 87 | Display 7 segmentos, segmento E | Salida | Activo alto |
| `seg[5]` = F | 86 | Display 7 segmentos, segmento F | Salida | Activo alto |
| `seg[6]` = G | 79 | Display 7 segmentos, segmento G | Salida | Activo alto |
| `digito` | 113 | Display, dígito 3 | Salida | Habilitación, activo alto |

Notas:

- **Pin 73 DEFECTUOSO: no usar.** Aun con todo desconectado entrega 3.3 V (fijo
  en alto). No se asigna en el `.qsf`.
- El **DIP switch 2** está fuera del diseño (su placa está defectuosa). No se
  usan sus pines (52–72).
- Los interruptores del **DIP switch 1** y los segmentos del display son activos
  en alto, según `docs/especificacion_hardware.md`.
- El pulsador del pin 144 es el único con pull-up (activo bajo) de la tarjeta.
  Por eso el módulo antirrebota con `ACTIVE_LOW = true` y normaliza la señal
  antes de usarla como reset.
- El display es **multiplexado**. Este proyecto enciende solo el **dígito 3** de
  forma permanente; los demás dígitos quedan apagados. Si se integra con los
  otros puntos, el barrido lo administra el `display_mux` del proyecto
  integrado.
- El punto decimal (DP) del display no se usa.

## 3. Arquitectura

```
                 ┌──────────────── Punto3_Contador (top) ────────────────┐
                 │                                                      │
 clk (17) ───────┼──► div_tick (TICK_HZ = 2 Hz) ──► tick ──┐             │
                 │                                         ├──► ena     │
 hab (132) ──────┼──► 2 FF ──► hab_sync ───────────────────┘             │
                 │                                                      │
 dir (126) ──────┼──► 2 FF ──► dir_sync ──────────────┐                  │
                 │                                    ▼                 │
                 │                         ┌──► contador_ud ──► valor   │
                 │   reset de encendido ──►│      (4 bits)              │
 rst_n (144) ────┼──► debounce_btn ──► rst_n_i ──────┘                  │
                 │                                                      │
                 │   valor ──► dec_7seg ──► seg(6..0)                    │
                 │   digito <= '1' ──► digito (113)                     │
                 └──────────────────────────────────────────────────────┘
```

| Archivo | Descripción |
|---|---|
| `src/Punto3_Contador.vhd` | Nivel superior: reset, antirrebote, sincronización, divisor, contador y display |
| `src/contador_ud.vhd` | Contador de 4 bits ascendente/descendente con reset asíncrono activo bajo |
| `src/div_tick.vhd` | Divisor que genera el pulso de conteo (2 Hz por defecto) |
| `src/dec_7seg.vhd` | Decodificador binario → 7 segmentos para `0`–`F` |
| `../punto2_registro_desplazamiento/src/debounce_btn.vhd` | Antirrebote reutilizado del punto 2 (salida de nivel y pulso) |
| `sim/tb_Contador.vhd` | Testbench con 7 pruebas |

El `.qsf` referencia el antirrebote del punto 2 con ruta relativa
(`../punto2_registro_desplazamiento/src/debounce_btn.vhd`); no hay copias
duplicadas. `simular.ps1` lee las entradas `VHDL_FILE` del `.qsf`, por lo que
también compila esa fuente externa.

El contador usa `ieee.numeric_std` (la librería estándar) en lugar de
`ieee.std_logic_arith` / `ieee.std_logic_unsigned`, que son específicas de
Altera y están obsoletas. El resultado funcional es el mismo que el del ejemplo
de referencia, pero con aritmética portable y sin ambigüedades entre `signed` y
`unsigned`.

## 4. Resultados de simulación (ModelSim)

Comando: `.\scripts\simular.ps1 -Modulo punto3_contador -Top tb_Contador`

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reset asíncrono activo bajo | OK — `q = 0` sin esperar flanco de reloj |
| T2 | Cuenta ascendente `0..15` y desbordamiento a `0` | OK |
| T3 | Cuenta descendente `15..0` y desbordamiento a `15` | OK |
| T4 | `hab = 0` congela y `hab = 1` reanuda | OK |
| T5 | Cambio de dirección en marcha | OK — `1 → 0 → 15` |
| T6 | Decodificador 7 segmentos para `0..F` | OK — 16 patrones correctos |
| T7 | Nivel superior: arranque en 0, conteo, habilitación, dirección, reset con pulsador y display | OK |

La simulación usa `CLK_HZ = 10_000`, `TICK_HZ = 1000` y `DB_MS = 5` para
mantener los tiempos reales de conteo y antirrebote sin simulaciones largas.

## 5. Resultados de síntesis

Proyecto `Punto3_Contador.qpf` (Quartus II 13.0 SP1, EP2C5T144C8):

```
Total logic elements   : 119 / 4,608 ( 3 % )
Total registers        :  76
Total pins             :  12 / 89  (13 %)
Worst-case setup slack : 13.813 ns   (positivo, reloj de 50 MHz)
Worst-case hold slack  :  0.499 ns   (positivo)
Full Compilation       : 0 errors, 9 warnings
```

Los warnings son informativos: compilación en paralelo sin licencia, LogicLock
sin licencia, jitter no soportado por Cyclone II, falta de capacitancia de carga
en las 8 salidas del display y `digito` fijo en VCC (es intencional: el dígito 3
queda siempre habilitado). No hay conflictos de pines dedicados y el pin 73
aparece como `RESERVED_INPUT` (no asignado).

## 6. Cómo reproducir

Desde la raíz del repositorio:

```powershell
# Compilación en Quartus
.\scripts\compilar.ps1 -Modulo punto3_contador

# Simulación
.\scripts\simular.ps1 -Modulo punto3_contador -Top tb_Contador
```

También se puede compilar manualmente desde esta carpeta:

```powershell
& "D:\Programas\Quartus ii\quartus\bin64\quartus_sh.exe" --flow compile Punto3_Contador
```

## 7. Integración en el proyecto del punto 5

Este punto se desarrolla como **proyecto independiente** (`Punto3_Contador.qpf`,
con reset en el pulsador del pin 144 activo bajo y display en el dígito 3), pero
**ya está integrado** en `punto5_ruleta/`, que combina los puntos 2, 3 y 5.

En la integración cambian solo el envoltorio y la asignación de pines; los
módulos `contador_ud`, `div_tick` y `dec_7seg` se reutilizan sin modificaciones
(el `.qsf` los referencia con ruta relativa):

| Señal | Pin standalone | Pin integrado | Componente físico en la integración |
|---|---|---|---|
| Reset | 144 (activo bajo) | **74** (activo alto) | Pulsador 1 |
| Start | — (arranca solo) | **75** (activo alto) | Pulsador 2 |
| Dirección | 126 | 126 | DIP switch 1, interruptor 3 |
| Habilitación | 132 | 132 | DIP switch 1, interruptor 4 |
| Display | 113 (dígito 3) | **115** (dígito 4) | Display, dígito 4 |

En el diseño integrado el contador **no arranca solo**: hay que pulsar start
(pulsador 2, pin 75) con la habilitación en 1; el reset (pulsador 1, pin 74)
borra y detiene. El pulsador del pin 144 queda reservado para la ruleta. El
envoltorio es `punto5_ruleta/src/Contador_P3.vhd` y su testbench
`punto5_ruleta/sim/tb_P3.vhd` (8 pruebas).
