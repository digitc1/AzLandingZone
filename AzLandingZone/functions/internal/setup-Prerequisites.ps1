Function setup-Prerequisites {
    Write-Host "Checking registration for Microsoft Insights" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Insights').RegistrationState[0] -Like "Registered")){
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.Insights' | Out-Null
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Insights').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }

    Write-Host "Checking registration for Microsoft PolicyInsights" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights').RegistrationState[0] -Like "Registered")){
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }
    Write-Host "Checking registration for Microsoft Security" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Security').RegistrationState[0] -Like "Registered")){
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security'
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Security').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }
}
Export-ModuleMember -Function setup-Prerequisites