@{
    RootModule           = 'EntraAppAnalysis.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'd32e6320-420f-4f62-9a99-90cb372299f1'
    Author               = 'Keith Doolan'
    CompanyName          = 'FlowLock'
    Copyright            = '(c) Keith Doolan. All rights reserved.'
    Description          = 'Lightweight PowerShell module for analyzing Entra ID (Azure AD) app registrations. Currently reports on client secret and certificate expiry; more analysis capabilities are planned.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    RequiredModules      = @(
        @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'Microsoft.Graph.Applications'; ModuleVersion = '2.0.0' }
    )

    FunctionsToExport    = @(
        'Connect-AppAnalysis'
        'Get-AppAnalysis'
        'Export-AppAnalysisReport'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    FormatsToProcess     = @('EntraAppAnalysis.format.ps1xml')

    PrivateData          = @{
        PSData = @{
            Tags       = @('Azure', 'AzureAD', 'EntraID', 'Security', 'Certificates', 'Secrets', 'Expiry', 'MicrosoftGraph')
            LicenseUri = 'https://github.com/KeithDoolan-Git/EntraAppAnalysis/blob/main/LICENSE'
            ProjectUri = 'https://github.com/KeithDoolan-Git/EntraAppAnalysis'
            ReleaseNotes = 'Initial release: Connect-AppAnalysis, Get-AppAnalysis, Export-AppAnalysisReport.'
        }
    }
}
