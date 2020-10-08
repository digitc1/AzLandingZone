Function Set-LzOffice365 {
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
    $context = Get-AzContext
	
	$body = @{
        'name' = 'afe968b3-3bb5-47ac-ab78-1ab251a69246'
        'kind' = 'Office365'
		'properties' = @{
			'tenantId' = $context.Tenant.Id
			'dataTypes' = @{
                'sharepoint' = @{
                    'state' = 'enabled'
                };
                'exchange' = @{
                    'state' = 'enabled'
                };
                'teams' = @{
                    'state' = 'enabled'
                }
            }
		}
	}
	
	$uri = "https://management.azure.com" + $GetWorkspace.ResourceId + "/providers/Microsoft.SecurityInsights/dataConnectors/afe968b3-3bb5-47ac-ab78-1ab251a69246?api-version=2020-01-01"

	try{
		Write-Host -ForegroundColor Yellow "Configuring active directory diagnostic settings"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Configured active directory diagnostic settings"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Diagnostic settings already configured"}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzOffice365