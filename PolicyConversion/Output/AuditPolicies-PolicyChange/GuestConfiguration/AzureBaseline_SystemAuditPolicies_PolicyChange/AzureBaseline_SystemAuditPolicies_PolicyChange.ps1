Configuration AzureBaseline_SystemAuditPolicies_PolicyChange
{
    param
    (
        [Parameter()]
        [string]$AuditAuthenticationPolicyChange = 'Success',

        [Parameter()]
        [string]$AuditAuthorizationPolicyChange = 'Success'
    )

    Import-DscResource -ModuleName @{ModuleName = 'AuditPolicyDsc'; RequiredVersion='1.4.0.0'}

    Node localhost
    {
        AuditPolicySubcategory 'Authentication Policy Change'
        {
            Name = 'AuthenticationPolicyChange'
            AuditFlag = $AuditAuthenticationPolicyChange
            Ensure = 'Present'
        }
        AuditPolicySubcategory 'Authorization Policy Change'
        {
            Name = 'AuthorizationPolicyChange'
            AuditFlag = $AuditAuthorizationPolicyChange
            Ensure = 'Present'
        }
    }
}

