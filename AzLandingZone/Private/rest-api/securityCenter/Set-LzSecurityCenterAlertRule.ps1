Function Set-LzSecurityCenterAlertRule {
	Param (
		[Parameter(Mandatory=$true)][String] $name
	)

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Host "No Resource Group for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}
	if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
		Write-Host "No Log analytics workspace for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}

	$body = @{
		'etag'       = ''
		'kind'       = 'MicrosoftSecurityIncidentCreation'
		'properties' = @{
			'productFilter' = 'Azure Security Center'
			'displayName' = 'Create incidents based on Azure Security Center alerts'
			'enabled' = 'true'
		}
	}
	$uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationalInsights/workspaces/" + $GetLogAnalyticsWorkspace.Name  + "/providers/Microsoft.SecurityInsights/alertRules/securityCenterAlertRule?api-version=2020-01-01"

	try {
		Write-Host -ForegroundColor Green "Enabling alerts creation for Azure Security Center in Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Enabled alerts creation for Azure Security Center in Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Alerts creation for Azure Security Center in Sentinel already enabled" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityCenterAlertRule