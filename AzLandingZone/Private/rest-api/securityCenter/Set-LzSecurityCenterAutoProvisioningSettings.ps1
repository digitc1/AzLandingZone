Function Set-LzSecurityAutoProvisioningSettings {
	Param (
		[Parameter(Mandatory=$true)][string]$subscriptionId
	)

	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
	}

	$body = @{
		'properties' = @{
			'autoProvision' = 'On'
		}
	}
	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/autoProvisioningSettings/default?api-version=2019-01-01"

	try {
		Write-Host -ForegroundColor Green "Configuring Azure security center agents auto-provisioning"
		$auth = Get-AzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Configured Azure security center agents auto-provisioning"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Azure security center agents auto-provisioning already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityAutoProvisioningSettings