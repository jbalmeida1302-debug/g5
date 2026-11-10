param(
    [Parameter(Mandatory=$true)][ValidateSet("A","B")][string]$Academia
)
$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$SourceKey = Join-Path $LabRoot "projeto-base\security\update-public-key.xml"
$Target = Join-Path $LabRoot ("academias\academia-teste-" + $Academia)
$TargetDir = Join-Path $Target "security"
$TargetKey = Join-Path $TargetDir "update-public-key.xml"

if (!(Test-Path $SourceKey)) { throw "Chave pública não encontrada. Execute primeiro scripts\gerar-chaves-assinatura.ps1." }
if (!(Test-Path (Join-Path $Target "run.py"))) { throw "Instalação da Academia $Academia não encontrada." }
if (Test-Path $TargetKey) { throw "A academia já possui uma chave pública. Não será substituída automaticamente." }
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
Copy-Item -LiteralPath $SourceKey -Destination $TargetKey
$fingerprint = (Get-FileHash -LiteralPath $TargetKey -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Chave pública instalada na Academia $Academia."
Write-Host "Fingerprint SHA-256: $fingerprint"
Write-Host "Compare este fingerprint com o exibido na geração das chaves antes de confiar nesta instalação."
