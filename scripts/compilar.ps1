param(
    [Parameter(Mandatory = $true)]
    [string]$Modulo,

    [string]$Quartus = ""
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$dir  = Join-Path $raiz $Modulo

if (-not (Test-Path $dir)) {
    Write-Error "No existe la carpeta del modulo: $dir"
}

$proyecto = Get-ChildItem -Path $dir -Filter *.qpf | Select-Object -First 1
if (-not $proyecto) {
    Write-Error "No se encontro ningun archivo .qpf en $dir"
}

# Localizar Quartus 13.0 SP1 (unico que soporta Cyclone II).
# Orden: parametro -Quartus, rutas habituales, variable QUARTUS_ROOTDIR.
$candidatos = @(
    "D:\Programas\Quartus ii\quartus",
    "C:\altera\13.0sp1\quartus",
    "C:\altera\13.0\quartus",
    "C:\altera\quartus",
    "C:\intelFPGA\13.0sp1\quartus"
)

if ($Quartus) {
    $candidatos = @($Quartus) + $candidatos
}
elseif ($env:QUARTUS_ROOTDIR) {
    $candidatos = $candidatos + @($env:QUARTUS_ROOTDIR)
}

foreach ($c in $candidatos) {
    if (Test-Path (Join-Path $c "bin64\quartus_sh.exe")) { $quartus = $c; break }
    if (Test-Path (Join-Path $c "bin\quartus_sh.exe"))     { $quartus = $c; break }
}
if (-not $quartus) {
    Write-Error ("No se encontro Quartus 13.0 SP1. Usa -Quartus <ruta> o define " +
                 "QUARTUS_ROOTDIR apuntando a la instalacion de Quartus II 13.0.")
}

$quartus_sh = Join-Path $quartus "bin64\quartus_sh.exe"
if (-not (Test-Path $quartus_sh)) {
    $quartus_sh = Join-Path $quartus "bin\quartus_sh.exe"
}

$nombre = [System.IO.Path]::GetFileNameWithoutExtension($proyecto.Name)
Write-Host "Compilando $nombre en $dir ..." -ForegroundColor Cyan

Push-Location $dir
try {
    & $quartus_sh --flow compile $nombre
    $codigo = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($codigo -ne 0) {
    Write-Error "La compilacion fallo (codigo $codigo). Revisa los mensajes anteriores."
}
Write-Host "Compilacion finalizada correctamente." -ForegroundColor Green
