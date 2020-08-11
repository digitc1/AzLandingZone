# Register-AzLandingZone

## SYNOPSIS
Register a subscription in Azure Landing Zone management groups (policies and log collection apply)

## SYNTAX
```
Register-AzLandingZone [-Subscription <String>]
```

## DESCRIPTION

## EXAMPLES

### EXAMPLE 1
```
Register-AzLandingZone -Subscrition "<subscription-name>"
```
Register the subscription <subscription-name> in Azure Landing Zone

### EXAMPLE 2
```
Register-AzLandingZone -Subscrition "<subscription-id>" -SOC "DIGIT"
```
Register the subscription <subscription-id> in Azure Landing Zone and enable lighthouse for DIGIT.S access

## PARAMETERS

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
Parameter Sets: DIGIT, CERTEU, none
Aliases:

Required: True
Position: Named
Default value: 
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS