# Registry DSC Resource Template
# Module: PSDesiredStateConfiguration
# Resource: Registry
# Description: Manages Windows registry keys and values

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
        Registry 'ExampleSetting'
        {
            Key = 'HKEY_LOCAL_MACHINE\Software\Example'
            ValueName = 'SettingName'
            ValueData = $ParameterValue
            ValueType = 'String'
            Ensure = 'Present'
        }
    }
}
