Function Register-LzManagedServicesAssignment {
	Param(
		[string]$name = "lzslz",
		[string]$subscriptionId
    )

    if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return;
	}
    $tmp = "/subscriptions/" + $subscriptionId + "/providers/Microsoft.ManagedServices/registrationDefinitions/097ce9c3-516a-4829-86ad-4d04e4f6dd1e"
    $body = @{
		'properties' = @{
            'registrationDefinitionId' = $tmp
        }
    }
	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.managedServices/registrationAssignments/097ce9c3-516a-4829-86ad-4d04e4f6dd1e?api-version=2019-06-01"

	try {
		Write-Host -ForegroundColor Yellow "Creating delegated access assignment"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Created delegated access assignment"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Delegated access assignment already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Register-LzManagedServicesAssignment