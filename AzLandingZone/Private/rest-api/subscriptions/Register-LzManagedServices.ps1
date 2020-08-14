Function Register-LzManagedServices {
	Param(
		[string]$name = "lzslz",
		[string]$subscriptionId
	)
	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
			Write-Host "No Resource Group for Secure Landing Zone found"
			Write-Host "Please run setup script before running this script"
			return 1;
	}
	if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "*$name*"})){
			Write-Host "No Storage Account found for Secure Landing Zone"
			Write-Host "Please run setup script before running this script"
			return 1;
	}

	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.managedservices/register?api-version=2019-09-01"

	try {
		Write-Host -ForegroundColor Green "Configuring subscription diagnostic settings"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Post -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Configured subscription diagnostic settings"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Diagnostic settings already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Register-LzManagedServices