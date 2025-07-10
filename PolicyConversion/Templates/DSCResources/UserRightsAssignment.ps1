# UserRightsAssignment DSC Resource Template
# Module: SecurityPolicyDsc
# Resource: UserRightsAssignment
# Description: Manages Windows user rights assignments

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
        UserRightsAssignment 'ExampleUserRight'
        {
            Policy = 'Log_on_as_a_service'
            Identity = 'NT SERVICE\LocalSystem'
            Ensure = 'Present'
        }
    }
}
