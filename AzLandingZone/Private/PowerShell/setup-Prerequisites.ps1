Function register-ResourceProvider {
    Write-Host "Checking registration for Microsoft Insights" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Insights').RegistrationState[0] -Like "Registered")){
        Write-Host "Registering Microsoft.Insights resource providers. This may take few minutes"
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.Insights' | Out-Null
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Insights').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }

    Write-Host "Checking registration for Microsoft PolicyInsights" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights').RegistrationState[0] -Like "Registered")){
        Write-Host "Registering Microsoft.PolicyInsights resource providers. This may take few minutes"
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights' | Out-Null
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }
    Write-Host "Checking registration for Microsoft Security" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Security').RegistrationState[0] -Like "Registered")){
        Write-Host "Registering Microsoft.Security resource providers. This may take few minutes"
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security' | Out-Null
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.Security').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }
    Write-Host "Checking registration for Microsoft Managed Services" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.ManagedServices').RegistrationState[0] -Like "Registered")){
        Write-Host "Registering Microsoft.ManagedServices resource providers. This may take few minutes"
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.ManagedServices' | Out-Null
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.ManagedServices').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }
    Write-Host "Checking registration for Microsoft Operation Management" -ForegroundColor Yellow
    if(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.OperationsManagement').RegistrationState[0] -Like "Registered")){
        Write-Host "Registering Microsoft.OperationsManagement resource providers. This may take few minutes"
        Register-AzResourceProvider -ProviderNamespace 'Microsoft.OperationsManagement' | Out-Null
        while(!((Get-AzResourceProvider -ProviderNamespace 'Microsoft.OperationsManagement').RegistrationState[0] -Like "Registered")){
            Start-Sleep -s 10
        }
    }
}
Export-ModuleMember -Function register-ResourceProvider