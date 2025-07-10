# Service DSC Resource Template
# Module: PSDesiredStateConfiguration
# Resource: Service
# Description: Manages Windows services

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
        Service 'ExampleService'
        {
            Name = 'ServiceName'
            State = 'Running'
            StartupType = 'Automatic'
            Ensure = 'Present'
        }
    }
}
