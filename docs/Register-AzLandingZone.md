# Register-AzLandingZone

## SYNOPSIS
Register a subscription in Azure Landing Zone management groups (policies and log collection apply)

## SYNTAX
```
Register-AzLandingZone [-managementGroup <String>] [-Subscription <String>] [-SOC <String>] [-securityContacts <String[]>]
```

## DESCRIPTION

## EXAMPLES

### EXAMPLE 1
```
Register-AzLandingZone -Subscrition "<subscription-name>" -managementGroup "<group-name>"
```
Register the subscription <subscription-name> in Azure Landing Zone in management group <group-name>

### EXAMPLE 2
```
Register-AzLandingZone -Subscrition "<subscription-id>" -SOC "DIGIT" -securityContacts "alice@domain.com,bob@domain.com"
```
Register the subscription <subscription-id> in Azure Landing Zone, enable lighthouse for DIGIT.S access and register alice and bob as security contacts

## PARAMETERS

### -managementGroup
Enter the name for AzLandingZone management group. If the management group already exist, it is reused for AzLandingZone.

```yaml
Type: string
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: lz-management-group
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subscription
Enter the name or id of the subscription to register

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

### -SOC
Enter SOC value for additional features (lighthouse, Sentinel multi-workspace, ...)

```yaml
Type: String
Parameter Sets: DIGIT, CERTEU, None
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -securityContacts
Enter comma separated list of email addresses

```yaml
Type: String
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