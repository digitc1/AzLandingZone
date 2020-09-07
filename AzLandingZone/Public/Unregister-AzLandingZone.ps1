Function Unregister-AzLandingZone {
    <#
        .SYNOPSIS
        Unregister a subscription in Azure Landing Zone management groups (policies and log collection no longer apply)
        .DESCRIPTION
        Unregister a subscription in Azure Landing Zone management groups (policies and log collection no longer apply)
        .PARAMETER Subscription
        Enter the name or id of the subscription to unregister
        .PARAMETER removeSecurityCenter
        Switch to disable Azure Security Center
        .PARAMETER managementGroup
        Enter the name of the Landing Zone management group
        .EXAMPLE
        Unregister-AzLandingZone -Subscrition "<subscription-name>"
        Unregister the subscription <subscription-name> in Azure Landing Zone
    #>
    Param(
        [Parameter(Mandatory=$true)][string]$subscription,
        [bool]$removeSecurityCenter = $false,
        [string]$managementGroup = "lz-management-group"
    )

    if(!($GetSubscription = Get-AzSubscription | Where-Object {$_.Name -Like "$subscription" -Or $_.Id -Like "$subscription"})){
        Write-Host "Provided subscription is invalid. Make sure to provide a valid subscription name."
        return
    }
    if($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand){
        if($GetSubscription.Name -In $GetManagementGroup.Children.DisplayName) {
            Remove-AzManagementGroupSubscription -GroupName $GetManagementGroup.Name -SubscriptionId ($GetSubscription.Id) | Out-Null
        }
    }
    #Get-AzResource | 
    #    ForEach-Object {
    #        Get-AzDiagnosticSetting -ResourceId $_.ResourceId -ErrorAction SilentlyContinue | ForEach-Object {
    #            if($_.Name -Like "SLZ-*"){
    #                Write-Host "Removing diagnostic setting: "$_.Id
    #                Remove-AzDiagnosticSetting -ResourceId $_.Id | Out-Null
    #            }
    #        }
    #    }
    Remove-LzSubscriptionDiagnosticSettings -subscriptionId $GetSubscription.Id
    
    if($removeSecurityCenter){
        Set-LzSecurityCenterPricing -subscriptionId $GetSubscription.Id -pricingTier "Free"
        Set-LzSecurityAutoProvisioningSettings -subscriptionId $GetSubscription.Id -pricingTier "Off"
        #
        # Remove security Contacts
        #
    }
    
    if(Get-AzOperationalInsightsWorkspace -ResourceGroupName "lzslz_rg"){
        Disconnect-LzSecurityCenter -subscriptionId $GetSubscription.Id
    }

    #
    # Ne fonctionne probablement pas sur toutes les subscriptions, à tester
    #
    if($GetManagedServicesDefinition = (Get-AzManagedServicesDefinition | Where-Object {$_.Properties.ManagedByTenantId -Like "3a8968a8-fbcf-4414-8b5c-77255f50f37b"})){
        if($GetManagedServicesAssignment = (Get-AzManagedServicesAssignment | where-Object {((Get-AzManagedServicesAssignment).Properties.RegistrationDefinitionId.split("/")[-1]) -Like $GetManagedServicesDefinition.Name })) {
            Remove-AzManagedServicesAssignment -InputObject $GetManagedServicesAssignment
        }
        Remove-AzManagedServicesDefinition -Id $GetManagedServicesDefinition.Id
    }
}
Export-ModuleMember -Function Unregister-AzLandingZone