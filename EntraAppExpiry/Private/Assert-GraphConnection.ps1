function Assert-GraphConnection {
    <#
        .SYNOPSIS
        Throws if there is no active Microsoft Graph connection.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run 'Connect-AppExpiry' first."
    }
}
