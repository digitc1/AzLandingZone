function Get-LzSentinelAlertRule {
    Param (
        [Parameter(Mandatory=$true)][String] $name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Host "No Log analytics workspace for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }

    $uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationalInsights/workspaces/" + $GetLogAnalyticsWorkspace.Name  + "/providers/Microsoft.SecurityInsights/alertRules/securityCenterAlertRule?api-version=2019-01-01-preview"

    try {
        $auth = Get-AzAccessToken
        $requestResult = Invoke-webrequest -Uri $uri -Method Get -Headers $auth
        return 0
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        return 2
    }
    catch {
        Write-Host "An unexpected error happened"
        return 1
    }
}

# Delete Azure Sentinel if exist
# return 0 if removed, 1 if not or error happened
# Requires Get-LzSentinel to return 0
function Remove-LzSentinelAlertRule {
    Param (
        [Parameter(Mandatory=$true)][String] $name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Host "No Log analytics workspace for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if((Get-LzSentinelAlertRule -name $name) -ne 0){
        Write-Host "No Sentinel to remove"
        return 2;
    }

    $uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationalInsights/workspaces/" + $GetLogAnalyticsWorkspace.Name  + "/providers/Microsoft.SecurityInsights/alertRules/securityCenterAlertRule?api-version=2019-01-01-preview"

    try {
        $auth = Get-AzAccessToken
        $requestResult = Invoke-webrequest -Uri $uri -Method Delete -Headers $auth
        return 0
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        return 2
    }
    catch {
        Write-Host "An unexpected error happened"
        return 1
    }
}

# Create Sentinel for the Landing Zone
# return 0 if exist, 1 if not or error happened
function Set-LzSentinelAlertRule {
    Param (
        [Parameter(Mandatory=$true)][String] $name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Host "No Log analytics workspace for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if((Get-LzSentinelAlertRule -name $name) -eq 0){
        return 0;
    }

    $uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationalInsights/workspaces/" + $GetLogAnalyticsWorkspace.Name  + "/providers/Microsoft.SecurityInsights/alertRules/securityCenterAlertRule?api-version=2019-01-01-preview"

    if ($GetLogAnalyticsWorkspace.provisioningState -eq 'Succeeded') {
        $body = @{
            'etag'       = ''
            'kind'       = 'MicrosoftSecurityIncidentCreation'
            'properties' = @{
				'productFilter' = 'Azure Security Center'
				'displayName' = 'Create incidents based on Azure Security Center alerts'
				'enabled' = 'true'
            }
        }
    }
    else {
        Write-Host "Log analytics provisioningState is not 'Succeeding'. Abording installation"
        return 1
    }

    try {
        $auth = Get-AzAccessToken
        $requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json)
        return 0
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        return 1
    }
    catch {
        Write-Host "An unexpected error happened"
        return 1
    }
}
Export-ModuleMember -Function Get-LzSentinel,Remove-LzSentinel,Set-LzSentinel