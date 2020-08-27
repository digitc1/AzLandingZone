# TODO:
# Add support for custom management group by adding a "management group" parameter.
# This should be stored in automation variable
Function setup-Automation {
    param(
        [Parameter(Mandatory=$true)][string]$name,
        [string] $managementGroup = "lz-management-group"
    )

    #
    # External resource required
    #
    $automationRunbookURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Fsetup-automation.ps1&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $runAsURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Fsetup-runAs.ps1&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    #
    # TODO:
    # Check with Microsoft for a way to access public resources without token
    # Alternatively, set token a read only on the public part of the Landing Zone
    #
    $token = "hfobtlrxx5cnlcjak5l7bhqwbwfvdwfa7z2u23gjd6wzpllovoxq"
    $repoURI = "https://dev.azure.com/devops0837/LandingZonePublic/_git/LandingZonePublic"
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
    $subscriptionId = (Get-AzContext).Subscription.Id

    #
    # Checking Azure automation account for Azure Landing Zone
    # If it doesn't exist, create it
    #
    Write-Host "Checking automation account in the Secure Landing Zone" -ForegroundColor Yellow
    if(!($GetAutomationAccount = Get-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.AutomationAccountName -Like $automationAccountName})){
        Write-Host "No automation account found"
        Write-Host "Creating automation account"
        $GetAutomationAccount = New-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Location $GetResourceGroup.Location
    }

    #
    # Checking Azure Run As account for Landing Zone automation account
    # If it doesn't exist, create it
    #
    Write-Host "Checking automation runAs account in the Secure Landing Zone" -ForegroundColor Yellow
    if(!($automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"})){
        Do
        {
            Write-Host "No automation RunAs account found"
            Write-Host "Create the automation RunAs account manually according to documentation and press any key to continue"
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        while (!($automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"}))
        #Install-Module -Name "AzureRm.Profile" -Force
        #Install-Module -Name "AzureRm.Resources" -Force
        #$password = ""
        #0..25 | ForEach-Object {$password = $password + (([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9) | Get-Random)}
        #setup-runAs -ResourceGroup $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -ApplicationDisplayName $automationAccountName -subscriptionId $subscriptionId -createClassicRunAsAccount $false -selfSignedCertPlainPassword $password | Out-Null
        #$automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"}
        #New-AzRoleAssignment -ApplicationId $automationServicePrincipal.Id -Scope $scope -RoleDefinitionName "Contributor"
    }

    #
    # Assign contributor at management group level #
    #
    if(!(Get-AzRoleAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.ObjectId -Like $automationServicePrincipal.Id})){
        Write-Host "Role for automation is not assigned at management group level"
        New-AzRoleAssignment -ObjectId $automationServicePrincipal.Id -Scope $GetManagementGroup.Id -RoleDefinitionName "Contributor" | Out-Null
    }

    #
    # Checking source control (for read runbooks)
    #
    Write-Host "Checking automation account source for additional runbooks" -ForegroundColor Yellow
    if(!($GetAutomationSourceControl = Get-AzAutomationSourceControl -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.Name -Like "AzLandingZone"})){
        $secure = ConvertTo-SecureString -String $token -AsPlainText -Force
        New-AzAutomationSourceControl -Name "AzLandingZone" -RepoUrl $repoURI -SourceType "VsoGit" -AccessToken $secure -Branch master -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -FolderPath "/runbooks" -EnableAutoSync | Out-Null
        Start-AzAutomationSourceControlSyncJob -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -Name "AzLandingZone" | Out-Null
    }

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

    #
    # Checking Azure automation runbook for Azure landing zone
    # if it doesn't exist, create it
    #
    Write-Host "Checking Azure automation runbook for Azure landing zone" -ForegroundColor Yellow
    if(!($GetAutomationRunbook = Get-AzAutomationRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName | Where-Object {$_.Name -Like "Update-AzLandingZone"})){
        Write-Host "Runbook did not sync yet. Please re-run this script later." -ForegroundColor Red
    }
    else {
        Write-Host "Checking Azure runbook registration for automation schedule" -ForegroundColor Yellow
        if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.RunbookName -Like "Update-AzLandingZone" -And $_.ScheduleName -Like "lzschedule"})){
            Register-AzAutomationScheduledRunbook -RunbookName $GetAutomationRunbook.Name -ScheduleName "lzschedule" -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
        }
    }
}
Export-ModuleMember -Function setup-Automation