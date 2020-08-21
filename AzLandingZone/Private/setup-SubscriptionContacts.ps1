Function setup-SubscriptionContacts {
    param(
        [ValidateSet("DIGIT", "CERTEU", "None", "")]
        [string] $SOC,
        [String[]]$securityContacts
    )
    $version = 1

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

    #
    # Checking definition
    #
    if($policyDefinition = Get-AzPolicyDefinition -ManagementGroupName "lz-management-group" | Where-Object {$_.Name -Like "SLZ-securityContact"}){
        if(!($policyDefinition.Properties.metadata.version -eq $version)){
            Invoke-WebRequest -Uri $definitionSecurityCenterContactURI -OutFile $HOME/rule.json
            Invoke-WebRequest -Uri $securityCenterContactParametersURI -OutFile $HOME/parameters.json
            $metadata = '{"version":"' + $version + '"}'
            $policyDefinition = Set-AzPolicyDefinition -Id $policyDefinition.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
            Remove-Item -Path $HOME/rule.json
            Remove-Item -Path $HOME/parameters.json
        }
    }
    else{
        Invoke-WebRequest -Uri $definitionSecurityCenterContactURI -OutFile $HOME/rule.json
        Invoke-WebRequest -Uri $securityCenterContactParametersURI -OutFile $HOME/parameters.json
        $metadata = '{"version":"' + $version + '"}'
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-securityContact" -Policy $HOME/rule.json -Parameter $HOME/parameters.json -ManagementGroupName "lz-management-group" -Metadata $metadata
        Remove-Item -Path $HOME/rule.json
        Remove-Item -Path $HOME/parameters.json
    }

    #
    # Checking assignment
    #
    $params = "DIGIT-CLOUD-VIRTUAL-TASK-FORCE@ec.europa.eu"
    if($SOC -eq "DIGIT"){
        $params += ";EC-DIGIT-CSIRC@ec.europa.eu;EC-DIGIT-CLOUDSEC@ec.europa.eu"
    }
    foreach ($contact in $securityContacts.Split(','))  
    { 
        $params += ";$contact"
    }
    if($policyAssignment = Get-AzPolicyAssignment -Scope "/providers/Microsoft.Management/managementGroups/lz-management-group" | Where-Object {$_.Properties.PolicyDefinitionId -eq $def.ResourceId}) {
        Set-AzPolicyAssignment -Id $policyAssignment.ResourceId -PolicyParametersObject $params | Out-Null
    }
    else {
        New-AzPolicyAssignment  -name "SLZ-securityContact" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location "westeurope" -contactEmail $params -contactName "default" | Out-Null
    }
}
Export-ModuleMember -Function setup-SubscriptionContacts