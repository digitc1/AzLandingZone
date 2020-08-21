# New-AzLandingZone

## SYNOPSIS
Installs all the components of the Landing Zone

## SYNTAX
```
New-AzLandingZone [-autoupdate <bool>] [-SOC <string>] [-location <string>] [-enableSentinel <bool>] [-enableEventHub <bool>] [-retentionPeriod <int>] [-securityContacts <string[]>]
```

## DESCRIPTION

## EXAMPLES

### EXAMPLE 1
```
New-AzLandingZone
```
Install the default components of the Landing Zone with default values.

### EXAMPLE 2
```
New-AzLandingZone -SOC "DIGIT" -autoupdate $true -location "northeurope"
```
Install the default components of the Landing Zone + log analytics workspace and Azure sentinel in region North Europe. Enables auto-update and connectivity for DIGIT-CLOUDSEC team.

### EXAMPLE 3
```
New-AzLandingZone -EnableSentinel $true -retentionPeriod 365
```
Install the default components of the Landing Zone + log analytics workspace and Azure sentinel. Retention policy for legal hold is set to 365 days (storage account only).

### EXAMPLE 4
```
New-AzLandingZone -EnableEventHub $true -securityContacts "alice@domain.com,bob@domain.com"
```
Install the default components of the Landing Zone + event hub namespace with a specific event hub and key. The users "alice@domain.com" and "bob@domain.com" are used for security notifications.

## PARAMETERS

### -autoUpdate
Switch to enable auto-update. If no value is provided then default to $false.

```yaml
Type: bool
Parameter Sets: $true, $false
Aliases:

Required: False
Position: Named
Default value: $false
Accept pipeline input: False
Accept wildcard characters: False
```

### -SOC
Enter the name of the SOC to connect to. If no value is provided then default to none.

```yaml
Type: bool
Parameter Sets: DIGIT, CERTEU, none
Aliases:

Required: False
Position: Named
Default value: none
Accept pipeline input: False
Accept wildcard characters: False
```

### -location
Enter a location to install the Landing Zone. If no value is provided then default to West Europe.

```yaml
Type: String
Parameter Sets: northeurope, westeurope
Aliases:

Required: False
Position: Named
Default value: none
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableSentinel
Switch to enable installation of Azure Sentinel. If no value is provided then default to $false. This parameter is overwritten to $true if using parameter "-SOC DIGIT".

```yaml
Type: bool
Parameter Sets: $true, $false
Aliases:

Required: False
Position: Named
Default value: $false
Accept pipeline input: False
Accept wildcard characters: False
```

### -enableEventHub
Switch to enable installation of event hub namespace. If no value is provided then default to $false. This parameter is overwritten to $true if using parameter "-SOC CERTEU".

```yaml
Type: bool
Parameter Sets: $true, $false
Aliases:

Required: False
Position: Named
Default value: $false
Accept pipeline input: False
Accept wildcard characters: False
```

### -retentionPeriod
Enter the number of days to retain the logs in legal hold. If not value is provided then default to 185 days (6 months). This parameters cannot be less than 185 days.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 185
Accept pipeline input: False
Accept wildcard characters: False
```

### -securityContacts
Enter a coma-separated list of users to notify in case of security alerts.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS