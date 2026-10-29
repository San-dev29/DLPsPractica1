param(
    [Parameter(Mandatory = $true)]
    [string]$Modulo,

    [string]$Top = "",

    [switch]$Wave
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$dir  = Join-Path $raiz $Modulo

if (-not (Test-Path $dir)) {
    Write-Error "No existe la carpeta del modulo: $dir"
}

# Localizar ModelSim-Altera
$candidatos = @(
    "D:\Programas\Quartus ii\modelsim_ase\win32aloem",
    "C:\altera\13.0sp1\modelsim_ase\win32aloem",
    "C:\altera\13.0\modelsim_ase\win32aloem",
    "C:\intelFPGA\modelsim_ase\win32aloem"
)
$modelsim = $null
foreach ($c in $candidatos) {
    if (Test-Path (Join-Path $c "vcom.exe")) { $modelsim = $c; break }
}
if (-not $modelsim) {
    Write-Error "No se encontro ModelSim-Altera. Ajusta las rutas de este script."
}

$vlib = Join-Path $modelsim "vlib.exe"
$vcom = Join-Path $modelsim "vcom.exe"
$vsim = Join-Path $modelsim "vsim.exe"

$fuentes = @(Get-ChildItem -Path (Join-Path $dir "src") -Filter *.vhd | Sort-Object Name)
$bancos  = @(Get-ChildItem -Path (Join-Path $dir "sim") -Filter *.vhd | Sort-Object Name)
if ($fuentes.Count -eq 0) { Write-Error "No hay archivos VHDL en $dir\src" }

if (-not $Top) {
    if ($bancos.Count -gt 0) {
        $Top = [System.IO.Path]::GetFileNameWithoutExtension($bancos[0].Name)
    }
    else {
        Write-Error "Indica el testbench con -Top <entidad>"
    }
}

Push-Location $dir
try {
    if (-not (Test-Path "work")) { & $vlib work | Out-Null }

    $archivos = @($fuentes + $bancos | ForEach-Object { $_.FullName })
    & $vcom -93 @archivos
    if ($LASTEXITCODE -ne 0) { Write-Error "Error al compilar con vcom." }

    if ($Wave) {
        & $vsim -do "run -all" $Top
    }
    else {
        & $vsim -c -do "run -all; quit -f" $Top
    }
}
finally {
    Pop-Location
}
