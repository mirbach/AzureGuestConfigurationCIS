Configuration AzureBaseline_SystemAuditPolicies_ObjectAccess
{
    param
    (
        [Parameter()]
        [string]$AuditDetailedFileShare = 'Failure',

        [Parameter()]
        [string]$AuditFileShare = 'Failure',

        [Parameter()]
        [string]$AuditFileSystem = 'Failure'
    )

    Import-DscResource -ModuleName 'AuditPolicyDsc'

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

