BeforeAll {
    $ModulePath = Resolve-Path "$PSScriptRoot/../EntraAppAnalysis/EntraAppAnalysis.psd1"
    Import-Module $ModulePath -Force
}

Describe 'Get-AppAnalysis' {
    BeforeAll {
        Mock -ModuleName EntraAppAnalysis Get-MgContext { @{ TenantId = 'test-tenant'; Account = 'test@example.com' } }
        Mock -ModuleName EntraAppAnalysis Get-MgApplication {
            @(
                [pscustomobject]@{
                    Id                  = '11111111-1111-1111-1111-111111111111'
                    AppId               = '22222222-2222-2222-2222-222222222222'
                    DisplayName         = 'Test App'
                    PasswordCredentials = @(
                        [pscustomobject]@{
                            KeyId         = '33333333-3333-3333-3333-333333333333'
                            DisplayName   = 'Test Secret'
                            StartDateTime = (Get-Date).AddDays(-300)
                            EndDateTime   = (Get-Date).AddDays(10)
                        }
                    )
                    KeyCredentials      = @()
                },
                [pscustomobject]@{
                    Id                  = '44444444-4444-4444-4444-444444444444'
                    AppId               = '55555555-5555-5555-5555-555555555555'
                    DisplayName         = 'Expired App'
                    PasswordCredentials = @(
                        [pscustomobject]@{
                            KeyId         = '66666666-6666-6666-6666-666666666666'
                            DisplayName   = 'Old Secret'
                            StartDateTime = (Get-Date).AddDays(-400)
                            EndDateTime   = (Get-Date).AddDays(-30)
                        }
                    )
                    KeyCredentials      = @()
                }
            )
        }
    }

    It 'Returns credentials expiring within the given window' {
        $result = Get-AppAnalysis -ExpiringInDays 30
        $result.Count | Should -Be 1
        $result[0].CredentialType | Should -Be 'Secret'
        $result[0].AppDisplayName | Should -Be 'Test App'
    }

    It 'Excludes credentials outside the expiry window' {
        $result = Get-AppAnalysis -ExpiringInDays 5
        $result.Count | Should -Be 0
    }

    It 'Excludes already-expired credentials by default' {
        $result = Get-AppAnalysis
        $result.AppDisplayName | Should -Not -Contain 'Expired App'
    }

    It 'Includes expired credentials when -IncludeExpired is set' {
        $result = Get-AppAnalysis -IncludeExpired
        $result.AppDisplayName | Should -Contain 'Expired App'
    }

    It 'Throws when not connected to Graph' {
        Mock -ModuleName EntraAppAnalysis Get-MgContext { $null }
        { Get-AppAnalysis } | Should -Throw
    }
}
