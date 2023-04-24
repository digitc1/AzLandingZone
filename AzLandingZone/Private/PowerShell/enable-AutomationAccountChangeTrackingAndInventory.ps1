Function enable-AutomationAccountChangeTrackinAndInventory {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$true)][string]$name,
        [Parameter(Mandatory=$true)][string]$automationAccountName,
        [Parameter(Mandatory=$true)][string]$lawName
    )

    #
    # Guard
    # Get/check if RG exists
    #
    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Error "No Resource Group for Secure Landing Zone found"
        Write-Error "Please run setup script before running the policy script"
        return;
    }

    #
    # Guard
    # Get/check required automation account
    #
    if(!($automationAccount = Get-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $automationAccountName)){
        Write-Error "No Automation Account for Secure Landing Zone found"
        return;
    }   
    
    $subscriptionId = $automationAccount.SubscriptionId

    #
    # Guard
    # Check if log analytics workspace exists
    #
    if(!($law = Get-AzOperationalInsightsWorkspace -Name $lawName -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        Write-Error "No Secure Landing Zone Log Analytics Workspace found"
        return;
    }


    # Link the Log Analytics Workspace with the Automation Account
    Set-AzOperationalInsightsLinkedService -ResourceGroupName $GetResourceGroup.ResourceGroupName -WorkspaceName $lawName -LinkedServiceName Automation -WriteAccessResourceId "/subscriptions/$subscriptionId/resourceGroups/$($GetResourceGroup.ResourceGroupName)/providers/Microsoft.Automation/automationAccounts/$automationAccountName"
 
    # Wnable the Change Tracking solution
    Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $GetResourceGroup.ResourceGroupName -WorkspaceName -WorkspaceName -IntelligencePackName "ChangeTracking" -Enabled $true 

}
Export-ModuleMember -Function enable-AutomationAccountChangeTrackinAndInventory
