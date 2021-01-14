Function Set-LzActiveDirectoryAlertRule {
	Param (
		[String] $name = "lzslz"
	)

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Host "No Resource Group for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}
	if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
		Write-Host "No Log analytics workspace for Secure Landing Zone found"
		Write-Host "Skipping alert rule creation for Log analytics workspace"
		return;
	}

	$body = @{
		'etag'       = ''
		'kind'       = 'MicrosoftSecurityIncidentCreation'
		'properties' = @{
			'productFilter' = 'Azure Active Directory Identity Protection'
			'displayName' = 'Create incidents based on Azure Active Directory Identity Protection alerts'
			'enabled' = 'true'
			'description' = 'Create incidents based on all alerts generated in Azure Active Directory Identity Protection'
			'alertRuleTemplateName' = '532c1811-79ee-4d9f-8d4d-6304c840daa1'
		}
	}
	$uri = "https://management.azure.com" + $GetResourceGroup.ResourceId + "/providers/Microsoft.OperationalInsights/workspaces/" + $GetLogAnalyticsWorkspace.Name  + "/providers/Microsoft.SecurityInsights/alertRules/azureAdIdentityProtection?api-version=2020-01-01"

	try {
		Write-Host -ForegroundColor Yellow "Enabling alerts creation for Azure Active Directory in Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Enabled alerts creation for Azure Active Directory in Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Alerts creation for Active Directory in Sentinel already enabled" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzActiveDirectoryAlertRule