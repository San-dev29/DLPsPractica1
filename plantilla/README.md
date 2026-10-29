# Plantilla de módulo

Copia esta carpeta para iniciar un nuevo punto de la práctica:

```powershell
Copy-Item -Recurse plantilla puntoN_mi_modulo
```

Luego:

1. Renombra el proyecto Quartus a `puntoN_mi_modulo` (o al nombre del top-level).
2. Coloca el código VHDL en `src/`.
3. Coloca el testbench en `sim/`.
4. Completa este README con:
   - Objetivo del módulo.
   - Tabla de pines (señal, pin, dirección, polaridad).
   - Diagrama o descripción de la arquitectura.
   - Tabla de pruebas realizadas y su resultado.
5. Verifica la compilación con:

```powershell
.\scripts\compilar.ps1 -Modulo puntoN_mi_modulo
```

## Distribución de pines (completar)

| Señal | Pin | Dirección | Polaridad / nota |
|---|---|---|---|
| | | | |

## Pruebas (completar)

| # | Descripción | Resultado |
|---|---|---|
| 1 | | |
