Function setup-Sentinel {
    param(
        [Parameter(Mandatory=$true)][string]$name
    )
    Set-LzSecurityCenterAlertRule -Name $name
    Connect-LzActiveDirectory -Name $name
    Set-LzActiveDirectoryAlertRule -Name $name
}
Export-ModuleMember -Function setup-Sentinel