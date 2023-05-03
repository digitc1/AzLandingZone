Function set-AutomationAccount {
    [cmdletbinding()]

    param(
        [string]$name = "lzslz"
    )

    #
    # Guard
    # check if RG exists
    #
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Error "No Resource Group for Secure Landing Zone found"
        return;
    }
    $automationAccountName = $name + "Automation"

    #
    # Checking Azure automation account for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Write-Verbose "Checking automation account in the Secure Landing Zone"
    if(!($automationAccount = Get-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.AutomationAccountName -Like "$name*"})){
        Write-Verbose "Creating Azure Landing Zone automation account"
        $automationAccount = New-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Location $GetResourceGroup.Location
    }
    
    if(!($automation.Identity)){
        Set-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -AssignSystemIdentity
    }
    
    return $automationAccount
}
Export-ModuleMember -Function set-AutomationAccount
