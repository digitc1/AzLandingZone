Function Remove-AzLandingZone {
    if($GetManagementGroup = Get-AzManagementGroup | Where-Object {$_.Name -Like "lz-management-group"}){
        Write-Host "Removing Landing Zone role assignments at the manamagement group level" -ForegroundColor Yellow
        Get-AzRoleAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.DisplayName -Like "SLZ-*"} | Remove-AzRoleAssignment | Out-Null
        Write-Host "Removing Landing Zone policy assignments at the manamagement group level" -ForegroundColor Yellow
        Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.ResourceName -Like "SLZ-*"} | Remove-AzPolicyAssignment | Out-Null
        Write-Host "Removing Landing Zone policy definition at the manamagement group level" -ForegroundColor Yellow
        Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -Like "SLZ-*"} | Remove-AzPolicyDefinition -Force | Out-Null
        Write-Host "Removing Landing Zone manamagement group" -ForegroundColor Yellow
        (Get-AzManagementGroup -Expand -GroupName $GetManagementGroup.Name).Children | ForEach-Object {Remove-AzManagementGroupSubscription -GroupName $GetManagementGroup.Name -SubscriptionId ($_.Id.Split("/"))[2]}
        Remove-AzManagementGroup -GroupName $GetManagementGroup.Name
    }
    if($GetManagedServicesDefinition = Get-AzManagedServicesDefinition | Where-Object {$_.Properties.ManagedByTenantId -Like "3a8968a8-fbcf-4414-8b5c-77255f50f37b"}){
        Write-Host "Removing Landing Zone delegation for SOC access" -ForegroundColor Yellow
        if($GetManagedServicesAssignment = Get-AzManagedServicesAssignment | Where-Object {$_.Properties.RegistrationDefinitionId -Like $GetManagedServicesDefinition.Id}){
            Remove-AzManagedServicesAssignment -InputObject $GetManagedServicesAssignment | Out-Null
        }
        Remove-AzManagedServicesDefinition -InputObject $GetManagedServicesDefinition | Out-Null
    }

    Write-Host "Removing Landing Zone security contacts" -ForegroundColor Yellow
    $GetSecurityContact = Get-AzSecurityContact | Where-Object {$_.Email -ne "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu" -And $_.Email -ne "EC-DIGIT-CSIRC@ec.europa.eu" -And $_.Email -ne "EC-DIGIT-CLOUDSEC@ec.europa.eu"}
    while((Get-AzSecurityContact).Count -ne 0){
        $var = ((Get-AzSecurityContact).Count)
        Remove-AzSecurityContact -Name "default$var"
    }
    $i = 0
    while($i -ne $GetSecurityContact.Count){
        Set-AzSecurityContact -Name "default$($i+1)" -Email $GetSecurityContact[$i].Email -AlertAdmin -NotifyOnAlert | Out-Null
    }
    
    Write-Host "Keep Azure security center standard tier ?"
    $param = read-Host "enter y or n (default Yes)"
    if($param -Like "n") {
        Write-Host "Removing security center configuration" -ForegroundColor Yellow
        Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "SqlServers" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "AppServices" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "KubernetesService" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "SqlServerVirtualMachines" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "ContainerRegistry" -PricingTier "Free" | Out-Null
        Set-AzSecurityPricing -Name "KeyVaults" -PricingTier "Free" | Out-Null             
    }
    
    if($GetResourceGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -Like "lzslz*"}){
        if($GetResourceLock = Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"}){
            Write-Host "Removing Landing Zone resource lock" -ForegroundColor Yellow
            Remove-AzResourceLock -LockId $GetResourceLock.ResourceId -Force | Out-Null
        }
        if($GetAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.AutomationAccountName -Like "lzslzAutomation"}){
            Write-Host "Removing Landing Zone automation" -ForegroundColor Yellow
            if($GetAutomationServicePrincipal = Get-AzADApplication | Where-Object {$_.DisplayName -Like "lzslzAutomation*"}){
                Get-AzRoleAssignment | Where-Object {$_.DisplayName -Like $GetAutomationServicePrincipal.DisplayName} | Remove-AzRoleAssignment | Out-Null
                Remove-AzADApplication -ObjectId $GetAutomationServicePrincipal.ObjectId -Force
            }
            Remove-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $GetAutomationAccount.AutomationAccountName -Force
        }
        if($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName){
            Write-Host "Removing Landing Zone analytics workspace and sentinel" -ForegroundColor Yellow
            Remove-AzOperationalInsightsWorkspace -Name $GetLogAnalyticsWorkspace.Name -ResourceGroupName $GetResourceGroup.ResourceGroupName -Force
        }
        if($GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName){
            Write-Host "Removing Landing Zone eventHub" -ForegroundColor Yellow
            Remove-AzEventHubNamespace -InputObject $GetEventHubNamespace
        }
    }
}
Export-ModuleMember -Function Remove-AzLandingZone

