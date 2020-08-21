Function Set-LzSecurityCenterContacts {
	Param (
        [Parameter(Mandatory=$true)][string]$subscriptionId,
        [Parameter(Mandatory=$true)][string]$securityContact
    )

	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
	}

	$body = @{
		'properties' = @{
			'email' = $securityContact
			'phone' = ''
			'alertNotifications' = 'On'
			'alertsToAdmins' = 'On'
		}
    }
    $uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/securityContacts/" + $securityContact.Replace("@","-") + "?api-version=2017-08-01-preview"

	try {
		Write-Host -ForegroundColor Yellow "Registering security contact $securityContact for Azure security center notifications"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Configured security contact for Azure security center notifications"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Security contact already exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityCenterPricing