function Get-AppAnalysis {
    <#
        .SYNOPSIS
        Reports client secret and certificate expiry for Entra ID app registrations.

        .DESCRIPTION
        Enumerates app registrations via Microsoft Graph and returns one object per
        credential (password secret or certificate) with its expiry date and days
        remaining. Requires Connect-AppAnalysis to have been run first.

        .PARAMETER ExpiringInDays
        Only return credentials expiring within this many days.

        .PARAMETER IncludeExpired
        Include credentials that have already expired. Excluded by default.

        .EXAMPLE
        Get-AppAnalysis -ExpiringInDays 30

        Lists every client secret/certificate expiring in the next 30 days.
    #>
    [CmdletBinding()]
    [OutputType('EntraAppAnalysis.Credential')]
    param(
        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ExpiringInDays,

        [Parameter()]
        [switch]$IncludeExpired
    )

    Assert-GraphConnection

    $now = Get-Date
    $apps = Get-MgApplication -All -Property Id, AppId, DisplayName, PasswordCredentials, KeyCredentials

    foreach ($app in $apps) {
        $credentials = [System.Collections.Generic.List[object]]::new()

        foreach ($secret in $app.PasswordCredentials) {
            $credentials.Add([pscustomobject]@{
                    PSTypeName      = 'EntraAppAnalysis.Credential'
                    AppDisplayName  = $app.DisplayName
                    AppId           = $app.AppId
                    ObjectId        = $app.Id
                    CredentialType  = 'Secret'
                    KeyId           = $secret.KeyId
                    DisplayName     = $secret.DisplayName
                    StartDateTime   = $secret.StartDateTime
                    EndDateTime     = $secret.EndDateTime
                    DaysUntilExpiry = [math]::Ceiling((New-TimeSpan -Start $now -End $secret.EndDateTime).TotalDays)
                })
        }

        foreach ($cert in $app.KeyCredentials) {
            $credentials.Add([pscustomobject]@{
                    PSTypeName      = 'EntraAppAnalysis.Credential'
                    AppDisplayName  = $app.DisplayName
                    AppId           = $app.AppId
                    ObjectId        = $app.Id
                    CredentialType  = 'Certificate'
                    KeyId           = $cert.KeyId
                    DisplayName     = $cert.DisplayName
                    StartDateTime   = $cert.StartDateTime
                    EndDateTime     = $cert.EndDateTime
                    DaysUntilExpiry = [math]::Ceiling((New-TimeSpan -Start $now -End $cert.EndDateTime).TotalDays)
                })
        }

        foreach ($credential in $credentials) {
            if (-not $IncludeExpired -and $credential.DaysUntilExpiry -lt 0) {
                continue
            }

            if ($PSBoundParameters.ContainsKey('ExpiringInDays') -and $credential.DaysUntilExpiry -gt $ExpiringInDays) {
                continue
            }

            $credential
        }
    }
}
