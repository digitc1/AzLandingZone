Function setup-SubscriptionContacts {
    param(
        [ValidateSet("DIGIT", "CERTEU", "None", "")]
        [string] $SOC
    )

    Write-Host "Checking that security center notification is set to DIGIT_VIRTUAL_TASK_FORCE@ec.europa.eu" -ForegroundColor Yellow
    if(!(Get-AzSecurityContact | Where-Object {$_.Email -Like "DIGIT-VIRTUAL-TASK-FORCE@ec.europa.eu"})){
            $count = (Get-AzSecurityContact).Count
            Set-AzSecurityContact -Name "default$($count+1)" -Email "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu" -AlertAdmin -NotifyOnAlert | Out-Null
    }
    if($SOC -eq "DIGIT"){
        Write-Host "Checking that security center notification is set to EC-DIGIT-CSIRC@ec.europa.eu" -ForegroundColor Yellow
        if(!(Get-AzSecurityContact | Where-Object {$_.Email -Like "EC-DIGIT-CSIRC@ec.europa.eu"})){
                        $count = (Get-AzSecurityContact).Count
                        Set-AzSecurityContact -Name "default$($count+1)" -Email "EC-DIGIT-CSIRC@ec.europa.eu" -AlertAdmin -NotifyOnAlert | Out-Null
        }
        Write-Host "Checking that security center notification is set to EC-DIGIT-CLOUDSEC@ec.europa.eu" -ForegroundColor Yellow
        if(!(Get-AzSecurityContact | Where-Object {$_.Email -Like "EC-DIGIT-CLOUDSEC@ec.europa.eu"})){
                        $count = (Get-AzSecurityContact).Count
                        Set-AzSecurityContact -Name "default$($count+1)" -Email "EC-DIGIT-CLOUDSEC@ec.europa.eu" -AlertAdmin -NotifyOnAlert | Out-Null
        }
    }
    $param = read-Host "Would you like to setup additional contacts for security alerts (y/n)"
    while($param -Like "y"){
            $param -Like "n"
            $tmp = Read-Host "Enter the email address for new contact"
            $count = (Get-AzSecurityContact).Count
            Set-AzSecurityContact -Name "default$($count+1)" -Email $tmp -AlertAdmin -NotifyOnAlert | Out-Null
            $param = Read-Host "Successfully added security contact. Add another (y/n) ?"
    }
}
Export-ModuleMember -Function setup-SubscriptionContacts