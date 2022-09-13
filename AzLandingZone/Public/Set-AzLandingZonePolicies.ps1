Function Set-AzLandingZonePolicies {
    <#
        .SYNOPSIS
        Assign Azure Landing Zone policies for multi-homing purpose (sending the logs to multiple workspace)
        .DESCRIPTION
        Assign Azure Landing Zone policies for multi-homing purpose (sending the logs to multiple workspace)
        .PARAMETER lzMgtGrp
        Name or Id of the landing zone management group
        .PARAMETER targetMgtGrp
        Name or Id of the Management group where multi-homing needs to be enabled (can be the same as or children of landing zone management group)
        .PARAMETER policyName
        Name to assign for diagnostic policies (must be different than "setByPolicy")
        .PARAMETER subscription
        Name or Id of the new seclog subscription. If none provided, it will use the current subscription.
        .PARAMETER storageAcct
        Name of the storage account in the new seclog subscription. If empty, log will not be shipped to storage account.
        .PARAMETER workspace
        Name of the log analytics workspace in the new seclog subscription. If empty, log will not be shipped to log analytics workspace.
        .PARAMETER eventHub
        Name of the log analytics event hub in the new seclog subscription. If empty, log will not be shipped to event hub.
        .EXAMPLE
        Set-AzLandingZonePolicies -lzMgtGrp "lz-management-group" -targetMgtGrp "C1-management-group" -policyName "c1policy" -workspace "c1loganalyticsws"
        Assign Landing Zone policies defined in "lz-management-group" on "C1-management-group" to ship logs to "c1loganalyticsws"
    #>
    Param (
        [string]$lzMgtGrp = "lz-management-group",
        [string]$targetMgtGrp,
        [string]$policyName,
        [string]$subscription,
        [string]$storageAcct,
        [string]$workspace,
        [string]$eventHub,
        [string]$authorizationKeyName = "RootManageSharedAccessKey"
	)

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    register-ResourceProvider

    #
    # variables
    #
    Write-Host "Creating variables and launching creation" -ForegroundColor Yellow
    
    if(!$subscription){
        $context = Get-AzContext
        Write-Host "No subscription Name or Id provided. Using the subscription $($context.subscription.Name)"
    } else {
        Set-AZContext $subscription
    }

#    if(!($lzManagementGroup = Get-AzManagementGroup -GroupId $lzMgtGrp)){
#        Write-Host "Unable to locate the landing zone management group, abording the script."
#        return
#    }

    if(!($targetManagementGroup = Get-AzManagementGroup -GroupId $targetMgtGrp)){
        Write-Host "Unable to locate the target management group, abording the script."
        return
    }

    if(!$policyName){
        Write-Host "PolicyName cannot be empty, abording the script."
        return
    }
    if($policyName -eq "setByPolicy"){
        Write-Host "PolicyName cannot be 'setByPolicy', abording the script."
        return
    }

    if(!$storageAcct){
        Write-Host "No storage account provided, skipping policies for storage account."
    } else {
        if(!($storageAccount = Get-AzStorageAccount | where-Object {$_.StorageAccountName -eq $storageAcct})){
            Write-Host "Provided storage account name cannot be found. Skipping policies for storage account."
        } else {
            $policyDefinition = Get-AzPolicySetDefinition | Where-Object {$_.Name -eq "SLZ-policyGroup1"}
            [PSCustomObject]$parameters = @{
                'storageAccountId'=$($storageAccount.Id) 
                'policyName'=$policyName
            }
            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policyDefinition -Scope $targetManagementGroup.Id -IdentityType 'SystemAssigned' -Location 'westeurope' -PolicyParameterObject $parameters -Name 'SLZ-policyGroup1'
            Start-Sleep -Seconds 15
            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        }
    }

    if(!$workspace){
        Write-Host "No log analytics workspace provided, skipping policies for log analytics workspace."
    } else {
        if(!($logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace | where-Object {$_.Name -eq $workspace})){
            Write-Host "Provided log analytics workspace name cannot be found. Skipping policies for log analytics workspace."
        } else {
            $policyDefinition = Get-AzPolicySetDefinition | Where-Object {$_.Name -eq "SLZ-policyGroup2"}
            [PSCustomObject]$parameters = @{
                'workspaceId'=$($logAnalyticsWorkspace.Id) 
                'policyName'=$policyName
            }
            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policyDefinition -Scope $targetManagementGroup.Id -IdentityType 'SystemAssigned' -Location 'westeurope' -PolicyParameterObject $parameters -Name 'SLZ-policyGroup2'
            Start-Sleep -Seconds 15
            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        }
    }

    if(!$eventHub){
        Write-Host "No event hub provided, skipping policies for event hub."
    } else {
        if(!($eventHubNamespace = Get-AzEventHubNamespace | where-Object {$_.Name -eq $eventHub})){
            Write-Host "Provided event hub name cannot be found. Skipping policies for event hub."
        } else {
            if(!($authorizationRule = Get-AzEventHubAuthorizationRule -ResourceGroupName $eventHubNamespace.ResourceGroupName -NameSpace $eventHubNamespace.Name -Name $authorizationKeyName)) {
                Write-Host "Provided event hub authorization key name cannot be found. Skipping policies for event hub."
            }
            else {
                $policyDefinition = Get-AzPolicySetDefinition | Where-Object {$_.Name -eq "SLZ-policyGroup3"}
                [PSCustomObject]$parameters = @{
                    'eventHubRuleId'=$($authorizationRule.Id) 
                    'policyName'=$policyName
                }
                $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policyDefinition -Scope $targetManagementGroup.Id -IdentityType 'SystemAssigned' -Location 'westeurope' -PolicyParameterObject $parameters -Name 'SLZ-policyGroup3'
                Start-Sleep -Seconds 15
                New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
            }
        }
    }
}
Export-ModuleMember -Function Set-AzLandingZonePolicies