param(
    [Parameter(Mandatory=$true)][ValidateSet("A","B")][string]$Academia,
    [Parameter(Mandatory=$true)][string]$Pacote
)
$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$Target = Join-Path $LabRoot ("academias\academia-teste-" + $Academia)
$BackupRoot = Join-Path $LabRoot ("backups\academia-teste-" + $Academia)

if (!(Test-Path (Join-Path $Target "run.py"))) { throw "Instalação da Academia $Academia não encontrada." }
if (!(Test-Path -LiteralPath $Pacote)) { throw "Pacote não encontrado: $Pacote" }
$SignatureFile = $Pacote + ".sig"
$PublicKey = Join-Path $Target "security\update-public-key.xml"
if (!(Test-Path -LiteralPath $SignatureFile)) { throw "Assinatura digital (.sig) não encontrada. Pacote recusado." }
if (!(Test-Path -LiteralPath $PublicKey)) { throw "Chave pública ainda não instalada nesta academia. Execute scripts\instalar-chave-publica.ps1 -Academia $Academia." }

# A assinatura RSA/SHA-256 autentica o pacote inteiro; o hash .sha256 é apenas conferência adicional.
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
try {
    $publicXml = Get-Content -LiteralPath $PublicKey -Raw
    $rsa.FromXmlString($publicXml)
    $packageBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Pacote).Path)
    $signatureBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $SignatureFile).Path)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        if (!$rsa.VerifyData($packageBytes, $sha256, $signatureBytes)) {
            throw "Assinatura digital inválida. O pacote pode ter sido alterado ou não foi assinado pela chave oficial."
        }
    }
    finally { $sha256.Dispose() }
}
finally { $rsa.Dispose() }

$HashFile = $Pacote + ".sha256"
if (Test-Path -LiteralPath $HashFile) {
    $Expected = (Get-Content -LiteralPath $HashFile -Raw).Trim().ToLowerInvariant()
    $Actual = (Get-FileHash -LiteralPath $Pacote -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Expected -ne $Actual) { throw "SHA-256 não confere. Atualização cancelada." }
}
Write-Host "Assinatura digital válida: pacote autenticado pelo publicador oficial."

Write-Warning "Antes de continuar, confirme que o servidor da Academia $Academia foi parado com Ctrl+C."
$Confirm = Read-Host "Digite ATUALIZAR para criar backup e aplicar o pacote somente na Academia $Academia"
if ($Confirm -cne "ATUALIZAR") { Write-Host "Operação cancelada."; exit 0 }

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Backup = Join-Path $BackupRoot ("antes-da-atualizacao-" + $Stamp)
$Stage = Join-Path $env:TEMP ("fitgestao-update-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
New-Item -ItemType Directory -Path $Backup | Out-Null
New-Item -ItemType Directory -Path $Stage | Out-Null

try {
    # Backup integral da instalação, preservando inclusive .env e instance/banco.
    Get-ChildItem -LiteralPath $Target -Force | Where-Object { $_.Name -ne ".venv" } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Backup -Recurse -Force
    }

    Expand-Archive -LiteralPath $Pacote -DestinationPath $Stage -Force

    # Defesa adicional: pacote não pode substituir configurações nem dados locais.
    if ((Test-Path (Join-Path $Stage ".env")) -or (Test-Path (Join-Path $Stage "instance"))) {
        throw "Pacote contém configuração ou dados locais. Atualização recusada."
    }

    Get-ChildItem -LiteralPath $Stage -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Target -Recurse -Force
    }

    Write-Host "Atualização aplicada somente na Academia $Academia."
    Write-Host "Backup criado em: $Backup"
    Write-Host "Inicie a academia e valide login, alunos, pagamentos e telas principais."
    Write-Host "Se houver problema, use scripts\restaurar-backup.ps1 com o caminho do backup acima."
}
catch {
    Write-Error ("Falha na atualização: " + $_.Exception.Message)
    Write-Warning "Os arquivos anteriores estão preservados no backup: $Backup"
    throw
}
finally {
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
}
