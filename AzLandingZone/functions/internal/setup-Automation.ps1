Function setup-Automation {
    param(
        [Parameter(Mandatory=$true)][string]$name
    )

    #
    # External resource required
    #
    $automationRunbookURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Fsetup-automation.ps1&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $runAsURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Fsetup-runAs.ps1&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    #
    # TODO:
    # Provide a token with read access on code repo
    #
    #$token = "kxuyox3celk4uagq2qjsgvldz6us55meya3hgybve22mafquux7a"
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
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group")){
        Write-Host "No Management Group for Secure Landing Zone found"
        Write-Host "Please run setup script before"
        return 1;
    }
    $automationAccountName = $name + "Automation"
    $subscriptionId = (Get-AzSubscription | Where-Object {$_.Name -Like "SECLOG*"}).Id

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
    Write-Host "Using Automation Account : "$GetAutomationAccount.AutomationAccountName

    #
    # Checking source control (for read runbooks)
    #
    Write-Host "Checking automation account source for additional runbooks" -ForegroundColor Yellow
    if(!($GetAutomationSourceControl = Get-AzAutomationSourceControl -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.Name -Like "AzLandingZone"})){
        $secure = ConvertTo-SecureString -String $token -AsPlainText -Force
        New-AzAutomationSourceControl -Name "AzLandingZone" -RepoUrl $repoURI -SourceType "VsoGit" -AccessToken $secure -Branch master -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -FolderPath "/runbooks" -EnableAutoSync | Out-Null
    }

    #
    # Checking Azure Run As account for Landing Zone automation account
    # If it doesn't exist, create it
    #
    Write-Host "Checking automation runAs account in the Secure Landing Zone" -ForegroundColor Yellow
    if(!($automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"})){
        Write-Host "No automation RunAs account found"
        Write-Host "To be created manually"
        # TODO #
        # generate password #
        $randomPassword = "zaefisfndsqdpnfgsdjlflkdsqnf"
        # TODO #
        # review Invoke-WebRequest cmdlet #
        #setup-runAs -ResourceGroup $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -ApplicationDisplayName $automationAccountName -subscriptionId $subscriptionId -createClassicRunAsAccount $false -selfSignedCertPlainPassword $randomPassword | Out-Null
        #Invoke-WebRequest -Uri "$runAsURI" -OutFile ./runAs.ps1
        #./runAs.ps1  -ResourceGroup $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName -ApplicationDisplayName $automationAccountName -subscriptionId $subscriptionId -createClassicRunAsAccount $false -selfSignedCertPlainPassword $randomPassword | Out-Null
        #$automationServicePrincipal = Get-AzAdServicePrincipal | Where-Object {$_.DisplayName -Like "*$automationAccountName*"}
        #Remove-Item -Path ./runAs.ps1
        #New-AzRoleAssignment -ApplicationId $automationServicePrincipal.Id -Scope $scope -RoleDefinitionName "Contributor"
    }
    Write-Host "Using automation account service principal : "$automationServicePrincipal.DisplayName

    # TODO #
    # Assign contributor at management group level #

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
        Write-Host "Error: Runbook not found" -ForegroundColor Red
    }
    else {
        Write-Host "Checking Azure runbook registration for automation schedule" -ForegroundColor Yellow
        if(!(Get-AzAutomationScheduledRunbook -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $automationAccountName | Where-Object {$_.RunbookName -Like "Update-AzLandingZone" -And $_.ScheduleName -Like "lzschedule"})){
            Register-AzAutomationScheduledRunbook -RunbookName $GetAutomationRunbook. -ScheduleName "lzschedule" -AutomationAccountName $GetAutomationAccount.AutomationAccountName -resourceGroupName $GetResourceGroup.ResourceGroupName | Out-Null
        }
    }
}
Export-ModuleMember -Function setup-Automation