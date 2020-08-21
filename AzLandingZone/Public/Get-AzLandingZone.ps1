Function Get-AzLandingZone {
    <#
      .SYNOPSIS
      Get all the components of the Landing Zone and checks the configuration of the resources
      .DESCRIPTION
      Get all the components of the Landing Zone and checks the configuration of the resources
      .EXAMPLE
      Get-AzLandingZone
    #>
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    $definitionListv1URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList1.txt"
    $definitionListv2URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList2.txt"
    $definitionListv3URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList3.txt"
    
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