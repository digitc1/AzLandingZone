Function setup-LogPipeline {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$true)][string]$name,
        [bool]$enableEventHub = $false,
        [bool]$enableSentinel = $false
    )

    $psWorkspace = $null

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Error "No Resource Group for Secure Landing Zone found"
            Write-Error "Please run setup script before running the policy script"
            return;
    }

    Write-Host "Checking log analytics workspace and Azure Sentinel in the Secure Landing Zone" -ForegroundColor Yellow
#    if($enableSentinel){
        Write-Verbose "Checking log analytics workspace and Azure Sentinel in the Secure Landing Zone"
        if(!($psWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
            $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
            $workspaceName = $name +"-workspace"+$rand
            $psWorkspace = New-AzOperationalInsightsWorkspace -Location $GetResourceGroup.Location -Name $workspaceName -ResourceGroupName $GetResourceGroup.ResourceGroupName 
            Start-Sleep -s 15
            Write-Verbose "Created Landing Zone log analytics"
        }
        if($enableSentinel){
            Set-LzSentinel -Name $name
        }
#    }

    Write-Host "Checking event-hub namespace in the Secure Landing Zone" -ForegroundColor Yellow
    if($enableEventHub){
        Write-Verbose "Checking event-hub namespace in the Secure Landing Zone"
        if(!($GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.Name -Like "$name*"})){
            $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
            $eventHubNamespace= $name +"-ehns"+$rand
            $GetEventHubNamespace = New-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $eventHubNamespace -Location $GetResourceGroup.Location
            Write-Verbose "Created event hub namespace"
        }
        
        Write-Verbose "Checking Event Hub 'insights-operational-logs' in the Secure Landing Zone"
        if(!(Get-AzEventHub -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name | Where-Object {$_.Name -Like "insights-operational-logs"})){
            Write-Verbose "Creating 'insights-operational-logs' event hub"
            New-AzEventHub -ResourceGroupName $GetResourceGroup.ResourceGroupName -NamespaceName $GetEventHubNamespace.Name -Name "insights-operational-logs" | Out-Null
        }

        Write-Verbose "Checking Access Key 'landingZoneAccessKey' in the Secure Landing Zone"
        if(!(Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name | Where-Object {$_.Name -like "landingZoneAccessKey"})){
            Write-Verbose "Creating 'landingZoneAccess Key'"
            New-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name -Name "landingZoneAccessKey" -Rights @("Listen","Send","Manage") | Out-Null
        }
    }

    $result = [PSCustomObject]@{
        law = $psWorkspace
    }
    
    return $result
}
Export-ModuleMember -Function setup-LogPipeline
