Function Set-LzSecurityCenterWorkspace {
	Param (
        [Parameter(Mandatory=$true)][string] $subscriptionId,
        [string]$name = "lzslz"
	)

	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
    }
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Host "No Resource Group for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}
    if(!($GetWorkspace = Get-AzOperationalInsightsWorkspace -resourceGroupName $GetResourceGroup.ResourceGroupName | where-Object {$_.Name -Like "*$name*"})){
		Write-Host -ForegroundColor Red "Workspace cannot be found"
		return 1;
    }

	$body = @{
		'properties' = @{
            'workspaceId' = $GetWorkspace.ResourceId
            'scope' = '/subscriptions/'+$SubscriptionId
		}
	}

	try {
		Write-Host -ForegroundColor Yellow "Registering Azure Security Center workspace"
		$auth = Get-LzAccessToken
		$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/workspaceSettings/default?api-version=2019-01-01"
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Configured Azure Security Center workspace"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Auto-provisioning already exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityCenterWorkspace