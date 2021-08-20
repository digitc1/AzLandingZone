Function setup-Automation {
    param(
        [string]$name = "lzslz",
        [string] $managementGroup = "lz-management-group",
        [int]$retentionPeriod = 185
    )

    #
    # External resource required
    #
    $runbookListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/runbooks/definitionList.txt"
    
    #
    # Checking variables and requirements
    #
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        return;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup)){
        Write-Host "No Management Group for Secure Landing Zone found"
        return;
    }

    #
    # Checking Azure automation account for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Write-Host "Checking automation account in the Secure Landing Zone" -ForegroundColor Yellow
    if(!($GetAutomationAccount = Get-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.AutomationAccountName -Like "$name*"})){
        $automationAccountName = $name + "Automation"
        $GetAutomationAccount = New-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Location $GetResourceGroup.Location
        Write-Host "Created automation account"
    }

    #
    # Automation variables
    #
    Write-Host "Checking automation variables" -ForegroundColor "Yellow"
    if(!( Get-AzAutomationVariable -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "name"} )){
        New-AzAutomationVariable -Encrypted $false -Name "name" -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Value $name | Out-Null
        Write-Host "Created automation variable 'name'"
    }
    if(!( Get-AzAutomationVariable -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "managementGroupName"} )){
        New-AzAutomationVariable -Encrypted $false -Name "managementGroupName" -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Value $GetManagementGroup.Name | Out-Null
        Write-Host "Created automation variable 'managementGroupName'"
    }
    if(!( Get-AzAutomationVariable -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "retentionPeriod"} )){
        New-AzAutomationVariable -Encrypted $false -Name "retentionPeriod" -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Value $retentionPeriod | Out-Null
        Write-Host "Created automation variable 'retentionPeriod'"
    }

    #
    # Checking automation account runbooks for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Invoke-WebRequest -Uri $runbookListURI -OutFile $HOME/definitionList.txt
    Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
        $runbookName = "SLZ-" + $_.Split(',')[0]
        $runbookLink = $_.Split(',')[1]
        Write-Host -ForegroundColor Yellow "Checking automation runbook: $runbookName"
        if(!(Get-AzAutomationRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -eq $runbookName})){
            Invoke-WebRequest -Uri $runbookLink -OutFile $HOME/$runbookName.ps1
            Import-AzAutomationRunbook -Path $HOME/runbook.ps1 -AutomationAccountName $GetAutomationAccount.AutomationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Type "PowerShell" -Name $runbookName -Published | Out-Null
            remove-Item -Path $HOME/$runbookName.ps1
            Write-Host "Created automation runbook: $runbookName"
        }
    }
    Remove-Item -Path $HOME/definitionList.txt

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
    update-AzAutomationModules

    #
    # Checking Azure automation account schedule
    # If it doesn't exist, create it
    # Default value is every Sunday
    #
    Write-Host "Checking Azure automation schedule" -ForegroundColor Yellow
    if(!($GetAutomationAccountSchedule = Get-AzAutomationSchedule -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName)){
        $StartTime = (Get-Date).AddDays(7-((Get-Date).DayOfWeek.value__))
        $EndTime = $StartTime.AddYears(1)
        $GetAutomationAccountSchedule = New-AzAutomationSchedule -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Name "lzSchedule" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 7 -ResourceGroupName $GetResourceGroup.ResourceGroupName
        Write-Host "Created automation account schedule"
    }

    #
    # Link schedule with runbook
    #
    $runbooks = Get-AzAutomationRunbook -ResourceGroupName $GetManagementGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName
    foreach ($runbook in $runbooks) {
        Write-Host -ForegroundColor Yellow "Checking scheduled task for $($runbook.Name)"
        if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.RunbookName -Like $($runbook.Name) -And $_.ScheduleName -Like $GetAutomationAccountSchedule.Name})){
            Register-AzAutomationScheduledRunbook -RunbookName $($runbook.Name) -ScheduleName $GetAutomationAccountSchedule.Name -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
            Write-Host "Created scheduled task for $($runbook.Name)"
        }
    }
#    if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.RunbookName -Like "Update-AzLandingZone" -And $_.ScheduleName -Like "lzschedule"})){
#        Register-AzAutomationScheduledRunbook -RunbookName $GetUpdateRunbook.Name -ScheduleName $GetAutomationAccountSchedule.Name -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
#    }
#    if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.RunbookName -Like "Update-AzLandingZone" -And $_.ScheduleName -Like "lzschedule"})){
#        Register-AzAutomationScheduledRunbook -RunbookName $GetSyncRunbook.Name -ScheduleName $GetAutomationAccountSchedule.Name -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
#    }
}
Export-ModuleMember -Function setup-Automation
