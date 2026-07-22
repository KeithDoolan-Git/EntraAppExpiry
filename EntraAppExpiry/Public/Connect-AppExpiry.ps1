function Connect-AppExpiry {
    <#
        .SYNOPSIS
        Connects to Microsoft Graph with the scopes EntraAppExpiry needs.

        .DESCRIPTION
        Thin wrapper around Connect-MgGraph. Supports interactive/delegated sign-in
        for ad hoc use, or app-only certificate auth for scheduled/unattended runs.

        .EXAMPLE
        Connect-AppExpiry

        Interactive sign-in with Application.Read.All.

        .EXAMPLE
        Connect-AppExpiry -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $thumbprint

        Unattended app-only sign-in for use in a scheduled task.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Delegated')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'AppOnly')]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'AppOnly')]
        [string]$ClientId,

        [Parameter(Mandatory, ParameterSetName = 'AppOnly')]
        [string]$CertificateThumbprint
    )

    if ($PSCmdlet.ParameterSetName -eq 'AppOnly') {
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome
    }
    else {
        Connect-MgGraph -Scopes 'Application.Read.All' -NoWelcome
    }

    $context = Get-MgContext
    if (-not $context) {
        throw 'Failed to establish a Microsoft Graph connection.'
    }

    Write-Verbose "Connected to tenant $($context.TenantId) as $($context.Account)"
}
