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

# Fuentes externas declaradas en el .qsf del modulo (por ejemplo, los modulos
# de otro punto que se instancian desde el nivel superior).
$externas = @()
$qsf = @(Get-ChildItem -Path $dir -Filter *.qsf -File)
if ($qsf.Count -gt 0) {
    $patron = '^\s*set_global_assignment\s+-name\s+VHDL_FILE\s+"?([^"]+)"?\s*$'
    foreach ($linea in Get-Content -Path $qsf[0].FullName) {
        if ($linea -match $patron) {
            $ruta = $Matches[1].Trim()
            if (-not [System.IO.Path]::IsPathRooted($ruta)) {
                $ruta = Join-Path $dir $ruta
            }
            $ruta = [System.IO.Path]::GetFullPath($ruta)
            if (Test-Path $ruta) { $externas += (Get-Item $ruta) }
        }
    }
}

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

    $vistos  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $archivos = @()
    foreach ($f in @($externas + $fuentes + $bancos)) {
        if ($vistos.Add($f.FullName)) { $archivos += $f.FullName }
    }
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
