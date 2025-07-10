Configuration AzureBaseline_SystemAuditPolicies_DetailedTracking
{
    param
    (
        [Parameter()]
        [string]$AuditProcessTermination = 'Success'
    )

    Import-DscResource -ModuleName @{ModuleName = 'AuditPolicyDsc'; RequiredVersion='1.4.0.0'}

    Node localhost
    {
        AuditPolicySubcategory 'Process Termination'
        {
            Name = 'ProcessTermination'
            AuditFlag = $AuditProcessTermination
            Ensure = 'Present'
        }
    }
}
