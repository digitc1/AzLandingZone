Function Remove-AzLandingZone {
    if($GetManagementGroup = Get-AzManagementGroup | Where-Object {$_.Name -Like "lz-management-group"}){
        # Remove role assignment
        Get-AzRoleAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.DisplayName -Like "SLZ-*"} | Remove-AzRoleAssignment | Out-Null
        # Remove policy assignment
        Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.ResourceName -Like "SLZ-*"} | Remove-AzPolicyAssignment | Out-Null
        # Remove policy definition
        Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -Like "SLZ-*"} | Remove-AzPolicyDefinition -Force | Out-Null
        # Remove all subscriptions from the resource group
        (Get-AzManagementGroup -Expand -GroupName $GetManagementGroup.Name).Children | ForEach-Object {Remove-AzManagementGroupSubscription -GroupName $GetManagementGroup.Name -SubscriptionId ($_.Id.Split("/"))[2]}
        # Delete management group
        Remove-AzManagementGroup -GroupName $GetManagementGroup.Name
    }
    # Azure Lighthouse delegation
    if($GetManagedServicesDefinition = Get-AzManagedServicesDefinition | Where-Object {$_.Properties.ManagedByTenantId -Like "3a8968a8-fbcf-4414-8b5c-77255f50f37b"}){
        if($GetManagedServicesAssignment = Get-AzManagedServicesAssignment | Where-Object {$_.Properties.RegistrationDefinitionId -Like $GetManagedServicesDefinition.Id}){
            Remove-AzManagedServicesAssignment -InputObject $GetManagedServicesAssignment | Out-Null
        }
        Remove-AzManagedServicesDefinition -InputObject $GetManagedServicesDefinition | Out-Null
    }

    #Azure security center
    $GetSecurityContact = Get-AzSecurityContact | Where-Object {$_.Email -Like "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu" -Or $_.Email -Like "EC-DIGIT-CSIRC@ec.europa.eu" -Or $_.Email -Like "EC-DIGIT-CLOUDSEC@ec.europa.eu"}
    # TO DO - remove security contact
    Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "SqlServers" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "AppServices" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "KubernetesService" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "SqlServerVirtualMachines" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "ContainerRegistry" -PricingTier "Free" | Out-Null
    Set-AzSecurityPricing -Name "KeyVaults" -PricingTier "Free" | Out-Null

    if($GetResourceGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -Like "lzslz*"}){
        if($GetResourceLock = Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"}){
            # This one does not work, could not be found
            Remove-AzResourceLock -LockId $GetResourceGroup.ResourceId -Force
        }
        if($GetAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.AutomationAccountName -Like "lzslzAutomation"}){
            if($GetAutomationServicePrincipal = Get-AzADApplication | Where-Object {$_.DisplayName -Like "lzslzAutomation*"}){
                Get-AzRoleAssignment | Where-Object {$_.DisplayName -Like $GetAutomationServicePrincipal.DisplayName} | Remove-AzRoleAssignment | Out-Null
                Remove-AzADApplication -ObjectId $GetAutomationServicePrincipal.ObjectId -Force
            }
            Remove-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $GetAutomationAccount.AutomationAccountName -Force
        }
        #Remove Azure Sentinel
        #Remove Analytics workspace
        #Remove Event Hub
    }
}
Export-ModuleMember -Function Remove-AzLandingZone

