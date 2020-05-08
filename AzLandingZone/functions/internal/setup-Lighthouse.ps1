Function setup-Lighthouse {
    param(
            [ValidateSet("DIGIT", "CERTEU", "None", "")]
            [string] $SOC
    )

    $delegatedResourceManagementURI = ""
    $delegatedResourceManagementparametersURI = ""
    #
    # Get the list of children for the management group
    #
    (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children | ForEach-Object {
            Set-AzContext -SubscriptionId $_.Name | Out-Null

            #
            # Set contact email address
            #
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
    #
    # Following values have been hard-coded in the parameters file:
    # Security Reader (read access to the security center) and Log analytics reader (Read access to Azure Log Analytics workspace and all logs) to DIGIT-S1
    # Security Reader (read access to the security center) and Log analytics reader (Read access to Azure Log Analytics workspace and all logs) to DIGIT-S2
    #
        if($SOC -eq "DIGIT"){
                if(!(Get-AzManagedServicesDefinition | Where-Object {$_.Properties.ManagedByTenantId -Like "3a8968a8-fbcf-4414-8b5c-77255f50f37b"})){
                        Invoke-WebRequest -Uri $delegatedResourceManagementURI -OutFile $HOME/delegatedResourceManagement.json
                        Invoke-WebRequest -Uri $delegatedResourceManagementURI -OutFile $HOME/delegatedResourceManagement.parameters.json
                        New-AzDeployment -Name LightHouse -Location "westeurope" -TemplateFile $HOME/delegatedResourceManagement.json -TemplateParameterFile $HOME/delegatedResourceManagement.parameters.json | Out-Null
                        Remove-Item -Path $HOME/delegatedResourceManagement.parameters.json
                        Remove-Item -Path $HOME/delegatedResourceManagement.json
                        Write-Host "Delegation created for DIGIT S"
                }
        }
    }
}
Export-ModuleMember -Function setup-Lighthouse