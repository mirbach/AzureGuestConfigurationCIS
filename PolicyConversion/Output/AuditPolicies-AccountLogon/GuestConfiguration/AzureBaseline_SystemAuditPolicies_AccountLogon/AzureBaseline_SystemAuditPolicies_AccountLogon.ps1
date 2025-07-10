Configuration AzureBaseline_SystemAuditPolicies_AccountLogon
{
    param
    (
        [Parameter()]
        [string]$AuditCredentialValidation = 'Success'
    )

    Import-DscResource -ModuleName @{ModuleName = 'AuditPolicyDsc'; RequiredVersion='1.4.0.0'}

    Node localhost
    {
        AuditPolicySubcategory 'Credential Validation'
        {
            Name = 'CredentialValidation'
            AuditFlag = $AuditCredentialValidation
            Ensure = 'Present'
        }
    }
}
