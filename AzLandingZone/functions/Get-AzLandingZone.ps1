Function Get-AzLandingZone {
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    #
    # variables
    #
    $name = "lzslz"

    #
    # Check resources
    #
    if($lzResourceGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -Like "$name*"}){
        if(Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"}){
            Write-Host "Resource group properly configured" -ForegroundColor Green
        }
        else {
            Write-Host "Resource group not properly configured" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        return 2
    }
    
    if(Get-AzManagementGroup -GroupName "lz-management-group") {
        Write-Host "Landing Zone management group properly configured" -ForegroundColor Green
    }
    else {
        Write-Host "Landing Zone management group not properly configured" -ForegroundColor Yellow
    }

    if($lzStorageAccount = Get-AzStorageAccount -ResourceGroupName $lzResourceGroup.ResourceGroupName) {
        if($lzStorageContainer = Get-AzStorageContainer -Context $lzStorageAccount.Context){
            if($lzStorageContainer.BlobContainerProperties.HasImmutabilityPolicy -Like "True"){
                Write-Host "Storage Account properly configured" -ForegroundColor Green
            }
            else {
                Write-Host "Immutability policy for logs storage is not set" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Storage account for Landing Zone Logs is not set" -ForegroundColor Red
            Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
            return 2
        }
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        return 2
    }

    if($lzLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $lzResourceGroup.ResourceGroupName) {
        Write-Host "Optional Azure log analytics and Azure Sentinel are properly configured" -ForegroundColor Green
    }
    else {
        Write-Host "Optional Azure log analytics and Azure Sentinel are not configured" -ForegroundColor Yellow
    }

    if($lzEventHubNamespace = Get-AzEventHubNameSpace -ResourceGroupName $lzResourceGroup.ResourceGroupName | Where-Object {$_.Name -Like "$name*"}) {
        if((Get-AzEventHub  -ResourceGroupName $lzResourceGroup.ResourceGroupName -Namespace $lzEventHubNamespace.Name | Where-Object {$_.Name -Like "insights-operational-logs"}) -And (Get-AzEventHubAuthorizationRule -ResourceGroupName $lzResourceGroup.ResourceGroupName -Namespace $lzEventHubNamespace.Name | Where-Object {$_.Name -like "landingZoneAccessKey"})){
            Write-Host "Optional Azure event-hub is properly configured" -ForegroundColor Green
        }
        else {
            Write-Host "Optional Azure event-hub is installed but not properly configured" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Optional Azure event-hub is not configured" -ForegroundColor Yellow
    }
}
Export-ModuleMember -Function Get-AzLandingZone