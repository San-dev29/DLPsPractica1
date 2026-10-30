# AGENTS.md — Reglas de trabajo del repositorio

Instrucciones para cualquier agente (humano o IA) que modifique este repositorio.

## 1. No hacer commit ni push sin autorización

- **No ejecutar `git commit` ni `git push`** hasta que el usuario lo indique
  explícitamente. La única excepción es el commit inicial del repositorio, que ya
  fue autorizado.
- Un `git add` o dejar cambios en el árbol de trabajo es aceptable; el commit no.
- Motivo: **que el proyecto compile y simule no garantiza que funcione en la
  placa.** La validación real solo ocurre al programar el FPGA y probar el
  hardware. El usuario decide cuándo un cambio está listo para versionarse.
- Antes de commitear, el usuario debe confirmar la prueba física. Si no la ha
  confirmado, no commitear aunque la compilación tenga 0 errores.

## 2. Verificar las funciones especiales de los pines antes de asignarlos

Antes de agregar un `set_location_assignment` en cualquier `.qsf`:

1. Consultar el pinout del dispositivo (**EP2C5T144C8**) y la documentación de la
   placa en `docs/`.
2. Revisar si el pin tiene una **función especial o dedicada**, por ejemplo:
   - Entradas de reloj dedicadas / entradas de PLL (`CLK[0..3]`, `PLL*_IN`).
   - Pines de configuración (`DCLK`, `DATA0`, `nCE`, `nCONFIG`, `CONF_DONE`,
     `nSTATUS`, `MSEL*`).
   - Pines de JTAG (`TCK`, `TDI`, `TDO`, `TMS`, `TRST`).
   - Pines de alimentación, tierra o reguladores internos.
3. **Aunque el usuario indique un orden o una lista de pines**, verificar cada
   uno y advertir si se está usando una función dedicada como I/O normal.
   Ejemplo real de este proyecto: los pines 74 y 75 (entradas de reloj/PLL) y el
   76 (`nCEO`) se usaron como pulsadores; funcionan como I/O, pero deben revisarse
   los warnings del fitter y confirmarse en la placa.
4. Revisar la lista de pines defectuosos de la sección 6 y **no asignar** ninguno
   de ellos.
5. Compilar y revisar los mensajes del fitter (`quartus_sh --flow compile`);
   no ignorar warnings de pines dedicados, de configuración o de bancos de I/O.
6. Si hay conflicto o riesgo, informar al usuario antes de continuar.

## 3. Entorno y herramientas

- Quartus II **13.0 SP1** (Cyclone II EP2C5T144C8). No usar Quartus Prime 24.x:
  no soporta Cyclone II.
- ModelSim-Altera incluido con Quartus para simulación.
- Scripts del repositorio:
  - `scripts\compilar.ps1 -Modulo <carpeta>`
  - `scripts\simular.ps1 -Modulo <carpeta> -Top <testbench>`

## 4. Estructura y convenciones

- Un módulo por punto en `puntoN_<nombre>/` con `src/` (sintetizable) y `sim/`
  (testbenches).
- El nivel superior solo instancia módulos y genera señales comunes (reloj,
  reset); la lógica va en módulos reutilizables.
- No versionar archivos generados (`db/`, `incremental_db/`, `output_files/`,
  `work/`, bitstreams, reportes); están en `.gitignore`.
- Mantener actualizado el `README.md` del módulo (pines, arquitectura, pruebas y
  resultados de síntesis) cuando cambie el diseño.
- Reportar siempre: resultados de compilación (0 errores, slack), resultados de
  simulación y pines realmente asignados según `output_files/*.pin`.

## 5. Polaridades de la placa

- Reloj: `PIN_17`, 50 MHz.
- Pulsador de la ruleta: `PIN_144`, pull-up, **activo bajo**.
- DIP switch 1, pulsadores de prueba y barras de LEDs: **activos en alto**
  (pull-down / resistencia a GND), según `docs/especificacion_hardware.md`.
- LEDs D2/D4/D5: **activos en bajo**.

Si el hardware real difiere, ajustar las constantes `DIP_ACTIVO_BAJO` /
`BTN_ACTIVO_BAJO` del módulo correspondiente y documentarlo.

## 6. Pines y componentes defectuosos (no usar)

| Elemento | Detalle | Estado |
|---|---|---|
| **`PIN_73`** | Aun con todo desconectado entrega **3.3 V** (fijo en alto); no sirve como entrada. | **DEFECTUOSO — no asignar** |
| DIP switch 2 (pines 52–72) | La placa del DIP switch está defectuosa (la FPGA no). Se retiró del diseño. | **No usar** |

Reglas:
- No asignar `PIN_73` en ningún `.qsf`, ni siquiera como salida o tri-estado.
- Si una lista de pines del usuario incluye uno de estos, avisar y proponer una
  alternativa antes de continuar.
- Al detectar un pin nuevo defectuoso, agregarlo a esta tabla y al `README.md`
  del módulo correspondiente.

