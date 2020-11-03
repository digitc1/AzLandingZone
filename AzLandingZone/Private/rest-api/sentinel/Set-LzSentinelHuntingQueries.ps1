Function Set-LzSentinelHuntingQueries {
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
    
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/develop/definitions/sentinel/hunting/definitionList.txt" -Method Get -OutFile "$HOME/definitionList.txt"
    Get-Content "$HOME/definitionList.txt" | ForEach-Object {
        $definitionId = $_.Split(',')[0]
        $definitionName = $_.Split(',')[1]
        $definitionUri = $_.Split(',')[2]

        $query = (Invoke-WebRequest -Uri $definitionUri -Method Get).Content
        $body = [PSCustomObject]@{
            'properties' = @{
                'Category' = 'Hunting Queries'
                'DisplayName' = $definitionName 
                'Query' = $query
            }
        }
        $uri = "https://management.azure.com" + $GetWorkspace.ResourceId + "/savedSearches/" + $definitionId + "?api-version=2020-08-01"
        try{
            Write-Host -ForegroundColor Green "Creating custom hunting query: "$definitionName
            $auth = Get-LzAccessToken
            $requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
            Write-Host -ForegroundColor Green "Created custom hunting query: "$definitionName
        }
        catch {
            Switch ($_.Exception.Response.StatusCode.value__)
            {
                409 {Write-Host "Connection already exists" -ForegroundColor Yellow}
                default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
            }
        }
    }
    Remove-Item -Path "$HOME/definitionList.txt"
}
Export-ModuleMember -Function Set-LzSentinelHuntingQueries