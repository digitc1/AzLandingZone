# Check the existence of Sentinel for the Landing Zone
# return 0 if exist, 1 if not or error happened
function Get-LzSentinel {
    Param (
        [Parameter(Mandatory=$true)][String] $name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup | where-Object {$_.ResourceGroupName -like "*$name*"})){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Host "No Log analytics workspace for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }

    $uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationsManagement/solutions/SecurityInsights(" + $GetLogAnalyticsWorkspace.Name + ")?api-version=2015-11-01-preview"
    
    try {
        $auth = Get-LzAccessToken
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
function Remove-LzSentinel {
    Param (
        [Parameter(Mandatory=$true)][String] $name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup | where-Object {$_.ResourceGroupName -like "*$name*"})){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Host "No Log analytics workspace for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return 1;
    }
    if((Get-LzSentinel -name $name) -ne 0){
        Write-Host "No Sentinel to remove"
        return 2;
    }

    $uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationsManagement/solutions/SecurityInsights(" + $GetLogAnalyticsWorkspace.Name + ")?api-version=2015-11-01-preview"
    
    try {
        $auth = Get-LzAccessToken
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
function Set-LzSentinel {
    Param (
        [Parameter(Mandatory=$true)][String] $name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup | where-Object {$_.ResourceGroupName -like "*$name*"})){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return ;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Host "No Log analytics workspace for Secure Landing Zone found"
        Write-Host "Please run setup script before running this script"
        return ;
    }
    if((Get-LzSentinel -name $name) -eq 0){
        return ;
    }

    $uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationsManagement/solutions/SecurityInsights(" + $GetLogAnalyticsWorkspace.Name + ")?api-version=2015-11-01-preview"
    
    if ($GetLogAnalyticsWorkspace.provisioningState -eq 'Succeeded') {
        $body = @{
            'id'         = ''
            'etag'       = ''
            'name'       = ''
            'type'       = ''
            'location'   = $GetLogAnalyticsWorkspace.location
            'properties' = @{
                'workspaceResourceId' = $GetLogAnalyticsWorkspace.Resourceid
            }
            'plan' = @{
                'name'          = 'SecurityInsights($workspace)'
                'publisher'     = 'Microsoft'
                'product'       = 'OMSGallery/SecurityInsights'
                'promotionCode' = ''
            }
        }
    } else {
        Write-Host "Log analytics provisioningState is not 'Succeeding'. Abording installation"
        return
    }

    try {
        $auth = Get-LzAccessToken
        # TODO : Check request result to ensure the Sentinel instance was properly created
        $requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
        Write-Host "A Sentinel instance has been created for the Landing Zone"
        return
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $errorDetails =  $_.ErrorDetails.Message | ConvertFrom-Json -Depth 5
        switch ($errorDetails.error.code) {
            'CannotUpdatePlan' {
                Write-Host "A Sentinel instance is already enabled"
            }
            Default {
                Write-Host "An unexpected Microsoft.PowerShell.Commands.HttpResponseException error happened"
                Write-Host $errorDetails
            }
        }
        return
    } catch {
        Write-Host "An unexpected error happened"
        return
    }
}
Export-ModuleMember -Function Get-LzSentinel,Remove-LzSentinel,Set-LzSentinel