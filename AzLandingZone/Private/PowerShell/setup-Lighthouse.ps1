Function setup-Lighthouse {
    param(
            [ValidateSet("DIGIT", "CERTEU", "None", "")][string] $SOC,
            [string]$managementGroup = "lz-management-group"
    )

    $name = "lzslz"
    #$delegatedResourceManagementURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Ftemplates%2FdelegatedResourceManagement.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    #$delegatedResourceManagementparametersURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Ftemplates%2FdelegatedResourceManagement.parameters.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionManagedServices = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/lighthouse/definition-managedServices.json"

    #
    # Following values have been hard-coded in the parameters file:
    # Security Reader (read access to the security center) and Log analytics reader (Read access to Azure Log Analytics workspace and all logs) to DIGIT-S1
    # Security Reader (read access to the security center) and Log analytics reader (Read access to Azure Log Analytics workspace and all logs) to DIGIT-S2
    #
    if($SOC -eq "DIGIT"){
        #if(!(Get-AzManagedServicesDefinition | Where-Object {$_.Properties.ManagedByTenantId -Like "3a8968a8-fbcf-4414-8b5c-77255f50f37b"})){
        #    Invoke-WebRequest -Uri $delegatedResourceManagementURI -OutFile $HOME/delegatedResourceManagement.json
        #    Invoke-WebRequest -Uri $delegatedResourceManagementparametersURI -OutFile $HOME/delegatedResourceManagement.parameters.json
        #    New-AzDeployment -Name LightHouse -Location "westeurope" -TemplateFile $HOME/delegatedResourceManagement.json -TemplateParameterFile $HOME/delegatedResourceManagement.parameters.json | Out-Null
        #    Remove-Item -Path $HOME/delegatedResourceManagement.parameters.json
        #    Remove-Item -Path $HOME/delegatedResourceManagement.json
        #    Write-Host "Delegation created for DIGIT S"
        #}
        if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Host "No Resource Group for Secure Landing Zone found"
            Write-Host "Please run setup script before running the policy script"
            return 1;
        }
        if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "*$name*"})){
                Write-Host "No Storage Account found for Secure Landing Zone"
                Write-Host "Please run setup script before running the policy script"
                return 1;
        }
        if(!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)){
                Write-Host "No Management group found for Secure Landing Zone"
                Write-Host "Please run setup script before running the policy script"
                return 1;
        }
        $location = $GetResourceGroup.Location
        $scope = ($GetManagementGroup).Id

        Write-Host "Checking policy for Azure Lighthouse" -ForegroundColor Yellow
        if(!(Get-AzPolicyAssignment -Scope $scope | where-Object {$_.Name -Like "SLZ-managedServices"})){
            Write-Host "Enabling Azure Lighthouse delegation for DIGIT.S"
            Invoke-WebRequest -Uri $definitionManagedServices -OutFile $HOME/rule.json
            $policyDefinition = New-AzPolicyDefinition -Name "SLZ-managedServices" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
            $policyAssignment = New-AzPolicyAssignment -name "SLZ-managedServices" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location
            Write-Host "Waiting for previous task to complete" -ForegroundColor Yellow
            Start-Sleep -Seconds 15
            New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
            Write-Host "Created role assignment for: "$policyAssignment.Name
            Remove-Item -Path $HOME/rule.json
        }
    }
}
Export-ModuleMember -Function setup-Lighthouse