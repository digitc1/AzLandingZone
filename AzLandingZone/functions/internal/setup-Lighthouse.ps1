Function setup-Lighthouse {
    param(
            [ValidateSet("DIGIT", "CERTEU", "None", "")]
            [string] $SOC
    )

    $delegatedResourceManagementURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Ftemplates%2FdelegatedResourceManagement.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $delegatedResourceManagementparametersURI = "https://dev.azure.com/devops0837/6414d3a7-f802-4703-8cd7-9cef7c9a9617/_apis/git/repositories/0707bade-f83f-4a91-bbb6-9a13502def90/items?path=%2FLandingZone%2Ftemplates%2FdelegatedResourceManagement.parameters.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"

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
Export-ModuleMember -Function setup-Lighthouse