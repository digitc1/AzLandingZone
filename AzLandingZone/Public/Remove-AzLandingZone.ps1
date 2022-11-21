Function Remove-AzLandingZone {
    <#
        .SYNOPSIS
        Remove all the components of the Landing Zone except storage account for legal hold
        .DESCRIPTION
        Remove all the components of the Landing Zone except storage account for legal hold
        .PARAMETER managementGroup
        Enter the name for AzLandingZone management group. If the management group already exist, it is reused for AzLandingZone.
        .EXAMPLE
        Remove-AzLandingZone
    #>
    Param (
        [string]$managementGroup = "lz-management-group"
    )
    
    if($GetManagementGroup = Get-AzManagementGroup -ErrorAction "silentlyContinue" | Where-Object {$_.Name -Like $managementGroup}){
        Write-Host "Removing Landing Zone manamagement group" -ForegroundColor Yellow
        try{
            (Get-AzManagementGroup -Expand -GroupName $GetManagementGroup.Name).Children | ForEach-Object {
                Remove-AzManagementGroupSubscription -GroupName $GetManagementGroup.Name -SubscriptionId ($_.Id.Split("/"))[2]
                
                Write-Host ("Keep Azure security center standard tier for subscription "+ $_.DisplayName +"?")
                $param = read-Host "enter y or n (default Yes)"
                if($param -Like "n") {
                    Write-Host "Removing security center configuration" -ForegroundColor Yellow
                    Set-LzSecurityCenterPricing -SubscriptionId $_.Id.Split("/")[2] -pricingTier "Free"
                }
                
            }
        }
        catch {} # Could not find any children, nothing to do
        Remove-AzManagementGroup -GroupName $GetManagementGroup.Name
    }
    
    if($GetResourceGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -Like "lzslz*"}){
        if($GetResourceLock = Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"}){
            Write-Host "Removing Landing Zone resource lock" -ForegroundColor Yellow
            Remove-AzResourceLock -LockId $GetResourceLock.ResourceId -Force | Out-Null
        }
        if($GetAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.AutomationAccountName -Like "lzslzAutomation"}){
            Write-Host "Removing Landing Zone automation" -ForegroundColor Yellow
            if($GetAutomationServicePrincipal = Get-AzADApplication | Where-Object {$_.DisplayName -Like "lzslzAutomation*"}){
                Get-AzRoleAssignment | Where-Object {$_.DisplayName -Like $GetAutomationServicePrincipal.DisplayName} | Remove-AzRoleAssignment | Out-Null
                Remove-AzADApplication -ObjectId $GetAutomationServicePrincipal.ObjectId -Force
            }
            Remove-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $GetAutomationAccount.AutomationAccountName -Force
        }
        if($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName){
            Write-Host "Removing Landing Zone analytics workspace and sentinel" -ForegroundColor Yellow
            Remove-AzOperationalInsightsWorkspace -Name $GetLogAnalyticsWorkspace.Name -ResourceGroupName $GetResourceGroup.ResourceGroupName -Force
        }
        if($GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName){
            Write-Host "Removing Landing Zone eventHub" -ForegroundColor Yellow
            Remove-AzEventHubNamespace -InputObject $GetEventHubNamespace
        }
    }
}
Export-ModuleMember -Function Remove-AzLandingZone

