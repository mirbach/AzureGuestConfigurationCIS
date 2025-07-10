# User DSC Resource Template
# Module: PSDesiredStateConfiguration
# Resource: User
# Description: Manages local Windows user accounts

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
        User 'ExampleUser'
        {
            UserName = 'Username'
            Disabled = $true
            Ensure = 'Present'
        }
    }
}
