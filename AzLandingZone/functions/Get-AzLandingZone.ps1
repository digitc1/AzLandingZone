Function Get-AzLandingZone {
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    $definitionListv1URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2FdefinitionList1.txt&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionListv2URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2FdefinitionList2.txt&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionListv3URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2FdefinitionList3.txt&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    
    #
    # variables
    #
    $name = "lzslz"
    $policyStatus = $true
    #$policyCount = 0
    #$policyUpdates = 0
    #$policyMissing = 0

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
    
    if($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group") {
        $scope = $GetManagementGroup.Id
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

        if($scope){
            Invoke-WebRequest -Uri $definitionListv1URI -OutFile $HOME/definitionList.txt
            Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
                $policyName = "SLZ-" + $_.Split(',')[0] + "1"
                $policyVersion = $_.Split(',')[1]
                if($policy = Get-AzPolicyAssignment -Scope $scope| Where-Object {$_.Name -Like $policyName}){
                    $definition = Get-AzPolicyDefinition -Id $policy.Properties.policyDefinitionId
                    if(!($definition.Properties.metadata.version -eq $policyVersion)){
                        Write-Host "Policy '$policyName' is not up to date" -ForegroundColor Yellow
                        $policyStatus = $false
                    }
                }
                else{
                    Write-Host "Policy '$policyName' does not exist" -ForegroundColor Red
                    $policyStatus = $false
                }
            }
            Remove-Item -Path $HOME/definitionList.txt
        }
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        return 2
    }

    if($lzLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $lzResourceGroup.ResourceGroupName) {
        Write-Host "Optional Azure log analytics and Azure Sentinel are properly configured" -ForegroundColor Green
        
        if($scope){
            Invoke-WebRequest -Uri $definitionListv2URI -OutFile $HOME/definitionList.txt
            Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
                $policyName = "SLZ-" + $_.Split(',')[0] + "2"
                $policyVersion = $_.Split(',')[1]
                if($policy = Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like $policyName}){
                    $definition = Get-AzPolicyDefinition -Id $policy.Properties.policyDefinitionId
                    if(!($definition.Properties.metadata.version -eq $policyVersion)){
                        Write-Host "Policy '$policyName' is not up to date" -ForegroundColor Yellow
                        $policyStatus = $false
                    }
                }
                else{
                    Write-Host "Policy '$policyName' does not exist" -ForegroundColor Red
                    $policyStatus = $false
                }
            }
            Remove-Item -Path $HOME/definitionList.txt
        }
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
        if($scope){
            Invoke-WebRequest -Uri $definitionListv3URI -OutFile $HOME/definitionList.txt
            Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
                $policyName = "SLZ-" + $_.Split(',')[0] + "3"
                $policyVersion = $_.Split(',')[1]
                if($policy = Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like $policyName}){
                    $definition = Get-AzPolicyDefinition -Id $policy.Properties.policyDefinitionId
                    if(!($definition.Properties.metadata.version -eq $policyVersion)){
                        Write-Host "Policy '$policyName' is not up to date" -ForegroundColor Yellow
                        $policyStatus = $false
                    }
                }
                else{
                    Write-Host "Policy '$policyName' does not exist" -ForegroundColor Red
                    $policyStatus = $false
                }
            }
            Remove-Item -Path $HOME/definitionList.txt
        }
    }
    else {
        Write-Host "Optional Azure event-hub is not configured" -ForegroundColor Yellow
    }

    if($policyStatus) {
        Write-Host "Landing Zone policies are created and are up to date" -ForegroundColor "Green"
    }
}
Export-ModuleMember -Function Get-AzLandingZone