$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $LabRoot "academias\academia-teste-B"

if (!(Test-Path (Join-Path $Project "run.py"))) {
    throw "Instalação da Academia B não encontrada. Execute primeiro scripts\preparar-laboratorio.ps1."
}

Set-Location $Project
if (!(Test-Path ".venv\Scripts\python.exe")) {
    python -m venv .venv
}

& ".venv\Scripts\python.exe" -m pip install --upgrade pip
& ".venv\Scripts\python.exe" -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar dependências." }

$env:PORT = "5002"
& ".venv\Scripts\python.exe" run.py
