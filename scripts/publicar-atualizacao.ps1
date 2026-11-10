param(
    [Parameter(Mandatory=$true)][string]$Versao
)
$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$Base = Join-Path $LabRoot "projeto-base"
$Releases = Join-Path $LabRoot "servidor-atualizacoes\releases"
$PrivateKey = Join-Path $LabRoot "chaves\fitgestao-private-key.xml"
$PublicKey = Join-Path $Base "security\update-public-key.xml"

if (!(Test-Path (Join-Path $Base "run.py"))) { throw "Projeto-base não encontrado." }
if ($Versao -notmatch '^\d+\.\d+\.\d+$') { throw "Use uma versão no formato X.Y.Z, por exemplo 1.0.2." }
if (!(Test-Path $PrivateKey)) { throw "Chave privada não encontrada. Execute scripts\gerar-chaves-assinatura.ps1." }
if (!(Test-Path $PublicKey)) { throw "Chave pública não encontrada no projeto-base." }

$VersionFile = Join-Path $Base "app\version.py"
$VersionContent = Get-Content $VersionFile -Raw
if ($VersionContent -notmatch '(?m)^APP_VERSION\s*=\s*".*?"') { throw "APP_VERSION não foi encontrada em app\version.py." }
$VersionContent = [regex]::Replace($VersionContent, '(?m)^APP_VERSION\s*=\s*".*?"', ('APP_VERSION = "' + $Versao + '"'))
Set-Content -Path $VersionFile -Value $VersionContent -Encoding UTF8

New-Item -ItemType Directory -Force -Path $Releases | Out-Null
$Stage = Join-Path $env:TEMP ("fitgestao-release-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $Stage | Out-Null
$ZipPath = Join-Path $Releases ("FITGESTAO-" + $Versao + ".zip")
$SignaturePath = $ZipPath + ".sig"

try {
    Get-ChildItem -LiteralPath $Base -Force | ForEach-Object {
        if ($_.Name -in @(".env", ".venv", "venv", "instance", "backups", "academias")) { return }
        Copy-Item -LiteralPath $_.FullName -Destination $Stage -Recurse -Force
    }
    Get-ChildItem -Path $Stage -Recurse -Force | Where-Object {
        $_.FullName -match '[\\/](__pycache__|\.venv|venv|instance|backups)[\\/]' -or
        $_.Name -match '\.(pyc|pyo|db|sqlite|sqlite3)$' -or $_.Name -eq ".env"
    } | Sort-Object FullName -Descending | ForEach-Object {
        if ($_.PSIsContainer) { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
        else { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }

    if (Test-Path $ZipPath) { throw "Essa versão já existe: $ZipPath" }
    if (Test-Path $SignaturePath) { throw "Já existe uma assinatura para essa versão: $SignaturePath" }
    Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $ZipPath -CompressionLevel Optimal

    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    try {
        $privateXml = Get-Content -LiteralPath $PrivateKey -Raw
        $rsa.FromXmlString($privateXml)
        $packageBytes = [System.IO.File]::ReadAllBytes($ZipPath)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            $signatureBytes = $rsa.SignData($packageBytes, $sha256)
            [System.IO.File]::WriteAllBytes($SignaturePath, $signatureBytes)
        }
        finally { $sha256.Dispose() }
    }
    finally { $rsa.Dispose() }

    $Hash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -Path ($ZipPath + ".sha256") -Value $Hash -Encoding ASCII
    Write-Host "Pacote publicado e assinado: $ZipPath"
    Write-Host "Assinatura digital: $SignaturePath"
    Write-Host "SHA-256 do pacote: $Hash"
    Write-Host "A publicação não instala a atualização em nenhuma academia."
}
finally { if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force } }
