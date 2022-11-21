
Function Get-Policies {
    param(
        $policySetDefinitionName,
        $definitionListURI,
        $managementGroupName,
        $version
    )
    $GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroupName
    $scope = $GetManagementGroup.Id

    Invoke-WebRequest -Uri $definitionListURI -OutFile $HOME/definitionList.txt

    # Check the existence of policy set definition
    if ($policySetDefinition = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like $policySetDefinitionName }) {
        if (Get-AzPolicyAssignment -scope $scope | Where-Object { $_.Name -Like $policySetDefinition.Name }) {
            Write-Verbose "Found Policy set definition and role assignment"
        } else {
            Write-Warning "Policy set definition has not been assigned a role"
        }
    } else {
        Write-Warning "Policy set definition does not exist"
    }

    # Check the existence and registration of all policies
    Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
        $policyName = "SLZ-" + $_.Split(',')[0] + $version
        $policyVersion = $_.Split(',')[1]
        if (!($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like $policyName })) {
            Write-Warning "Policy '$policyName' does not exist"
        } else {
            if (!($policy.ResourceId -In $policySetDefinition.Properties.PolicyDefinitions.policyDefinitionId)) {
                Write-Warning "Policy '$policyName' is not registered in policy set definition"
            } else {
                if (!($policy.Properties.metadata.version -eq $policyVersion)) {
                    Write-Warning "Policy '$policyName' is not up to date"
                } else {
                    Write-Verbose "Policy '$policyName' is properly configured"
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
        .PARAMETER name
        Give a description
        .PARAMETER managementGroupName
        Give a description
        .EXAMPLE
        Get-AzLandingZone
        .EXAMPLE
        Get-AzLandingZone -verbose
    #>
    #Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    [cmdletbinding()]
    param(
        [string]$name = "lzslz",
        [string]$managementGroupName = "lz-management-group"
    )

    # Additional resources URI
    $definitionListv1URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList1.txt"
    $definitionListv2URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList2.txt"
    $definitionListv3URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList3.txt"

    # Check resources
    Write-Host "Checking Azure Landing Zone resources" -ForegroundColor Yellow
    if ($GetResourceGroup = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -Like "$name*" }) {
        if (Get-AzResourceLock | Where-Object { $_.Name -Like "LandingZoneLock" }) {
            Write-Verbose "Resource group properly configured"
        } else {
            Write-Warning "Resource group lock not properly configured"
        }
    } else {
        Write-Error "Landing Zone not installed"
        Write-Error "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone"
        return
    }
    
    if ($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroupName) {
        Write-Verbose "Landing Zone management group properly configured"
    } else {
        Write-Error "Landing Zone management group not properly configured"
        return
    }

    # Check storage account
    Write-Host "Checking Azure Landing Zone storage account" -ForegroundColor Yellow
    if ($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName) {
        # Check if the storage account is properly configured
        if ($GetStorageContainer = Get-AzStorageContainer -Context $GetStorageAccount.Context) {
            if ($GetStorageContainer.BlobContainerProperties.HasImmutabilityPolicy -Like "True") {
                Write-Verbose "Storage Account properly configured"
            } else {
                Write-Warning "Immutability policy for logs storage is not set"
            }
        } else {
            Write-Error "Storage account for Landing Zone Logs is not set"
            Write-Error "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone"
            return
        }

        # Check if all policies linked to the storage account are configured
        Get-Policies -policySetDefinitionName "SLZ-policyGroup1" -definitionListURI $definitionListv1URI -managementGroupName $GetManagementGroup.Name -version 1
    } else {
        Write-Error "Landing Zone not installed"
        Write-Error "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone"
        return
    }

    Write-Host "Checking Azure Landing Zone log analytics workspace" -ForegroundColor Yellow
    if (Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName) {
        Write-Verbose "Optional Azure log analytics and Azure Sentinel are properly configured"
        
        # Check if all policies linked to the log analytics workspace are configured
        Get-Policies -policySetDefinitionName "SLZ-policyGroup2" -definitionListURI $definitionListv2URI -managementGroupName $GetManagementGroup.Name -version 2
    } else {
        Write-Verbose "Optional Azure log analytics and Azure Sentinel are not configured" -ForegroundColor Yellow
    }

    Write-Host "Checking Azure Landing Zone event hub namespace" -ForegroundColor "Yellow"
    if ($lzEventHubNamespace = Get-AzEventHubNameSpace -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object { $_.Name -Like "$name*" }) {
        if ((Get-AzEventHub  -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $lzEventHubNamespace.Name | Where-Object { $_.Name -Like "insights-operational-logs" }) -And (Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $lzEventHubNamespace.Name | Where-Object { $_.Name -like "landingZoneAccessKey" })) {
            Write-Verbose "Optional Azure event-hub is properly configured" -ForegroundColor Green
        } else {
            Write-Host "Optional Azure event-hub is installed but not properly configured" -ForegroundColor Red
        }

        # Check if all policies linked to the event hub are configured
        Get-Policies -policySetDefinitionName "SLZ-policyGroup3" -definitionListURI $definitionListv3URI -managementGroupName $GetManagementGroup.Name -version 3
    } else {
        Write-Verbose "Optional Azure event-hub is not configured" -ForegroundColor Yellow
    }

    if(Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -eq "SLZ-AHUB"}){
        Write-Verbose "Azure Landing Zone policy for Azure Hybrid Benefit properly configured"
    } else {
        Write-Warning "Azure Landing Zone policy for Azure Hybrid Benefit not configured"
    }

    if(Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -eq "SLZ-MonitorLinux"}){
        Write-Verbose "Virtual machine monitoring for Linux servers properly configured"
    } else {
        Write-Warning "Virtual machine monitoring for Linux servers not configured"
    }
    if(Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -eq "SLZ-MonitorWin"}){
        Write-Verbose "Virtual machine monitoring for Windows servers properly configured"
    } else {
        Write-Warning "Virtual machine monitoring for Windows servers not configured"
    }
}
Export-ModuleMember -Function Get-AzLandingZone