Function Onboard-AzLandingZone {
    Param(
        [Parameter(Mandatory=$true)][string]$subscription,
        [ValidateSet("DIGIT", "CERTEU", "None", "")][string] $SOC = "None"
    )

    #
    # Onboard the specified subscription
    #

    if(!($GetSubscription = Get-AzSubscription | Where-Object {$_.Name -Like "$subscription" -Or $_.Id -Like "$subscription"})){
        Write-Host "Provided subscription is invalid. Make sure to provide a valid subscription name."
        return
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group" -Expand)){
        Write-Host "No management group found. Make sure the Landing Zone is installed."
    }

    if($GetSubscription.Name -notin $GetManagementGroup.Children.DisplayName){
        New-AzManagementGroupSubscription -GroupName "lz-management-group" -SubscriptionId $GetSubscription.Id | Out-Null
    }

    Set-LzSubscriptionDiagnosticSettings -subscriptionId $GetSubscription.Id

    Set-LzSecurityPricing -subscriptionId $GetSubscription.Id
    Set-LzSecurityCenterAutoProvisioningSetting -subscriptionId $GetSubscription.Id
    if($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName "lzslz_rg"){
        Connect-LzSecurityCenter -subscriptionId $GetSubscription.Id
    }
}
Export-ModuleMember -Function Onboard-AzLandingZone