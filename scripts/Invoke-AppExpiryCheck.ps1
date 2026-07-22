<#
    .SYNOPSIS
    Runs an unattended Entra app credential expiry check and writes a report.

    .DESCRIPTION
    Intended to be invoked from Windows Task Scheduler (see
    Register-AppExpiryScheduledTask.ps1 in this same folder) or any other
    scheduler. Connects to Microsoft Graph using app-only certificate auth,
    pulls credentials expiring within the given window, and writes a
    timestamped report. If nothing is expiring, no report file is written.

    .PARAMETER TenantId
    Entra ID tenant ID.

    .PARAMETER ClientId
    App registration (client) ID used for app-only auth.

    .PARAMETER CertificateThumbprint
    Thumbprint of the certificate used to authenticate the app registration.
    For a SYSTEM-run scheduled task, this certificate must be installed in
    the LocalMachine\My store (see USAGE.md).

    .PARAMETER OutputFolder
    Folder to write the report into. Created if it doesn't exist. Defaults to
    a "Reports" folder next to this script.

    .PARAMETER ExpiringInDays
    Only report credentials expiring within this many days. Default 30.

    .PARAMETER Format
    Report format: Csv or Html. Default Csv.

    .EXAMPLE
    .\Invoke-AppExpiryCheck.ps1 -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $thumb -ExpiringInDays 30
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
    [string]$OutputFolder = (Join-Path $PSScriptRoot 'Reports'),

    [Parameter()]
    [int]$ExpiringInDays = 30,

    [Parameter()]
    [ValidateSet('Csv', 'Html')]
    [string]$Format = 'Csv'
)

$ErrorActionPreference = 'Stop'

# Prefer a sibling checkout of the module (git clone layout); fall back to
# an installed copy on $env:PSModulePath (e.g. after Install-Module).
$moduleManifest = Join-Path $PSScriptRoot '..\EntraAppExpiry\EntraAppExpiry.psd1'
if (Test-Path -Path $moduleManifest) {
    Import-Module $moduleManifest -Force
}
else {
    Import-Module EntraAppExpiry -ErrorAction Stop
}

try {
    Connect-AppExpiry -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint

    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $extension = if ($Format -eq 'Html') { 'html' } else { 'csv' }
    $reportPath = Join-Path $OutputFolder "AppExpiryReport_$timestamp.$extension"

    $results = Get-AppExpiry -ExpiringInDays $ExpiringInDays

    if ($results) {
        $results | Export-AppExpiryReport -Path $reportPath -Format $Format
        Write-Output "Wrote report with $($results.Count) expiring credential(s) to $reportPath"
    }
    else {
        Write-Output "No credentials expiring within $ExpiringInDays day(s). No report written."
    }
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
