Function Connect-LzActiveDirectory{
	Param(
		[string]$name = "lzslz"
	)

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Error "No Resource Group for Secure Landing Zone found"
		Write-Error "Please run setup script before running this script"
		return 1;
	}
	if(!($GetWorkspace = Get-AzOperationalInsightsWorkspace -resourceGroupName $GetResourceGroup.ResourceGroupName | where-Object {$_.Name -Like "*$name*"})){
		Write-Error "Workspace cannot be found"
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
		Write-Host -ForegroundColor Yellow "Connecting Active Directory logs to Azure Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Connected Active Directory logs to Azure Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			400 {Write-Error "Another connector with the same name already exist."}
			401 {Write-Host "Tenant does not have P2 license and does not support this feature"}
			409 {Write-Host "Connection already exists"}
			default {Write-Error "An unexpected error happened. Contact Landing Zone FMB for additional support. $($_.Exception.Message)"}
		}
	}
}
Export-ModuleMember -Function Connect-LzActiveDirectory