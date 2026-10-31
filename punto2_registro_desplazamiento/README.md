# Punto 2 — Registro de desplazamiento de 8 bits

Registro de desplazamiento serie-entrada / paralelo-salida implementado en VHDL
para la tarjeta **Cyclone II EP2C5T144C8N**.

> **Este módulo ya está integrado.** El diseño que se programa en la placa es
> `punto5_ruleta/`, que instancia `Punto2_Registro` **en paralelo** con la ruleta
> (punto 5). Las fuentes de esta carpeta se referencian desde el `.qsf` de
> `punto5_ruleta` con rutas relativas, y la prueba de componentes se deshabilitó
> para reutilizar sus pines. El proyecto `Punto2_Registro.qpf` de esta carpeta se
> conserva para probar el punto 2 por separado. Ver
> [`../punto5_ruleta/README.md`](../punto5_ruleta/README.md) para la integración,
> el pinout completo y los resultados finales.

## 1. Funcionamiento

- `din` es el dato serie y se toma del **DIP switch 1, bit 0**.
- `enable` es la habilitación y se toma del **DIP switch 1, bit 1**.
  - `enable = '1'`: cada pulso de reloj introduce `din` en la etapa 0 y desplaza
    el contenido hacia la etapa 7.
  - `enable = '0'`: el registro conserva su contenido.
- `btn_clk` es un pulsador que actúa como reloj. Se antirrebota y genera **un
  solo pulso por pulsación**, aunque se mantenga presionado.
- `btn_rst` es un pulsador de reset. Se antirrebota y su nivel se usa como reset
  **sincrónico activo alto**.
- `led(7..0)` entrega una salida por cada etapa del registro. Se conecta a la
  **barra de LEDs 1** de la tarjeta (activa alta).

Dirección del desplazamiento:

```
          din ──► q(0) ──► q(1) ──► q(2) ──► ... ──► q(7)
                   │        │        │                  │
                 led(0)   led(1)   led(2)   ...       led(7)
```

`q(0)` contiene el bit más reciente y `q(7)` el más antiguo.

El registro se relojiza con el reloj de 50 MHz de la placa. El pulso
antirrebotado del pulsador se usa como habilitación de un ciclo, de modo que no
se utiliza un pulsador directamente como reloj digital.

### Prueba rápida en la tarjeta

1. Coloca `enable` (**DIP switch 1, interruptor 2, pin 122**) en **ON**.
2. Coloca `din` (**DIP switch 1, interruptor 1, pin 120**) en **ON** o **OFF** según
   el bit que quieras introducir.
3. Pulsa el **pulsador 3 (pin 100)** una vez por cada bit. La **barra de LEDs 1**
   muestra el contenido del registro: `led[0]` es la etapa más reciente y `led[7]`
   la más antigua.
4. Pulsa el **pulsador 4 (pin 97)** para borrar el registro.
5. Si `enable` está en **OFF**, los pulsos de reloj no modifican el registro.

## 2. Distribución de pines

| Señal | Pin | Componente físico | Tipo | Función / polaridad |
|---|---|---|---|---|
| `clk` | 17 | Oscilador de la placa | Entrada | 50 MHz |
| `din` | 120 | DIP switch 1, interruptor 1 | Entrada | Dato serie; activo alto |
| `enable` | 122 | DIP switch 1, interruptor 2 | Entrada | Habilitación; activo alto |
| `btn_clk` | 100 | Pulsador 3 | Entrada | Reloj del registro; activo alto (pull-down) |
| `btn_rst` | 97 | Pulsador 4 | Entrada | Reset; activo alto (pull-down) |
| `led[0]` | 121 | Barra de LEDs 1, LED 1 | Salida | Etapa 0; activo alto |
| `led[1]` | 125 | Barra de LEDs 1, LED 2 | Salida | Etapa 1; activo alto |
| `led[2]` | 129 | Barra de LEDs 1, LED 3 | Salida | Etapa 2; activo alto |
| `led[3]` | 133 | Barra de LEDs 1, LED 4 | Salida | Etapa 3; activo alto |
| `led[4]` | 135 | Barra de LEDs 1, LED 5 | Salida | Etapa 4; activo alto |
| `led[5]` | 137 | Barra de LEDs 1, LED 6 | Salida | Etapa 5; activo alto |
| `led[6]` | 141 | Barra de LEDs 1, LED 7 | Salida | Etapa 6; activo alto |
| `led[7]` | 143 | Barra de LEDs 1, LED 8 | Salida | Etapa 7; activo alto |

