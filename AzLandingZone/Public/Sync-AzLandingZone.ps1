Function Sync-AzLandingZone{
    Get-AzPolicyState -ManagementGroupName "lz-management-group" | where-Object {$_.PolicyAssignmentName -Like "SLZ-policyGroup*"} | ForEach-Object {
        Write-Host "Creating remediation for "$_.PolicyDefinitionName
        Start-AzPolicyRemediation -Name $_.PolicyDefinitionName -PolicyAssignmentId $_.PolicyAssignmentId -PolicyDefinitionReferenceId $_.PolicyDefinitionReferenceId | Out-Null
    }
    Get-AzPolicyState -ManagementGroupName "lz-management-group" | where-Object {$_.PolicyAssignmentName -like "SLZ-*"} | where-Object {$_.PolicyAssignmentName -notlike "SLZ-policyGroup*"} | where-Object {$_.ComplianceState -Like "NonCompliant"} | ForEach-Object {
        Write-Host "Creating remediation for "$_.PolicyAssignmentName
        Start-AzPolicyRemediation -Name $_.PolicyAssignmentName -PolicyAssignmentId $_.PolicyAssignmentId
    }
}
Export-ModuleMember -Function Sync-AzLandingZone