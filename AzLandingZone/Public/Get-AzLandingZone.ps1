
Function Get-Policies {
    param(
        $policySetDefinitionName,
        $definitionListURI,
        $managementGroupName,
        $version
    )
    $GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroupName

    Invoke-WebRequest -Uri $definitionListURI -OutFile $HOME/definitionList.txt

    # Check the existence of policy set definition
    if ($policySetDefinition = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like $policySetDefinitionName }) {
        if (Get-AZPolicyAssignment | Where-Object { $_.Name -Like $policySetDefinition.Name }) {
            Write-Host "Policy set definition properly configured" -ForegroundColor Green
        }
        else {
            Write-Host -ForegroundColor Red "Policy set definition has not been assigned a role"
        }
    }
    else {
        Write-Host -ForegroundColor Red "Policy set definition does not exist"
    }

    # Check the existence and registration of all policies
    Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
        $policyName = "SLZ-" + $_.Split(',')[0] + $version
        $policyVersion = $_.Split(',')[1]
        if (!($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like $policyName })) {
            Write-Host "Policy '$policyName' does not exist" -ForegroundColor Red
        }
        else {
            if (!($policy.ResourceId -In $policySetDefinition.Properties.PolicyDefinitions.policyDefinitionId)) {
                Write-Host "Policy '$policyName' is not registered in policy set definition" -ForegroundColor Yellow
            }
            else {
                if (!($policy.Properties.metadata.version -eq $policyVersion)) {
                    Write-Host "Policy '$policyName' is not up to date" -ForegroundColor Yellow
                }
                else {
                    Write-Host "Policy '$policyName' is properly configured" -ForegroundColor Green
                }
            }
        } 
    }
    Remove-Item -Path $HOME/definitionList.txt
}
Function Get-AzLandingZone {
    <#
        .SYNOPSIS
        Get all the components of the Landing Zone and checks the configuration of the resources
        .DESCRIPTION
        Get all the components of the Landing Zone and checks the configuration of the resources
        .EXAMPLE
        Get-AzLandingZone
    #>
    #Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    [cmdletbinding()]
    #param(
    #    [string]$name,
    #    [string]$managementGroupName
    #)

    # Additional resources URI
    $definitionListv1URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList1.txt"
    $definitionListv2URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList2.txt"
    $definitionListv3URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList3.txt"
    
    # variables
    $name = "lzslz"

    # Check resources
    if ($GetResourceGroup = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -Like "$name*" }) {
        if (Get-AzResourceLock | Where-Object { $_.Name -Like "LandingZoneLock" }) {
            Write-Host "Resource group properly configured" -ForegroundColor Green
        }
        else {
            Write-Host "Resource group lock not properly configured" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        return
    }
    
    if ($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group") {
        Write-Host "Landing Zone management group properly configured" -ForegroundColor Green
    }
    else {
        Write-Host "Landing Zone management group not properly configured" -ForegroundColor Yellow
        return
    }

    # Check storage account
    Write-Host "Checking storage account" -ForegroundColor Yellow
    if ($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName) {
        # Check if the storage account is properly configured
        if ($GetStorageContainer = Get-AzStorageContainer -Context $GetStorageAccount.Context) {
            if ($GetStorageContainer.BlobContainerProperties.HasImmutabilityPolicy -Like "True") {
                Write-Host "Storage Account properly configured" -ForegroundColor Green
            }
            else {
                Write-Host "Immutability policy for logs storage is not set" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Storage account for Landing Zone Logs is not set" -ForegroundColor Red
            Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        }

        # Check if all policies linked to the storage account are configured
        Get-Policies -policySetDefinitionName "SLZ-policyGroup1" -definitionListURI $definitionListv1URI -managementGroupName $GetManagementGroup.Name -version 1
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        return
    }

    Write-Host "Checking log analytics workspace" -ForegroundColor Yellow
    if (Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName) {
        Write-Host "Optional Azure log analytics and Azure Sentinel are properly configured" -ForegroundColor Green
        
        Get-Policies -policySetDefinitionName "SLZ-policyGroup2" -definitionListURI $definitionListv2URI -managementGroupName $GetManagementGroup.Name -version 2
    }
    else {
        Write-Host "Optional Azure log analytics and Azure Sentinel are not configured" -ForegroundColor Yellow
    }

    Write-Host "Checking event hub namespace"
    if ($lzEventHubNamespace = Get-AzEventHubNameSpace -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object { $_.Name -Like "$name*" }) {
        if ((Get-AzEventHub  -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $lzEventHubNamespace.Name | Where-Object { $_.Name -Like "insights-operational-logs" }) -And (Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $lzEventHubNamespace.Name | Where-Object { $_.Name -like "landingZoneAccessKey" })) {
            Write-Host "Optional Azure event-hub is properly configured" -ForegroundColor Green
        }
        else {
            Write-Host "Optional Azure event-hub is installed but not properly configured" -ForegroundColor Red
        }

        Get-Policies -policySetDefinitionName "SLZ-policyGroup3" -definitionListURI $definitionListv3URI -managementGroupName $GetManagementGroup.Name -version 3
    }
    else {
        Write-Host "Optional Azure event-hub is not configured" -ForegroundColor Yellow
    }
}
Export-ModuleMember -Function Get-AzLandingZone