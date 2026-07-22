# EntraAppExpiry

A small, dependency-light PowerShell module that reports on Entra ID (Azure AD) app registration **client secret** and **certificate** expiry — so you find out from a report, not an outage.

## Why

Every Entra ID app registration's client secrets and certificates have an expiry date. When one lapses silently, whatever depends on it breaks with no warning. This module gives you a quick way to see what's expiring, on demand or on a schedule.

**New here?** [USAGE.md](USAGE.md) has the full step-by-step walkthrough, including unattended/scheduled setup. This README is the short version.

## Requirements

- PowerShell 5.1+ or PowerShell 7+
- [`Microsoft.Graph.Authentication`](https://www.powershellgallery.com/packages/Microsoft.Graph.Authentication) and [`Microsoft.Graph.Applications`](https://www.powershellgallery.com/packages/Microsoft.Graph.Applications) (installed automatically as module dependencies — not the full `Microsoft.Graph` meta-module)
- An account or app registration with the `Application.Read.All` Graph permission

## Install

Not yet published to the PowerShell Gallery. Until then, install from source:

```powershell
git clone https://github.com/KeithDoolan-Git/EntraAppExpiry.git
Import-Module ./EntraAppExpiry/EntraAppExpiry/EntraAppExpiry.psd1
```

Once published:

```powershell
Install-Module EntraAppExpiry
```

## Quick start

```powershell
# Interactive sign-in
Connect-AppExpiry

# Everything expiring in the next 30 days
Get-AppExpiry -ExpiringInDays 30

# Export a report
Get-AppExpiry -ExpiringInDays 30 | Export-AppExpiryReport -Path .\expiry-report.html -Format Html
```

### Unattended / scheduled use

For a scheduled task or CI job, use app-only auth with a certificate instead of interactive sign-in:

```powershell
Connect-AppExpiry -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $thumbprint
Get-AppExpiry -ExpiringInDays 14 | Export-AppExpiryReport -Path .\expiry-report.csv
```

The app registration used for this needs the `Application.Read.All` **application** permission, admin-consented.

### Running it on a schedule (Task Scheduler)

`scripts/` has a ready-made runner and a registration helper — no need to hand-build a scheduled task:

```powershell
# One-time: create the scheduled task (elevated PowerShell, on the server)
.\scripts\Register-AppExpiryScheduledTask.ps1 `
    -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $thumbprint `
    -OutputFolder 'C:\EntraAppExpiry\Reports' -ExpiringInDays 30 -At '07:00'
```

This registers a daily task that runs `scripts/Invoke-AppExpiryCheck.ps1`, which connects, checks, and writes a timestamped CSV/HTML report — no file is written if nothing is expiring. Full setup (including the one-time app registration + certificate steps) is in [USAGE.md](USAGE.md).

## Cmdlets

| Cmdlet | Description |
|---|---|
| `Connect-AppExpiry` | Connects to Microsoft Graph (interactive or app-only cert auth) |
| `Get-AppExpiry` | Returns one object per client secret/certificate with `DaysUntilExpiry` |
| `Export-AppExpiryReport` | Writes `Get-AppExpiry` output to CSV or HTML |

## Roadmap

- [ ] Publish to PowerShell Gallery

## Development

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Force
Install-Module PSScriptAnalyzer -Force

Invoke-ScriptAnalyzer -Path ./EntraAppExpiry -Recurse
Invoke-Pester -Path ./Tests
```

To publish a new version: bump `ModuleVersion` in `EntraAppExpiry/EntraAppExpiry.psd1`, tag the release `vX.Y.Z`, and push the tag — the `publish.yml` workflow handles the rest (requires a `PSGALLERY_API_KEY` repo secret).

## License

MIT — see [LICENSE](LICENSE).
