Function register-ResourceProvider {
    $items = @(
        'Microsoft.Insights',
        'Microsoft.PolicyInsights',
        'Microsoft.Security',
        'Microsoft.ManagedServices',
        'Microsoft.OperationsManagement'
    )
    
    $items | ForEach-Object -parallel {
        Write-Host "Checking registration for $_" -ForegroundColor Yellow
        if((Get-AzResourceProvider -ProviderNamespace $_).RegistrationState[0] -Like "Registered"){
            Write-Verbose "$_ already registered"
        } else {
            Write-Verbose "Registering $_ resource providers. This may take few minutes"
            Register-AzResourceProvider -ProviderNamespace $_ | Out-Null
            do {
                Start-Sleep -s 10
            } until (!((Get-AzResourceProvider -ProviderNamespace $_).RegistrationState[0] -Like "Registered"))
        }
    }
}
Export-ModuleMember -Function register-ResourceProvider
