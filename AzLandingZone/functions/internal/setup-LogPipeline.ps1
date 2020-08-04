Function setup-LogPipeline {
    param(
        [Parameter(Mandatory=$true)][string]$name,
        [bool]$enableEventHub = $false,
        [bool]$enableSentinel = $false
    )

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Host "No Resource Group for Secure Landing Zone found"
            Write-Host "Please run setup script before running the policy script"
            return;
    }

    if($enableSentinel){
        Write-Host "Checking log analytics workspace and Azure Sentinel in the Secure Landing Zone" -ForegroundColor Yellow
        if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
            $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
            $workspaceName = $name +"-workspace"+$rand
            $GetLogAnalyticsWorkspace = New-AzOperationalInsightsWorkspace -Location $GetResourceGroup.Location -Name $workspaceName -Sku Standard -ResourceGroupName $GetResourceGroup.ResourceGroupName
            Set-LzSentinel -Name $name
            Set-LzSecurityCenterAlertRule -Name $name
            Connect-LzActiveDirectory
            Set-LzActiveDirectoryAlertRule -Name $name
            Write-Host "Created Landing Zone log analytics"
        }
    }
    if($enableEventHub){
        Write-Host "Checking event-hub namespace in the Secure Landing Zone" -ForegroundColor Yellow
        if(!($GetEventHubNamespace = Get-AzEventHubNameSpace -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.Name -Like "$name*"})){
            $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
            $eventHubNamespace= $name +"-ehns"+$rand
            $GetEventHubNamespace = New-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $eventHubNamespace -Location $GetResourceGroup.Location
            Write-Host "Checking Event Hub 'insights-operational-logs' in the Secure Landing Zone" -ForegroundColor Yellow
            if(!(Get-AzEventHub -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name | Where-Object {$_.Name -Like "insights-operational-logs"})){
                New-AzEventHub -ResourceGroupName $GetResourceGroup.ResourceGroupName -NamespaceName $GetEventHubNamespace.Name -Name "insights-operational-logs" | Out-Null
            }

            Write-Host "Checking Access Key 'landingZoneAccessKey' in the Secure Landing Zone" -ForegroundColor Yellow
            if(!(Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name | Where-Object {$_.Name -like "landingZoneAccessKey"})){
                New-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name -Name "landingZoneAccessKey" -Rights @("Listen","Send","Manage") | Out-Null
            }
        }
    }
    Set-LzActiveDirectoryDiagnosticSettings
}
Export-ModuleMember -Function setup-LogPipeline