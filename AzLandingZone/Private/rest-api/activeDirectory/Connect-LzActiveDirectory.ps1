Function Connect-LzActiveDirectory{
	Param(
		[string]$name = "lzslz"
	)

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Host "No Resource Group for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}
	if(!($GetWorkspace = Get-AzOperationalInsightsWorkspace -resourceGroupName $GetResourceGroup.ResourceGroupName | where-Object {$_.Name -Like "*$name*"})){
		Write-Host -ForegroundColor Red "Workspace cannot be found"
		return 1;
	}
	$tenantId = (Get-AzContext).Tenant.Id
	
	$body = [PSCustomObject]@{
		'name' = $tenantId
		'etag' = (New-Guid).Guid
		'kind' = 'AzureActiveDirectory'
		'properties' = @{
			'tenantId' = $tenantId
			'dataTypes' = @{
				'alerts' = @{
					'state' = 'enabled'
				}
			}
		}
	}
	$uri = "https://management.azure.com" + $GetWorkspace.ResourceId + "/providers/Microsoft.SecurityInsights/dataConnectors/" + $tenantId + "?api-version=2020-01-01"

	try{
		Write-Host -ForegroundColor Green "Connecting Active Directory logs to Azure Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Connected Active Directory logs to Azure Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Connection already exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Connect-LzActiveDirectory