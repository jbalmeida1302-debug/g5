param(
    [Parameter(Mandatory=$true)][ValidateSet("A","B")][string]$Academia,
    [int]$ManterUltimos = 14
)
$ErrorActionPreference = "Stop"
if ($ManterUltimos -lt 1) { throw "ManterUltimos deve ser pelo menos 1." }

$LabRoot = Split-Path -Parent $PSScriptRoot
$Target = Join-Path $LabRoot ("academias\academia-teste-" + $Academia)
$BackupRoot = Join-Path $LabRoot ("backups\academia-teste-" + $Academia)
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Stage = Join-Path $env:TEMP ("fitgestao-backup-" + [guid]::NewGuid().ToString("N"))
$BackupName = "FITGESTAO-" + $Academia + "-backup-" + $Timestamp
$BackupZip = Join-Path $BackupRoot ($BackupName + ".zip")
$HashFile = $BackupZip + ".sha256"
$PythonHelper = Join-Path $PSScriptRoot "backup_sqlite.py"
$ZipHelper = Join-Path $PSScriptRoot "zip_backup.py"

if (!(Test-Path (Join-Path $Target "run.py"))) { throw "Instalação da Academia $Academia não encontrada." }
if (!(Test-Path (Join-Path $Target "instance\academia.db"))) { throw "Banco instance\academia.db não encontrado. Inicie a academia ao menos uma vez." }
if (!(Test-Path $PythonHelper)) { throw "Auxiliar backup_sqlite.py não encontrado." }
if (!(Test-Path $ZipHelper)) { throw "Auxiliar zip_backup.py não encontrado." }

$Version = "desconhecida"
$VersionFile = Join-Path $Target "app\version.py"
if (Test-Path $VersionFile) {
    $VersionText = Get-Content -LiteralPath $VersionFile -Raw
    if ($VersionText -match '(?m)^APP_VERSION\s*=\s*"([^"]+)"') { $Version = $Matches[1] }
}

New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
New-Item -ItemType Directory -Path $Stage | Out-Null

try {
    # Copia código e configurações, mas não inclui venvs, backups antigos ou bytecode.
    & robocopy $Target $Stage /E /R:2 /W:1 /XD ".venv" "venv" "backups" "__pycache__" /XF "*.pyc" "*.pyo" "academia.db"
    $CopyExitCode = $LASTEXITCODE
    if ($CopyExitCode -ge 8) { throw "Falha ao copiar arquivos da instalação (robocopy código $CopyExitCode)." }

    $StageInstance = Join-Path $Stage "instance"
    New-Item -ItemType Directory -Force -Path $StageInstance | Out-Null
    $SourceDb = Join-Path $Target "instance\academia.db"
    $SnapshotDb = Join-Path $StageInstance "academia.db"

    # A API de backup do SQLite cria um snapshot consistente com o banco em uso.
    $Python = Join-Path $Target ".venv\Scripts\python.exe"
    if (!(Test-Path $Python)) { $Python = (Get-Command python -ErrorAction Stop).Source }
    & $Python $PythonHelper $SourceDb $SnapshotDb
    if ($LASTEXITCODE -ne 0 -or !(Test-Path $SnapshotDb)) { throw "Não foi possível criar uma cópia consistente do banco SQLite." }

    $Manifest = [ordered]@{
        application = "FITGESTAO"
        academy = $Academia
        version = $Version
        created_at = (Get-Date).ToString("o")
        database = "instance/academia.db"
        includes_environment_file = (Test-Path (Join-Path $Stage ".env"))
        backup_format = 1
    }
    $Manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Stage "backup-manifest.json") -Encoding UTF8

    & $Python $ZipHelper $Stage $BackupZip
    if ($LASTEXITCODE -ne 0 -or !(Test-Path $BackupZip)) { throw "Não foi possível compactar e validar o backup." }
    $Hash = (Get-FileHash -LiteralPath $BackupZip -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath $HashFile -Value $Hash -Encoding ASCII

    # Retém somente os N backups mais recentes desta academia.
    $OldBackups = Get-ChildItem -LiteralPath $BackupRoot -Filter ("FITGESTAO-" + $Academia + "-backup-*.zip") -File |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip $ManterUltimos
    foreach ($Old in $OldBackups) {
        Remove-Item -LiteralPath $Old.FullName -Force
        $OldHash = $Old.FullName + ".sha256"
        if (Test-Path $OldHash) { Remove-Item -LiteralPath $OldHash -Force }
    }

    Write-Host "Backup concluído: $BackupZip"
    Write-Host "Versão registrada: $Version"
    Write-Host "SHA-256: $Hash"
    Write-Host "Backups mantidos: $ManterUltimos"
}
catch {
    if (Test-Path $BackupZip) { Remove-Item -LiteralPath $BackupZip -Force }
    if (Test-Path $HashFile) { Remove-Item -LiteralPath $HashFile -Force }
    throw
}
finally {
    if (Test-Path $Stage) { Remove-Item -LiteralPath $Stage -Recurse -Force }
}
