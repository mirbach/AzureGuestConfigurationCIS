# WindowsFeature DSC Resource Template
# Module: PSDesiredStateConfiguration
# Resource: WindowsFeature
# Description: Manages Windows features and roles

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
        WindowsFeature 'ExampleFeature'
        {
            Name = 'FeatureName'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }
    }
}
