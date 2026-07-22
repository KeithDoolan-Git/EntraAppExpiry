<#
    .SYNOPSIS
    Registers a Windows Task Scheduler task that runs Invoke-AppExpiryCheck.ps1
    on a recurring daily schedule.

    .DESCRIPTION
    Wraps Register-ScheduledTask so you don't have to hand-build the
    action/trigger/principal. Run this once, as an administrator, on the
    server that should own the recurring check.

    Runs as SYSTEM by default, which means the certificate used for
    -CertificateThumbprint must live in the LocalMachine\My certificate
    store (not CurrentUser). See USAGE.md for the full unattended-auth setup.

    .PARAMETER TenantId
    Entra ID tenant ID, passed straight through to Invoke-AppExpiryCheck.ps1.

    .PARAMETER ClientId
    App registration (client) ID, passed straight through.

    .PARAMETER CertificateThumbprint
    Thumbprint of the LocalMachine\My certificate, passed straight through.

    .PARAMETER OutputFolder
    Folder reports are written to. Default C:\EntraAppAnalysis\Reports.

    .PARAMETER ExpiringInDays
    Expiry window in days. Default 30.

    .PARAMETER Format
    Report format: Csv or Html. Default Csv.

    .PARAMETER TaskName
    Name of the scheduled task. Default "EntraAppAnalysis - Daily Credential Expiry Check".

    .PARAMETER At
    Time of day to run daily, e.g. '07:00'. Default 07:00.

    .PARAMETER Engine
    Which PowerShell executable to run the script with: powershell.exe
    (built into every Windows Server, default) or pwsh.exe (PowerShell 7,
    if installed).

    .PARAMETER ScriptPath
    Path to Invoke-AppExpiryCheck.ps1. Defaults to the copy next to this
    script.

    .EXAMPLE
    .\Register-AppExpiryScheduledTask.ps1 -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $thumb -At '07:00'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [string]$ClientId,

    [Parameter(Mandatory)]
    [string]$CertificateThumbprint,

    [Parameter()]
    [string]$OutputFolder = 'C:\EntraAppAnalysis\Reports',

    [Parameter()]
    [int]$ExpiringInDays = 30,

    [Parameter()]
    [ValidateSet('Csv', 'Html')]
    [string]$Format = 'Csv',

    [Parameter()]
    [string]$TaskName = 'EntraAppAnalysis - Daily Credential Expiry Check',

    [Parameter()]
    [string]$At = '07:00',

    [Parameter()]
    [ValidateSet('powershell.exe', 'pwsh.exe')]
    [string]$Engine = 'powershell.exe',

    [Parameter()]
    [string]$ScriptPath = (Join-Path $PSScriptRoot 'Invoke-AppExpiryCheck.ps1')
)

$ErrorActionPreference = 'Stop'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated (Administrator) PowerShell session.'
}

if (-not (Test-Path -Path $ScriptPath)) {
    throw "Could not find Invoke-AppExpiryCheck.ps1 at '$ScriptPath'. Pass -ScriptPath explicitly if you moved it."
}

$argumentList = @(
    '-NoProfile'
    '-ExecutionPolicy', 'Bypass'
    '-File', "`"$ScriptPath`""
    '-TenantId', $TenantId
    '-ClientId', $ClientId
    '-CertificateThumbprint', $CertificateThumbprint
    '-OutputFolder', "`"$OutputFolder`""
    '-ExpiringInDays', $ExpiringInDays
    '-Format', $Format
) -join ' '

$action = New-ScheduledTaskAction -Execute $Engine -Argument $argumentList
$trigger = New-ScheduledTaskTrigger -Daily -At $At
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd

Register-ScheduledTask -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Runs EntraAppAnalysis to report on expiring Entra ID app client secrets/certificates.' `
    -Force | Out-Null

Write-Output "Registered scheduled task '$TaskName' to run daily at $At as SYSTEM."
Write-Output "Reports will be written to: $OutputFolder"
