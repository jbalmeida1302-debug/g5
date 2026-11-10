$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $PSScriptRoot
$Base = Join-Path $LabRoot "projeto-base"
$Academies = Join-Path $LabRoot "academias"

if (!(Test-Path (Join-Path $Base "run.py"))) {
    throw "Projeto-base não encontrado em: $Base"
}

New-Item -ItemType Directory -Force -Path $Academies | Out-Null

foreach ($item in @(
    @{ Name = "academia-teste-A"; Port = 5001 },
    @{ Name = "academia-teste-B"; Port = 5002 }
)) {
    $Target = Join-Path $Academies $item.Name
    if (Test-Path $Target) {
        throw "A pasta $Target já existe. Não vou sobrescrever dados. Renomeie ou faça backup antes."
    }

    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Copy-Item -Path (Join-Path $Base "*") -Destination $Target -Recurse -Force

    # Cada instalação recebe seu próprio segredo e seu próprio arquivo .env.
    $Secret = python -c "import secrets; print(secrets.token_urlsafe(48))"
    if ($LASTEXITCODE -ne 0 -or !$Secret) {
        throw "Não foi possível gerar SECRET_KEY. Verifique se Python está instalado e no PATH."
    }
    @(
        "SECRET_KEY=$Secret"
        "PORT=$($item.Port)"
    ) | Set-Content -Path (Join-Path $Target ".env") -Encoding ASCII

    New-Item -ItemType Directory -Force -Path (Join-Path $Target "instance") | Out-Null
    Write-Host "Criada $($item.Name) na porta $($item.Port)"
}

Write-Host ""
Write-Host "Laboratório preparado. As duas academias têm pastas, segredos e bancos independentes."
Write-Host "A: http://127.0.0.1:5001"
Write-Host "B: http://127.0.0.1:5002"
