Function setup-Sentinel {
    param(
        [Parameter(Mandatory=$true)][string]$name
    )
    Set-LzSecurityCenterAlertRule -Name $name
    Connect-LzActiveDirectory -Name $name
    Set-LzActiveDirectoryAlertRule -Name $name
    Set-LzSentinelAnalyticsRule
    Set-LzSentinelHuntingQueries
    Set-LzOffice365
}
Export-ModuleMember -Function setup-Sentinel
