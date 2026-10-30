# DLPs — Práctica 1

Repositorio del equipo para la **Práctica 1 de Diseño Lógico Programable (DLPs)**.

Cada punto de la práctica vive en su propia carpeta (`puntoN_<nombre>/`) con su
proyecto Quartus independiente, de modo que se puedan desarrollar y compilar
varios módulos en paralelo sin interferencias.

## Estructura

```
DLPsPractica1/
├── docs/                      # Documentación y especificaciones de hardware
│   ├── EP2C5T144C8N.txt
│   └── especificacion_hardware.md
├── punto5_ruleta/             # Punto 5: ruleta de 8 resultados
│   ├── src/                   # Código VHDL sintetizable
│   ├── sim/                   # Testbenches
│   ├── Practica1_DLPs.qpf     # Proyecto Quartus
│   ├── Practica1_DLPs.qsf     # Asignaciones de pines
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
.\scripts\compilar.ps1 -Modulo punto5_ruleta

# Simular un módulo
.\scripts\simular.ps1 -Modulo punto5_ruleta -Top tb_Ruleta
```

## Módulos

| Punto | Carpeta | Descripción | Estado |
|---|---|---|---|
| 5 | [`punto5_ruleta`](punto5_ruleta/README.md) | Ruleta de 8 resultados + prueba de DIP switches, barras de LEDs y 4 pulsadores | ✅ Implementado |

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
