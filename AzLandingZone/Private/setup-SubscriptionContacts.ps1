#
# Breaking changes to this function
# The function will now deploy a policy (deployifnotexist) that checks the security contacts
# This function no longer deploys the contacts by it's own
#

Function setup-SubscriptionContacts {
    param(
        [ValidateSet("DIGIT", "CERTEU", "None", "")]
        [string] $SOC,
        [String[]]$securityContacts
    )

    #
    # External resources
    #
    $definitionSecurityCenterContactURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterContact.json"
    $securityCenterContactParametersURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterContact.parameters.json"

    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group" -Expand | Where-Object {$_.Name -Like "lz-management-group"})){
            Write-Host "No Management group found for Secure Landing Zone"
            Write-Host "Please run setup script before running the policy script"
            return 1;
    }
    $scope = $GetManagementGroup.Id

    Invoke-WebRequest -Uri $definitionSecurityCenterContactURI -OutFile $HOME/rule.json
    Invoke-WebRequest -Uri $securityCenterContactParametersURI -OutFile $HOME/parameters.json

    if(!($policyDefinition = Get-AzPolicyDefinition -ManagementGroupName "lz-management-group" | Where-Object {$_.Name -Like "SLZ-securityContact"})){
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-securityContact" -Policy $HOME/rule.json -Parameter $HOME/parameters.json -ManagementGroupName "lz-management-group"
    }

    Write-Host "Checking registration for DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu as security contact" -ForeGroundColor Yellow
    if(!(Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like "SLZ-securityContact1"})){
        New-AzPolicyAssignment -name "SLZ-securityContact1" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location "westeurope" -contactEmail "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu" -contactName "default1" | Out-Null
    }

    if($SOC -eq "DIGIT"){
        Write-Host "Checking registration for EC-DIGIT-CSIRC@ec.europa.eu as security contact" -ForeGroundColor Yellow
        if(!(Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like "SLZ-securityContact2"})){
            New-AzPolicyAssignment -name "SLZ-securityContact2" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location "westeurope" -contactEmail "EC-DIGIT-CSIRC@ec.europa.eu" -contactName "default2" | Out-Null
        }
        Write-Host "Checking registration for EC-DIGIT-CLOUDSEC@ec.europa.eu as security contact" -ForeGroundColor Yellow
        if(!(Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like "SLZ-securityContact3"})){
            New-AzPolicyAssignment -name "SLZ-securityContact3" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location "westeurope" -contactEmail "EC-DIGIT-CLOUDSEC@ec.europa.eu" -contactName "default3" | Out-Null
        }
    }

    foreach ($contact in $securityContacts)  
    { 
        if($contact -notin ((Get-AzPolicyAssignment -Scope $scope | where-Object {$_.Name -Like "SLZ-securityContact*"}).Properties.Parameters.contactEmail.value)){
            $count = (Get-AzPolicyAssignment -Scope $scope | where-Object {$_.Name -Like "SLZ-securityContact*"}).Count
            New-AzPolicyAssignment -name "SLZ-securityContact$($count+1)" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location "westeurope" -contactEmail $contact -contactName "default$($count+1)" | Out-Null
        }
    }

    Remove-item -Path $HOME/rule.json
    Remove-item -Path $HOME/parameters.json
}
Export-ModuleMember -Function setup-SubscriptionContacts