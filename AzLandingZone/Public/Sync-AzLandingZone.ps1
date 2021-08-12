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

    if(!(Get-AzManagementGroup -GroupName $managementGroup -Expand)){
        Write-Host "No management group found. Make sure the Landing Zone is installed."
    }

    $assignments = (Get-AzPolicyState | Where-Object {$_.PolicyAssignmentName -Like "SLZ-*" -And $_.ComplianceState -eq "NonCompliant" -And $_.PolicyDefinitionAction -eq "deployifnotexists"}) | Sort-Object -Unique -Property PolicyDefinitionReferenceId,PolicyDefinitionId
    foreach ($assignment in $assignments){
        "Running Remediation for $($assignment.PolicyDefinitionName)"
        if($assignment.policyDefinitionReferenceId){
            Start-AzPolicyRemediation -Name "myremediation_$($assignment.PolicyDefinitionName)" -PolicyAssignmentId $assignment.PolicyAssignmentId -PolicyDefinitionReferenceId $assignment.policyDefinitionReferenceId | Out-Null
        } else {
            Start-AzPolicyRemediation -Name "myremediation_$($assignment.PolicyDefinitionName)" -PolicyAssignmentId $assignment.PolicyAssignmentId | Out-Null
        }
    }
}
Export-ModuleMember -Function Sync-AzLandingZone
