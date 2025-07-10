# Group DSC Resource Template
# Module: PSDesiredStateConfiguration
# Resource: Group
# Description: Manages local Windows groups

Configuration {CONFIGURATION_NAME}
{
    param
    (
        # TODO: Add parameters based on policy requirements
        [Parameter()]
        [string]$ParameterValue = 'DefaultValue'
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost
    {
        Group 'ExampleGroup'
        {
            GroupName = 'Administrators'
            Members = $ParameterValue
            Ensure = 'Present'
        }
    }
}
