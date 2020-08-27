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
        Write-Host "Please run setup script before"
        return 1;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup)){
        Write-Host "No Management Group for Secure Landing Zone found"
        Write-Host "Please run setup script before"
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

    #
    # Checking Azure Run As account for Landing Zone automation account
    # If it doesn't exist, create it
    #
    #Write-Host "Checking automation runAs account in the Secure Landing Zone" -ForegroundColor Yellow
    #if(!($automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"})){
    #    Do
    #    {
    #        Write-Host "No automation RunAs account found"
    #        Write-Host "Create the automation RunAs account manually according to documentation and press any key to continue"
    #        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    #    }
    #    while (!($automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"}))
        #Install-Module -Name "AzureRm.Profile" -Force
        #Install-Module -Name "AzureRm.Resources" -Force
        #$password = ""
        #0..25 | ForEach-Object {$password = $password + (([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9) | Get-Random)}
        #setup-runAs -ResourceGroup $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -ApplicationDisplayName $automationAccountName -subscriptionId $subscriptionId -createClassicRunAsAccount $false -selfSignedCertPlainPassword $password | Out-Null
        #$automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"}
        #New-AzRoleAssignment -ApplicationId $automationServicePrincipal.Id -Scope $scope -RoleDefinitionName "Contributor"
    #}

    #
    # Assign contributor at management group level #
    #
    #if(!(Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" | Where-Object {$_.ObjectId -Like $automationServicePrincipal.Id})){
    #    Write-Host "Role for automation is not assigned at management group level"
    #    New-AzRoleAssignment -ObjectId $automationServicePrincipal.Id -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" -RoleDefinitionName "Contributor" | Out-Null
    #}
    setup-runAs -name $name -managementGroup $GetManagementGroup.Name

    if(!( $GetautomationRunbook = Get-AzAutomationRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.Name -Like "*azLandingZone*"} )){
        #New-AzAutomationRunbook -AutomationAccountName $automationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name "Update-AzLandingzone"
        Invoke-WebRequest -Uri $repoURI -OutFile $HOME/runbook.ps1
        $GetAutomationRunbook = Import-AzAutomationRunbook -Path $HOME/runbook.ps1 -AutomationAccountName $automationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Type "PowerShell" -Name "Update-AzLandingzone" -Published | Out-Null
        Remove-Item -Path $HOME/runbook.ps1
    }
    
    #
    # Checking source control (for read runbooks)
    #
    #Write-Host "Checking automation account source for additional runbooks" -ForegroundColor Yellow
    #if(!($GetAutomationSourceControl = Get-AzAutomationSourceControl -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.Name -Like "AzLandingZone"})){
    #    $secure = ConvertTo-SecureString -String $token -AsPlainText -Force
    #    New-AzAutomationSourceControl -Name "AzLandingZone" -RepoUrl $repoURI -SourceType "VsoGit" -AccessToken $secure -Branch master -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -FolderPath "/runbooks" -EnableAutoSync | Out-Null
    #    Start-AzAutomationSourceControlSyncJob -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -Name "AzLandingZone" | Out-Null
    #}

    #
    # Checking Azure automation schedule
    # If it doesn't exist, create it (default schedule runs once a week)
    #
    Write-Host "Checking Azure automation schedule" -ForegroundColor Yellow
    if(!($GetAutomationAccountSchedule = Get-AzAutomationSchedule -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName)){
        Write-Host "No automation account schedule found"
        Write-Host "Creating automation account schedule"
        $StartTime = (Get-Date).AddDays(7-((Get-Date).DayOfWeek.value__))
        $EndTime = $StartTime.AddYears(1)
        $GetAutomationAccountSchedule = New-AzAutomationSchedule -AutomationAccountName $GetAutomationAccount.AutomationAccountName -Name "lzSchedule" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 7 -ResourceGroupName $GetResourceGroup.ResourceGroupName
    }

    if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.RunbookName -Like "Update-AzLandingZone" -And $_.ScheduleName -Like "lzschedule"})){
        Register-AzAutomationScheduledRunbook -RunbookName $GetAutomationRunbook.Name -ScheduleName $GetAutomationAccountSchedule.Name -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
    }
}
Export-ModuleMember -Function setup-Automation