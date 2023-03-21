Function enable-AutomationAccountChangeTrackinAndInventory {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$true)][string]$resourceGroupName,
        [Parameter(Mandatory=$true)][string]$automationAccountName,
        [Parameter(Mandatory=$true)][string]$lawName
    )

    #
    # Guard
    # Get/check if RG exists
    #
    if(!($resourceGroup = Get-AzResourceGroup -ResourceGroupName "*$resourceGroupName*")){
        Write-Error "No Resource Group for Secure Landing Zone found"
        return;
    }

    #
    # Guard
    # Get/check required automation account
    #
    if(!($automationAccount = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccountName)){
        Write-Error "No Automation Account for Secure Landing Zone found"
        return;
    }   
    
    $subscriptionId = $automationAccount.SubscriptionId

    #
    # Guard
    # Check if log analytics workspace exists
    #
    if(!($law = Get-AzOperationalInsightsWorkspace -Name $lawName -ResourceGroupName $resourceGroupName)){
        Write-Error "No Secure Landing Zone Log Analytics Workspace found"
        return;
    }


    # Link the Log Analytics Workspace with the Automation Account
    Set-AzOperationalInsightsLinkedService -ResourceGroupName $resourceGroupName -WorkspaceName $lawName -LinkedServiceName Automation -WriteAccessResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$automationAccountName"
 
    # Wnable the Change Tracking solution
    Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $resourceGroupName -WorkspaceName -WorkspaceName -IntelligencePackName "ChangeTracking" -Enabled $true 

}
Export-ModuleMember -Function enable-AutomationAccountChangeTrackinAndInventory
