function Export-AppAnalysisReport {
    <#
        .SYNOPSIS
        Exports Get-AppAnalysis output to CSV or HTML.

        .EXAMPLE
        Get-AppAnalysis -ExpiringInDays 30 | Export-AppAnalysisReport -Path .\report.html -Format Html
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSTypeName('EntraAppAnalysis.Credential')]
        [psobject[]]$InputObject,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [ValidateSet('Csv', 'Html')]
        [string]$Format = 'Csv'
    )

    begin {
        $allItems = [System.Collections.Generic.List[object]]::new()
    }
    process {
        foreach ($item in $InputObject) {
            $allItems.Add($item)
        }
    }
    end {
        $sorted = $allItems | Sort-Object DaysUntilExpiry

        switch ($Format) {
            'Csv' {
                $sorted | Export-Csv -Path $Path -NoTypeInformation
            }
            'Html' {
                $sorted |
                    ConvertTo-Html -Title 'Entra App Credential Expiry Report' `
                        -Property AppDisplayName, CredentialType, DisplayName, EndDateTime, DaysUntilExpiry |
                    Out-File -FilePath $Path -Encoding utf8
            }
        }

        Get-Item -Path $Path
    }
}
