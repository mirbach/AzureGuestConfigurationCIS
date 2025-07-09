Configuration AzureBaseline_SystemAuditPoliciesObjectAccess
{
    param
    (
        [Parameter()]
        [string]$AuditDetailedFileShare = 'No Auditing',

        [Parameter()]
        [string]$AuditFileShare = 'No Auditing',

        [Parameter()]
        [string]$AuditFileSystem = 'No Auditing'
    )

    Import-DscResource -ModuleName 'AuditPolicyDsc' -ModuleVersion '1.4.0.0'

    Node localhost
    {
        AuditPolicySubcategory 'Audit Detailed File Share'
        {
            Name = 'Detailed File Share'
            AuditFlag = $AuditDetailedFileShare
            Ensure = 'Present'
        }

        AuditPolicySubcategory 'Audit File Share'
        {
            Name = 'File Share'
            AuditFlag = $AuditFileShare
            Ensure = 'Present'
        }

        AuditPolicySubcategory 'Audit File System'
        {
            Name = 'File System'
            AuditFlag = $AuditFileSystem
            Ensure = 'Present'
        }
    }
}
