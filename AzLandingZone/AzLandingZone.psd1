#
# Manifeste de module pour le module « AzLandingZone »
#
# Généré par : Augustin Colle
#
# Généré le : 05-05-20
#

@{

    # Module de script ou fichier de module binaire associé à ce manifeste
    RootModule = './AzLandingZone.psm1'
    
    # Numéro de version de ce module.
    ModuleVersion = '<ModuleVersion>'
    
    # Éditions PS prises en charge
    # CompatiblePSEditions = @()
    
    # ID utilisé pour identifier de manière unique ce module
    GUID = 'd57ee1e9-fbec-4941-9e11-0b79bf323495'
    
    # Auteur de ce module
    Author = 'Augustin Colle'
    
    # Société ou fournisseur de ce module
    CompanyName = 'Inconnu'
    
    # Déclaration de copyright pour ce module
    Copyright = '(c) 2020 Augustin Colle. Tous droits réservés.'
    
    # Description de la fonctionnalité fournie par ce module
    # Description = ''
    
    # Version minimale du moteur Windows PowerShell requise par ce module
    # PowerShellVersion = ''
    
    # Nom de l'hôte Windows PowerShell requis par ce module
    # PowerShellHostName = ''
    
    # Version minimale de l'hôte Windows PowerShell requise par ce module
    # PowerShellHostVersion = ''
    
    # Version minimale du Microsoft .NET Framework requise par ce module. Cette configuration requise est valide uniquement pour PowerShell Desktop Edition.
    # DotNetFrameworkVersion = ''
    
    # Version minimale de l’environnement CLR (Common Language Runtime) requise par ce module. Cette configuration requise est valide uniquement pour PowerShell Desktop Edition.
    # CLRVersion = ''
    
    # Architecture de processeur (None, X86, Amd64) requise par ce module
    # ProcessorArchitecture = ''
    
    # Modules qui doivent être importés dans l'environnement global préalablement à l'importation de ce module
    RequiredModules = @()
    
    # Assemblys qui doivent être chargés préalablement à l'importation de ce module
    # RequiredAssemblies = @()
    
    # Fichiers de script (.ps1) exécutés dans l’environnement de l’appelant préalablement à l’importation de ce module
    # ScriptsToProcess = @()
    
    # Fichiers de types (.ps1xml) à charger lors de l'importation de ce module
    # TypesToProcess = @()
    
    # Fichiers de format (.ps1xml) à charger lors de l'importation de ce module
    # FormatsToProcess = @()
    
    # Modules à importer en tant que modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @(
            '.\Public\Get-AzLandingZone.ps1',
            '.\Public\New-AzLandingZone.ps1',
            '.\Public\Register-AzLandingZone.ps1',
            '.\Public\Remove-AzLandingZone.ps1',
            '.\Public\Sync-AzLandingZone.ps1',
            '.\Public\Test-AzLandingZone.ps1',
            '.\Public\Update-AzLandingZone.ps1',
            '.\Private\setup-Automation.ps1',
            '.\Private\setup-Lighthouse.ps1',
            '.\Private\setup-LogPipeline.ps1',
            '.\Private\setup-Policy.ps1',
            '.\Private\setup-Prerequisites.ps1',
            '.\Private\setup-Resources.ps1',
            '.\Private\setup-RunAs.ps1',
            '.\Private\setup-Storage.ps1',
            '.\Private\setup-Subscription.ps1',
            '.\Private\setup-SubscriptionContacts.ps1',
            '.\Private\rest-api\Get-AzAccessToken.ps1',
            '.\Private\rest-api\Set-LzSentinel.ps1',
            '.\Private\rest-api\activeDirectory\Connect-LzActiveDirectory.ps1',
            '.\Private\rest-api\activeDirectory\Set-LzActiveDirectoryAlertRule.ps1',
            '.\Private\rest-api\activeDirectory\Set-LzActiveDirectoryDiagnosticSettings.ps1',
            '.\Private\rest-api\securityCenter\Connect-LzSecurityCenter.ps1',
            '.\Private\rest-api\securityCenter\Set-LzSecurityCenterAlertRule.ps1',
            '.\Private\rest-api\securityCenter\Set-LzSecurityCenterAutoProvisioningSettings.ps1',
            '.\Private\rest-api\securityCenter\Set-LzSecurityCenterPricing.ps1',
            '.\Private\rest-api\subscriptions\Set-LzSubscriptionDiagnosticSettings.ps1'
        )
    
    # Fonctions à exporter à partir de ce module. Pour de meilleures performances, n’utilisez pas de caractères génériques et ne supprimez pas l’entrée. Utilisez un tableau vide si vous n’avez aucune fonction à exporter.
    FunctionsToExport = @(
            'New-AzLandingZone',
            'Get-AzLandingZone',
            'Register-AzLandingZone',
            'Remove-AzLandingZone',
            'Sync-AzLandingZone',
            'Update-AzLandingZone',
            'Test-AzLandingZone'
        )
    
    # Applets de commande à exporter à partir de ce module. Pour de meilleures performances, n’utilisez pas de caractères génériques et ne supprimez pas l’entrée. Utilisez un tableau vide si vous n’avez aucune applet de commande à exporter.
    CmdletsToExport = @()
    
    # Variables à exporter à partir de ce module
    VariablesToExport = '*'
    
    # Alias à exporter à partir de ce module. Pour de meilleures performances, n’utilisez pas de caractères génériques et ne supprimez pas l’entrée. Utilisez un tableau vide si vous n’avez aucun alias à exporter.
    AliasesToExport = @()
    
    # Ressources DSC à exporter depuis ce module
    # DscResourcesToExport = @()
    
    # Liste de tous les modules empaquetés avec ce module
    # ModuleList = @()
    
    # Liste de tous les fichiers empaquetés avec ce module
    # FileList = @()
    
    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess. Cela peut également inclure une table de hachage PSData avec des métadonnées de modules supplémentaires utilisées par PowerShell.
    PrivateData = @{
    
        PSData = @{
    
            # Des balises ont été appliquées à ce module. Elles facilitent la découverte des modules dans les galeries en ligne.
            # Tags = @()
    
            # URL vers la licence de ce module.
            # LicenseUri = ''
    
            # URL vers le site web principal de ce projet.
            # ProjectUri = ''
    
            # URL vers une icône représentant ce module.
            # IconUri = ''
    
            # Propriété ReleaseNotes de ce module
            # ReleaseNotes = ''
    
        } # Fin de la table de hachage PSData
    
    } # Fin de la table de hachage PrivateData
    
    # URI HelpInfo de ce module
    # HelpInfoURI = ''
    
    # Le préfixe par défaut des commandes a été exporté à partir de ce module. Remplacez le préfixe par défaut à l’aide d’Import-Module -Prefix.
    # DefaultCommandPrefix = ''
    
    }