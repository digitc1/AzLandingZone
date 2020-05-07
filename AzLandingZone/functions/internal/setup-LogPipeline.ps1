Function setup-LogPipeline {
    param(
        [Parameter][string]$SOC,
        [Parameter(Mandatory=$true)][string]$name
    )

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Host "No Resource Group for Secure Landing Zone found"
            Write-Host "Please run setup script before running the policy script"
            return 1;
    }

    switch ( $SOC ){
        DIGIT {
            Write-Host "Checking log analytics workspace and Azure Sentinel in the Secure Landing Zone" -ForegroundColor Yellow
            if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
                $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
                $workspaceName = $name +"-workspace"+$rand
                $GetLogAnalyticsWorkspace = New-AzOperationalInsightsWorkspace -Location $AzDCLocation -Name $workspaceName -Sku Standard -ResourceGroupName $GetResourceGroup.ResourceGroupName
                Set-AzSentinel -WorkspaceName $workspaceName
            }
        }
        CERTEU {
            Write-Host "Checking event-hub namespace in the Secure Landing Zone" -ForegroundColor Yellow
            if(!($GetEventHubNamespace = Get-AzEventHubNameSpace -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.Name -Like "$name*"})){
                $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
                $eventHubNamespace= $name +"-ehns"+$rand
                $GetEventHubNamespace = New-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $eventHubNamespace -Location $AzDCLocation
            }
        }
        default {
            Write-Host "Checking log analytics workspace in the Secure Landing Zone" -ForegroundColor Yellow
            if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
                Write-Host "Do you want to deploy and configure Azure Log Analytics for this subscription (required for integration with DIGIT-S)"
                $param = read-Host "enter y or n (default No)"
                if($param -Like "y") {
                    $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
                    $workspaceName = $name +"-workspace"+$rand
                    $GetLogAnalyticsWorkspace = New-AzOperationalInsightsWorkspace -Location $AzDCLocation -Name $workspaceName -Sku Standard -ResourceGroupName $GetResourceGroup.ResourceGroupName
                    Set-AzSentinel -WorkspaceName $workspaceName
                }
            }

            Write-Host "Checking event-hub namespace in the Secure Landing Zone" -ForegroundColor Yellow
            if(!($GetEventHubNamespace = Get-AzEventHubNameSpace -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.Name -Like "$name*"})){
                Write-Host "Do you want to deploy and configure Azure eventHubNameSpace for this subscription (required for integration with CERT-EU)"
                $param = read-Host "enter y or n (default No)"
                if($param -Like "y"){
                    $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
                    $eventHubNamespace= $name +"-ehns"+$rand
                    $GetEventHubNamespace = New-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $eventHubNamespace -Location $GetResourceGroup.Location
                }
            }
        }
    }
    if($GetEventHubNamespace){
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
Export-ModuleMember -Function setup-LogPipeline