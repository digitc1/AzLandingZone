Function setup-Automation {
    [cmdletbinding()]

    param(
        [string]$name = "lzslz",
        [string] $managementGroup = "lz-management-group"
    )

    #
    # External resource required
    #
    $runbookListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/runbooks/definitionList.txt"
    
    #
    # Checking variables and requirements
    #
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Error "No Resource Group for Secure Landing Zone found"
        return;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup)){
        Write-Error "No Management Group for Secure Landing Zone found"
        return;
    }

    #
    # Checking Azure automation account for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Write-Verbose "Checking automation account in the Secure Landing Zone"
    if(!($GetAutomationAccount = Get-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.AutomationAccountName -Like "$name*"})){
        Write-Error "No Automation Account for Secure Landing Zone found"
        return;
    }

    Write-Host "Checking Azure Landing Zone auto-update feature" -ForegroundColor Yellow
    #
    # Automation variables
    #
    Write-Verbose "Checking automation variables"
    if(!( Get-AzAutomationVariable -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "name"} )){
        New-AzAutomationVariable -Encrypted $false -Name "name" -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Value $name | Out-Null
        Write-Verbose "Created automation variable 'name'"
    }
    if(!( Get-AzAutomationVariable -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "managementGroupName"} )){
        New-AzAutomationVariable -Encrypted $false -Name "managementGroupName" -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Value $GetManagementGroup.Name | Out-Null
        Write-Verbose "Created automation variable 'managementGroupName'"
    }
#    if(!( Get-AzAutomationVariable -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "retentionPeriod"} )){
#        New-AzAutomationVariable -Encrypted $false -Name "retentionPeriod" -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Value $retentionPeriod | Out-Null
#        Write-Verbose "Created automation variable 'retentionPeriod'"
#    }

    #
    # Checking automation account runbooks for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Write-Verbose "Checking automation runbooks"
    Invoke-WebRequest -Uri $runbookListURI -OutFile $HOME/definitionList.txt
    Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
        $runbookName = $_.Split(',')[0]
        $runbookLink = $_.Split(',')[1]
        if(!(Get-AzAutomationRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -eq $runbookName})){
            Invoke-WebRequest -Uri $runbookLink -OutFile $HOME/$runbookName.ps1
            Import-AzAutomationRunbook -Path $HOME/$runbookName.ps1 -AutomationAccountName $GetAutomationAccount.AutomationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Type "PowerShell" -Name $runbookName -Published | Out-Null
            remove-Item -Path $HOME/$runbookName.ps1
            Write-Verbose "Created automation runbook: $runbookName"
        }
    }
    Remove-Item -Path $HOME/definitionList.txt

    #
    # Checking Azure automation account schedule
    # If it doesn't exist, create it
    # Default value is every Sunday
    #
    Write-Verbose "Checking Azure automation schedule"
    if(!($GetAutomationAccountSchedule = Get-AzAutomationSchedule -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName)){
        $StartTime = (Get-Date).AddDays(7-((Get-Date).DayOfWeek.value__))
        $EndTime = $StartTime.AddYears(1)
        $GetAutomationAccountSchedule = New-AzAutomationSchedule -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Name "lzSchedule" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 7 -ResourceGroupName $GetResourceGroup.ResourceGroupName
        Write-Verbose "Created automation account schedule"
    }

    #
    # Link schedule with runbook
    #
    $runbooks = Get-AzAutomationRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName
    foreach ($runbook in $runbooks) {
        Write-Verbose "Checking scheduled task for $($runbook.Name)"
        if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.RunbookName -Like $($runbook.Name) -And $_.ScheduleName -Like $GetAutomationAccountSchedule.Name})){
            Register-AzAutomationScheduledRunbook -RunbookName $($runbook.Name) -ScheduleName $GetAutomationAccountSchedule.Name -AutomationAccountName $GetAutomationAccount.AutomationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
            Write-Verbose "Created scheduled task for $($runbook.Name)"
        }
    }

    #
    # Checking the Azure AD application for Azure automation account
    # If it doesn't exist, create it
    # Moved to external function for sake of clarity
    #
    setup-runAs -name $name -managementGroup $GetManagementGroup.Name

    #
    # Checking Azure automation modules for required modules
    # If modules are not found, import
    # If module are found, update to the latest version
    # Moved to external function for sake of clarity
    #
    #update-AzAutomationModules -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName
    Write-Host "
    The script failed to update Azure powershell modules in the Azure automation account.
    Follow below documentation to update all modules manually.
    https://learn.microsoft.com/en-us/azure/automation/automation-update-azure-modules
    "
}
Export-ModuleMember -Function setup-Automation
