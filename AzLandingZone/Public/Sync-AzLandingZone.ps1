Function Sync-AzLandingZone{
    <#
        .SYNOPSIS
        Sync all Landing Zone policies and apply remediation
        .DESCRIPTION
        Sync all Landing Zone policies and apply remediation
        .PARAMETER managementGroup
        Enter the name for AzLandingZone management group. If the management group already exist, it is reused for AzLandingZone.
        .EXAMPLE
        Sync-AzLandingZone
    #>
    Param(
        [string] $managementGroup = "lz-management-group"
    )

    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)){
        Write-Host "No management group found. Make sure the Landing Zone is installed."
    }

    Get-AzPolicyState -ManagementGroupName $GetManagementGroup.Name | 
        where-Object {$_.PolicyAssignmentName -Like "SLZ-policyGroup*"} | 
        ForEach-Object {
            Write-Host "Creating remediation for "$_.PolicyDefinitionName
            Start-AzPolicyRemediation -Name $_.PolicyDefinitionName -PolicyAssignmentId $_.PolicyAssignmentId -PolicyDefinitionReferenceId $_.PolicyDefinitionReferenceId | Out-Null
    }
    Get-AzPolicyState -ManagementGroupName $GetManagementGroup.Name | 
        where-Object {$_.PolicyAssignmentName -like "SLZ-*"} | 
        where-Object {$_.PolicyAssignmentName -notlike "SLZ-policyGroup*"} | 
        where-Object {$_.ComplianceState -Like "NonCompliant"} | 
        ForEach-Object {
            Write-Host "Creating remediation for "$_.PolicyAssignmentName
            Start-AzPolicyRemediation -Name $_.PolicyAssignmentName -PolicyAssignmentId $_.PolicyAssignmentId | Out-Null
    }
}
Export-ModuleMember -Function Sync-AzLandingZone