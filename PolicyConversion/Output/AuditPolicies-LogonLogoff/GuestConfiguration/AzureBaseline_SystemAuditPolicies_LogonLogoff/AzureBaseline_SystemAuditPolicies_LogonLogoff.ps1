Configuration AzureBaseline_SystemAuditPolicies_LogonLogoff
{
    param
    (
        [Parameter()]
        [string]$AuditGroupMembership = 'Success'
    )

    Import-DscResource -ModuleName @{ModuleName = 'AuditPolicyDsc'; RequiredVersion='1.4.0.0'}

    Node localhost
    {
        AuditPolicySubcategory 'Group Membership'
        {
            Name = 'GroupMembership'
            AuditFlag = $AuditGroupMembership
            Ensure = 'Present'            }
}
}
