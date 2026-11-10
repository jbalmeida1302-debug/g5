param(
    [Parameter(Mandatory=$true)][ValidateSet("A","B")][string]$Academia,
    [Parameter(Mandatory=$true)][string]$Backup
)
$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$Target = Join-Path $LabRoot ("academias\academia-teste-" + $Academia)

if (!(Test-Path -LiteralPath $Backup)) { throw "Backup não encontrado: $Backup" }
if (!(Test-Path (Join-Path $Backup "run.py"))) { throw "A pasta indicada não parece conter um backup FITGESTAO válido." }

Write-Warning "Pare o servidor da Academia $Academia com Ctrl+C antes de restaurar."
$Confirm = Read-Host "Digite RESTAURAR para substituir os arquivos da Academia $Academia pelo backup"
if ($Confirm -cne "RESTAURAR") { Write-Host "Operação cancelada."; exit 0 }

# Mantém o ambiente virtual atual, mas restaura código, .env e banco do backup.
Get-ChildItem -LiteralPath $Target -Force | Where-Object { $_.Name -ne ".venv" } | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
}
Get-ChildItem -LiteralPath $Backup -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $Target -Recurse -Force
}
Write-Host "Backup restaurado na Academia $Academia."
