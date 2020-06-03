#
# Breaking changes to this function
# The function will now deploy a policy (deployifnotexist) that checks the security contacts
# This function no longer deploys the contacts by it's own
#

Function setup-SubscriptionContacts {
    param(
        [ValidateSet("DIGIT", "CERTEU", "None", "")]
        [string] $SOC
    )

    #
    # External resources
    #
    $definitionSecurityCenterContactURI = ""
    $securityCenterContactParametersURI = ""

    Invoke-WebRequest -Uri $definitionSecurityCenterContactURI -OutFile $HOME/rule.json
    Invoke-WebRequest -Uri $securityCenterContactURI -OutFile $HOME/parameters.json

    if(!($policyDefinition = Get-AzPolicyDefinition | Where-Object {$_.Name -Like "SLZ-securityContact"})){
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-securityContact1" -Policy $HOME/rule.json -Parameter $HOME/parameters.json -ManagementGroupName "lz-management-group"
    }

    if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "SLZ-securityContact1"})){
        New-AzPolicyAssignment -name "SLZ-securityContact1" -PolicyDefinition $policyDefinition -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" -AssignIdentity -Location "westeurope" -contactEmail "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu" -contactName "default1" | Out-Null
    }

    if($SOC -eq "DIGIT"){
        if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "SLZ-securityContact2"})){
            New-AzPolicyAssignment -name "SLZ-securityContact2" -PolicyDefinition $policyDefinition -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" -AssignIdentity -Location "westeurope" -contactEmail "EC-DIGIT-CSIRC@ec.europa.eu" -contactName "default2" | Out-Null
        }
        if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "SLZ-securityContact3"})){
            New-AzPolicyAssignment -name "SLZ-securityContact3" -PolicyDefinition $policyDefinition -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" -AssignIdentity -Location "westeurope" -contactEmail "EC-DIGIT-CLOUDSEC@ec.europa.eu" -contactName "default3" | Out-Null
        }
    }

    $param = read-Host "Would you like to setup additional contacts for security alerts (y/n)"
    while($param -Like "y"){
            $param -Like "n"
            $tmp = Read-Host "Enter the email address for new contact"
            $count = (Get-AzSecurityContact).Count
            New-AzPolicyAssignment -name "SLZ-securityContact3" -PolicyDefinition $policyDefinition -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" -AssignIdentity -Location "westeurope" -contactEmail $tmp -contactName "default$($count+1)" | Out-Null
            $param = Read-Host "Successfully added security contact. Add another (y/n) ?"
    }

    Remove-item -Path $HOME/rule.json
    Remove-item -Path $HOME/parameters.json
}
Export-ModuleMember -Function setup-SubscriptionContacts