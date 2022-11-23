Function setup-Sentinel {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$true)][string]$name
    )

    Write-Host -ForegroundColor Yellow "Performing initial configuration of Azure Sentinel"

    Set-LzSecurityCenterAlertRule -Name $name
    Connect-LzActiveDirectory -Name $name
    Set-LzActiveDirectoryAlertRule -Name $name
    #Set-LzSentinelAnalyticsRule
    #Set-LzSentinelHuntingQueries
    Set-LzOffice365
}
Export-ModuleMember -Function setup-Sentinel
