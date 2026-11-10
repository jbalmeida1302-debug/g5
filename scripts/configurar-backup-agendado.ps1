param(
    [Parameter(Mandatory=$true)][ValidateSet("A","B")][string]$Academia,
    [ValidateSet("02:00","03:00","04:00","23:00")][string]$Horario = "02:00",
    [int]$ManterUltimos = 14
)
$ErrorActionPreference = "Stop"
$BackupScript = Join-Path $PSScriptRoot "backup-academia.ps1"
if (!(Test-Path $BackupScript)) { throw "Script backup-academia.ps1 não encontrado." }

$TaskName = "FITGESTAO-Backup-Academia-" + $Academia
$PowerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
$Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$BackupScript`" -Academia $Academia -ManterUltimos $ManterUltimos"
$Action = New-ScheduledTaskAction -Execute $PowerShellExe -Argument $Arguments
$Trigger = New-ScheduledTaskTrigger -Daily -At $Horario
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Backup diário local do FITGESTAO - Academia $Academia" -Force | Out-Null
Write-Host "Agendamento criado: $TaskName"
Write-Host "Horário diário: $Horario"
Write-Host "Executa com o usuário atual quando ele estiver conectado ao Windows."
Write-Host "Retenção configurada: $ManterUltimos backups."
