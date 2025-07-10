Configuration AzureBaseline_SystemAuditPolicies_System
{
    param
    (
        [Parameter()]
        [string]$AuditOtherSystemEvents = 'Success'
    )

    Import-DscResource -ModuleName @{ModuleName = 'AuditPolicyDsc'; RequiredVersion='1.4.0.0'}

    Node localhost
    {
        AuditPolicySubcategory 'Other System Events'
        {
            Name = 'OtherSystemEvents'
            AuditFlag = $AuditOtherSystemEvents
            Ensure = 'Present'
        }
    }
}
