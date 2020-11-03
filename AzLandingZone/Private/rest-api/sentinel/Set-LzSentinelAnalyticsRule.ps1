Function Set-LzSentinelAnalyticsRule {
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
		Write-Host "Please run setup script before running this script"
		return 1;
    }
    
    try{
        $uri = "https://management.azure.com" + $GetLogAnalyticsWorkspace.ResourceId  + "/providers/Microsoft.SecurityInsights/alertRuleTemplates?api-version=2020-01-01"
        $auth = Get-LzAccessToken
        $requestResult = Invoke-webrequest -Uri $uri -Method Get -Headers $auth
        ($requestResult.Content | ConvertFrom-Json).value | ForEach-Object {
            try{
                if ($_.kind -Like "Scheduled") {
                    $body = @{
                        'kind'       = 'Scheduled'
                        'properties' = @{
                            'severity' = $_.properties.severity
                            'query' = $_.properties.query
                            'queryFrequency' = $_.properties.queryFrequency
                            'queryPeriod' = $_.properties.queryPeriod
                            'suppressionDuration' = 'PT5H'
                            'suppressionEnabled' = 'false'
                            'triggerOperator' = $_.properties.triggerOperator
                            'triggerThreshold' = $_.properties.triggerThreshold
                            'displayName' = $_.properties.displayName
                            'description' = $_.properties.description
                            'alertRuleTemplateName' = $_.name
                            'enabled' = 'true'
                        }
                    }
                }
                if ($_.kind -Like "MicrosoftSecurityIncidentCreation") {
                    $body = @{
                        'kind'       = 'MicrosoftSecurityIncidentCreation'
                        'properties' = @{
                            'productFilter' = $_.properties.productFilter
                            'displayName' = $_.properties.displayName
                            'enabled' = 'true'
                            'description' = $_.properties.description
                            'alertRuleTemplateName' = $_.name
                        }
                    }
                }
                if ($_.kind -Like "MLBehaviorAnalytics") {
                    $body = @{
                        'kind'       = 'MLBehaviorAnalytics'
                        'properties' = @{
                            'enabled' = 'true'
                            'alertRuleTemplateName' = $_.name
                        }
                    }
                }
                if ($_.kind -Like "Fusion") {
                    $body = @{
                        'kind'       = 'Fusion'
                        'properties' = @{
                            'enabled' = 'true'
                            'alertRuleTemplateName' = $_.name
                        }
                    }
                }
                if ($_.kind -Like "ThreatIntelligence") {
                    $body = @{
                        'kind'       = 'ThreatIntelligence'
                        'properties' = @{
                            'severity' = $_.properties.severity
                            'displayName' = $_.properties.displayName
                            'enabled' = 'true'
                            'description' = $_.properties.description
                            'alertRuleTemplateName' = $_.name
                        }
                    }
                }
                
                $uri = "https://management.azure.com" + $GetLogAnalyticsWorkspace.ResourceId  + "/providers/Microsoft.SecurityInsights/alertRules/" + $_.name + "?api-version=2020-01-01"
            
                Write-Host -ForegroundColor Green "Enabling analytics rule "$_.name
                $auth = Get-LzAccessToken
                $requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
                Write-Host -ForegroundColor Green "Enabled analytics rule "$_.name
            }
            catch {
                Switch ($_.Exception.Response.StatusCode.value__)
                {
                    409 {Write-Host "Alerts creation for Azure Advanced Threat Protection in Sentinel already enabled" -ForegroundColor Yellow}
                    default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
                }
            }
        }
    }
    catch {
        Switch ($_.Exception.Response.StatusCode.value__)
        {
            409 {Write-Host "Alerts creation for Azure Advanced Threat Protection in Sentinel already enabled" -ForegroundColor Yellow}
            default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
        }
    }
}
Export-ModuleMember -Function Set-LzAzureATPAlertRule