Notas:

- **No se usa el pin 73** (defectuoso: entrega 3.3 V con todo desconectado).
- Se usan los pines 100 y 97 para los pulsadores, que son I/O normales. Se
  evitaron los pines 74 y 75 (entradas de reloj/PLL) y el 76 (`nCEO`) para no
  depender de funciones dedicadas. El fitter no reportó conflictos en 100 ni 97.
- Los bits del DIP switch se sincronizan con dos biestables antes de entrar al
  registro.
- El pin 76 (`LVDS41p/nCEO`) se deja liberado como I/O normal con
  `CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION = USE AS REGULAR IO`, aunque este
  diseño no lo usa.

## 3. Arquitectura

```
                 ┌──────────────── Punto2_Registro ────────────────┐
                 │                                                │
 btn_clk ────────┼──► debounce_btn ──► pulso ──┐                  │
                 │                             │                  │
 enable ─────────┼──► 2 FF ──► enable_sync ───┴──► enable_pulse   │
                 │                                                │
 din ────────────┼──► 2 FF ──► din_sync ─────────► registro ──────┼──► led(7..0)
                 │                                                │
 btn_rst ────────┼──► debounce_btn ──► nivel ─────► rst            │
                 └────────────────────────────────────────────────┘
```

| Archivo | Descripción |
|---|---|
| `src/Punto2_Registro.vhd` | Nivel superior: antirrebote, sincronización y registro |
| `src/debounce_btn.vhd` | Antirrebote genérico con salida de nivel y pulso |
| `src/registro_desplazamiento.vhd` | Registro de 8 bits con entrada serie |
| `sim/tb_Registro.vhd` | Testbench con 6 pruebas |

## 4. Resultados de simulación (ModelSim)

| Prueba | Descripción | Resultado |
|---|---|---|
| T1 | Reset con pulsador | OK — registro a `0x00` |
| T2 | `enable = 0` bloquea el desplazamiento | OK |
| T3 | Entrada serie de 8 bits | OK — `1,0,1,1,0,0,1,0` → `0xB2` |
| T4 | `enable = 0` conserva el contenido | OK — permanece `0xB2` |
| T5 | Reset con datos cargados | OK — vuelve a `0x00` |
| T6 | Pulsación larga de reloj | OK — un solo desplazamiento |

## 5. Resultados de síntesis

Resultados del proyecto **individual** `Punto2_Registro.qpf` (compilado antes de
integrarlo; en el diseño integrado manda el reporte de `punto5_ruleta`):

```
Total logic elements : 60 / 4,608 ( 1 % )
Total registers      : 46
Total pins           : 13 / 89 ( 15 % )
Worst-case setup slack : 15.160 ns   (positivo)
Worst-case hold slack  :  0.499 ns   (positivo)
Full Compilation     : 0 errors
```

## 6. Cómo reproducir

Desde la raíz del repositorio:

```powershell
# Compilación en Quartus
.\scripts\compilar.ps1 -Modulo punto2_registro_desplazamiento

# Simulación
.\scripts\simular.ps1 -Modulo punto2_registro_desplazamiento -Top tb_Registro
```

También se puede compilar manualmente desde esta carpeta:

```powershell
& "D:\Programas\Quartus ii\quartus\bin64\quartus_sh.exe" --flow compile Punto2_Registro
```
