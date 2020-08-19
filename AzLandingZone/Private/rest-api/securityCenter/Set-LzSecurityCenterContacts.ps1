Function Set-LzSecurityCenterContacts {
	Param (
        [Parameter(Mandatory=$true)][string]$subscriptionId,
        [string]$securityContacts
        )

	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
	}

	$body = @{
		'properties' = @{
			'notificationsByRole' = @{
                'state'= 'On'
                'roles' = @(
                    'Owner'
                )
            }
            'emails' = $securityContacts
            'alertsNotifications' = @{
                'state' = 'On'
                'minimalSeverity' = 'Low'
            }
		}
    }
    $uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/securityContacts/default?api-version=2020-01-01-preview"

	try {
		Write-Host -ForegroundColor Yellow "Registering security contacts for Azure security center notifications"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Configured security contacts for Azure security center notifications"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Auto-provisioning already exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityCenterPricing