Function Register-AzLandingZone {
    <#
        .SYNOPSIS
        Register a subscription in Azure Landing Zone management groups (policies and log collection apply)
        .DESCRIPTION
        Register a subscription in Azure Landing Zone management groups (policies and log collection apply)
        .PARAMETER Subscription
        Enter the name or id of the subscription to register
        .PARAMETER SOC
        Enter SOC value for additional features (lighthouse, Sentinel multi-workspace, ...)
        .PARAMETER securityContacts
        Enter comma separated list of email addresses
        .EXAMPLE
        Register-AzLandingZone -Subscrition "<subscription-name>"
        Register the subscription <subscription-name> in Azure Landing Zone
        .EXAMPLE
        Register-AzLandingZone -Subscrition "<subscription-id>" -SOC "DIGIT" -securityContacts "alice@domain.com,bob@domain.com"
        Register the subscription <subscription-id> in Azure Landing Zone, enable lighthouse for DIGIT.S access and register alice and bob as security contacts
    #>
    Param(
        [Parameter(Mandatory=$true)][string]$subscription,
        [ValidateSet("DIGIT", "CERTEU", "None", "")][string] $SOC = "None",
        [string] $securityContacts = ""
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
    
    register-AzResourceProviders -subscriptionId $GetSubscription.Id

    Set-LzSubscriptionDiagnosticSettings -subscriptionId $GetSubscription.Id
    Set-LzSecurityCenterPricing -subscriptionId $GetSubscription.Id
    Set-LzSecurityAutoProvisioningSettings -subscriptionId $GetSubscription.Id

    Set-LzSecurityCenterContacts -subscriptionId $GetSubscription.Id -securityContact "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu"
    if($SOC -eq "DIGIT"){
        Set-LzSecurityCenterContacts -subscriptionId $GetSubscription.Id -securityContact "EC-DIGIT-CLOUDSEC@ec.europa.eu"
        Set-LzSecurityCenterContacts -subscriptionId $GetSubscription.Id -securityContact "EC-DIGIT-CSIRC@ec.europa.eu"
    }
    foreach ($securityContact in $securityContacts.Split(',')){ 
        Set-LzSecurityCenterContacts -subscriptionId $GetSubscription.Id -securityContact $securityContact
    }
    if(Get-AzOperationalInsightsWorkspace -ResourceGroupName "lzslz_rg"){
        Connect-LzSecurityCenter -subscriptionId $GetSubscription.Id
    }
}
Export-ModuleMember -Function Register-AzLandingZone