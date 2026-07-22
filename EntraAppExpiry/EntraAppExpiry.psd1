@{
    RootModule           = 'EntraAppExpiry.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'd32e6320-420f-4f62-9a99-90cb372299f1'
    Author               = 'Keith Doolan'
    CompanyName          = 'FlowLock'
    Copyright            = '(c) Keith Doolan. All rights reserved.'
    Description          = 'Lightweight PowerShell module for reporting on Entra ID (Azure AD) app registration client secret and certificate expiry.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    RequiredModules      = @(
        @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'Microsoft.Graph.Applications'; ModuleVersion = '2.0.0' }
    )

    FunctionsToExport    = @(
        'Connect-AppExpiry'
        'Get-AppExpiry'
        'Export-AppExpiryReport'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    FormatsToProcess     = @('EntraAppExpiry.format.ps1xml')

    PrivateData          = @{
        PSData = @{
            Tags       = @('Azure', 'AzureAD', 'EntraID', 'Security', 'Certificates', 'Secrets', 'Expiry', 'MicrosoftGraph')
            LicenseUri = 'https://github.com/KeithDoolan-Git/EntraAppExpiry/blob/main/LICENSE'
            ProjectUri = 'https://github.com/KeithDoolan-Git/EntraAppExpiry'
            ReleaseNotes = 'Initial release: Connect-AppExpiry, Get-AppExpiry, Export-AppExpiryReport.'
        }
    }
}
