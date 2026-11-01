# DLPs — Práctica 1

Repositorio del equipo para la **Práctica 1 de Diseño Lógico Programable (DLPs)**.

Cada punto de la práctica vive en su propia carpeta (`puntoN_<nombre>/`) con su
proyecto Quartus independiente, de modo que se puedan desarrollar y compilar
varios módulos en paralelo sin interferencias.

## Estructura

```
DLPsPractica1/
├── AGENTS.md                  # Reglas: no commitear sin autorización, revisar pines
├── docs/                      # Documentación y especificaciones de hardware
│   ├── EP2C5T144C8N.txt
│   └── especificacion_hardware.md
├── punto2_registro_desplazamiento/  # Punto 2: registro de desplazamiento de 8 bits
│   ├── src/                   # Se instancia desde punto5_ruleta
│   ├── sim/
│   ├── Punto2_Registro.qpf
│   ├── Punto2_Registro.qsf
│   ├── Punto2_Registro.sdc
│   └── README.md
├── punto3_contador/           # Punto 3: contador binario de 4 bits up/down
│   ├── src/                   # Top, contador, divisor y decodificador 7 segmentos
│   ├── sim/
│   ├── Punto3_Contador.qpf
│   ├── Punto3_Contador.qsf
│   ├── Punto3_Contador.sdc
│   └── README.md
├── punto5_ruleta/             # Proyecto integrado: puntos 5 + 2 + 3 en paralelo
│   ├── src/                   # Código VHDL sintetizable (top, ruleta, display, P3)
│   ├── sim/                   # Testbenches (ruleta, registro y contador)
│   ├── legacy/                # Prueba de componentes deshabilitada
│   ├── Practica1_DLPs.qpf     # Proyecto Quartus
│   ├── Practica1_DLPs.qsf     # Pines y fuentes de los puntos 2 y 3
│   ├── Practica1_DLPs.sdc     # Restricciones de reloj
│   └── README.md
├── plantilla/                 # Base para nuevos puntos
│   ├── src/
│   ├── sim/
│   └── README.md
└── scripts/                   # Utilidades de compilación y simulación
    ├── compilar.ps1
    └── simular.ps1
```

## Convención para agregar un módulo

1. Copia la carpeta `plantilla/` y renómbrala como `puntoN_<nombre>` (por ejemplo
   `punto2_contador`).
2. Crea el proyecto Quartus **dentro de esa carpeta** (Project → New), con el
   mismo nombre de la carpeta o del top-level.
3. Coloca el código sintetizable en `src/` y los testbenches en `sim/`.
4. Añade los archivos al proyecto y asigna los pines en el `.qsf`.
5. Documenta el módulo en su `README.md` (pines usados, funcionamiento, pruebas).
6. Compila con `scripts/compilar.ps1 -Modulo puntoN_<nombre>` y verifica 0 errores
   antes de hacer commit.

## Requisitos

- Quartus II 13.0 SP1 (dispositivo **EP2C5T144C8**, familia Cyclone II).
- ModelSim-Altera (incluido con Quartus) para simulación.
- Los archivos generados (`db/`, `incremental_db/`, `output_files/`, `work/`,
  bitstreams, reportes) están excluidos por `.gitignore`.

## Uso rápido

```powershell
# Compilar un módulo
.\scripts\compilar.ps1 -Modulo punto3_contador
.\scripts\compilar.ps1 -Modulo punto5_ruleta

# Simular un módulo
.\scripts\simular.ps1 -Modulo punto3_contador -Top tb_Contador
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Ruleta
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Registro
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_P3
```

`simular.ps1` toma las fuentes `VHDL_FILE` del `.qsf` del módulo, además de `src/` y
`sim/`, así que también compila los módulos externos que instancia el top (por
ejemplo, los puntos 2 y 3 dentro del proyecto del punto 5).

## Módulos

| Punto | Carpeta | Descripción | Estado |
|---|---|---|---|
| 2 | [`punto2_registro_desplazamiento`](punto2_registro_desplazamiento/README.md) | Registro de desplazamiento de 8 bits con entrada serie, enable y reset por pulsadores | ✅ Implementado e integrado en el proyecto del punto 5 |
| 3 | [`punto3_contador`](punto3_contador/README.md) | Contador binario de 4 bits ascendente/descendente, dirección y habilitación por DIP switch, reset/start por pulsadores y salida 0–F al display | ✅ Implementado e integrado en el proyecto del punto 5 |
| 5 | [`punto5_ruleta`](punto5_ruleta/README.md) | **Proyecto integrado**: ruleta de 8 resultados + registro de desplazamiento + contador, con display multiplexado (dígitos 3 y 4). La prueba de componentes está deshabilitada (`legacy/`) | ✅ Implementado |

> **Diseño que se programa en la placa:** `punto5_ruleta/`, que incluye los puntos 5,
> 2 y 3 funcionando al mismo tiempo: la ruleta en el dígito 3, el contador en el
> dígito 4 y el registro en la barra de LEDs 1. Las carpetas de los puntos 2 y 3 se
> mantienen como proyectos independientes y como fuente de los módulos que instancia
> el top integrado (rutas relativas en el `.qsf`).

## Equipo

| Integrante | GitHub |
|---|---|
| _Completar_ | _@usuario_ |

## Flujo de trabajo con Git

```powershell
git pull                      # Actualizar antes de empezar
git checkout -b feat/punto2   # Rama por módulo o tarea
git add .
git commit -m "punto2: descripción breve"
git push -u origin feat/punto2
```

Se recomienda abrir *Pull Request* hacia `main` para que otro integrante revise
antes de integrar.
