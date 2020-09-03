# TODO:
# Add support for custom management group by adding a "management group" parameter.
# This should be stored in automation variable
Function setup-Automation {
    param(
        [string]$name = "lzslz",
        [string] $managementGroup = "lz-management-group"
    )

    #
    # External resource required
    #
    $repoURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/runbooks/Update-AzLandingZone.ps1"
    
    #
    # Checking variables and requirements
    #
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        return 1;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup)){
        Write-Host "No Management Group for Secure Landing Zone found"
        return 1;
    }
    $automationAccountName = $name + "Automation"

    #
    # Checking Azure automation account for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Write-Host "Checking automation account in the Secure Landing Zone" -ForegroundColor Yellow
    if(!($GetAutomationAccount = Get-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.AutomationAccountName -Like $automationAccountName})){
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

    if(!( $GetautomationRunbook = Get-AzAutomationRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.Name -Like "*azLandingZone*"} )){
        Invoke-WebRequest -Uri $repoURI -OutFile $HOME/runbook.ps1
        $GetAutomationRunbook = Import-AzAutomationRunbook -Path $HOME/runbook.ps1 -AutomationAccountName $automationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Type "PowerShell" -Name "Update-AzLandingzone" -Published | Out-Null
        Remove-Item -Path $HOME/runbook.ps1
    }

    setup-runAs -name $name -managementGroup $GetManagementGroup.Name

    Write-Host "Checking Azure automation schedule" -ForegroundColor Yellow
    if(!($GetAutomationAccountSchedule = Get-AzAutomationSchedule -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName)){
        $StartTime = (Get-Date).AddDays(7-((Get-Date).DayOfWeek.value__))
        $EndTime = $StartTime.AddYears(1)
        $GetAutomationAccountSchedule = New-AzAutomationSchedule -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Name "lzSchedule" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 7 -ResourceGroupName $GetResourceGroup.ResourceGroupName
        Write-Host "Created automation account schedule"
    }

    if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.RunbookName -Like "Update-AzLandingZone" -And $_.ScheduleName -Like "lzschedule"})){
        Register-AzAutomationScheduledRunbook -RunbookName $GetAutomationRunbook.Name -ScheduleName $GetAutomationAccountSchedule.Name -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
    }
}
Export-ModuleMember -Function setup-Automation