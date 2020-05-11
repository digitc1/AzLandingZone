Function setup-Subscription {
    (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children | ForEach-Object {
        Set-AzContext -SubscriptionId $_.Name | Out-Null
        Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "SqlServers" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "AppServices" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "KubernetesService" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "SqlServerVirtualMachines" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "ContainerRegistry" -PricingTier "Standard" | Out-Null
        Set-AzSecurityPricing -Name "KeyVaults" -PricingTier "Standard" | Out-Null

        #
        # Set auto-provisionning for Azure Security Center agents
        #
        Write-Host "Checking that security center is enabled and auto-provisioning is working" -ForegroundColor Yellow
        if(!((Get-AzSecurityAutoProvisioningSetting -Name "default").AutoProvision -Like "On")){
                Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision | Out-Null
        }
    }
}
Export-ModuleMember -Function setup-Subscription