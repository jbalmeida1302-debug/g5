param()
$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$Base = Join-Path $LabRoot "projeto-base"
$PrivateDir = Join-Path $LabRoot "chaves"
$PrivateKey = Join-Path $PrivateDir "fitgestao-private-key.xml"
$PublicDir = Join-Path $Base "security"
$PublicKey = Join-Path $PublicDir "update-public-key.xml"

if (Test-Path $PrivateKey) { throw "A chave privada já existe. Não será sobrescrita: $PrivateKey" }
if (Test-Path $PublicKey) { throw "A chave pública já existe. Não será sobrescrita: $PublicKey" }
New-Item -ItemType Directory -Force -Path $PrivateDir, $PublicDir | Out-Null

$rsa = New-Object -TypeName System.Security.Cryptography.RSACryptoServiceProvider -ArgumentList 3072
try {
    $rsa.PersistKeyInCsp = $false
    $privateXml = $rsa.ToXmlString($true)
    $publicXml = $rsa.ToXmlString($false)
    Set-Content -LiteralPath $PrivateKey -Value $privateXml -Encoding ASCII -NoNewline
    Set-Content -LiteralPath $PublicKey -Value $publicXml -Encoding ASCII -NoNewline
}
finally { $rsa.Dispose() }

# Restringe a chave privada ao usuário atual e ao SYSTEM, quando possível.
try {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls.exe $PrivateKey /inheritance:r /grant:r "$identity`:(F)" "SYSTEM`:(F)" | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Warning "Não foi possível ajustar as permissões NTFS automaticamente. Proteja a pasta chaves manualmente." }
}
catch { Write-Warning "Não foi possível ajustar as permissões NTFS automaticamente. Proteja a pasta chaves manualmente." }

$fingerprint = (Get-FileHash -LiteralPath $PublicKey -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Par de chaves criado com sucesso."
Write-Host "Chave privada (NÃO COMPARTILHE): $PrivateKey"
Write-Host "Chave pública: $PublicKey"
Write-Host "Fingerprint SHA-256 da chave pública: $fingerprint"
Write-Warning "Faça uma cópia de segurança segura da chave privada. Se ela for perdida, os pacotes futuros precisarão de uma nova chave pública instalada em cada academia."
