# SecurityPolicy DSC Resource Template
# Module: SecurityPolicyDsc
# Resource: SecurityOption
# Description: Manages Windows security policy settings

Configuration {CONFIGURATION_NAME}
{
    param
    (
        # TODO: Add parameters based on policy requirements
        [Parameter()]
        [string]$ParameterValue = 'DefaultValue'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'ExampleSecuritySetting'
        {
            Name = 'Network_access_Do_not_allow_anonymous_enumeration_of_SAM_accounts'
            Value = 'Enabled'
        }
    }
}
