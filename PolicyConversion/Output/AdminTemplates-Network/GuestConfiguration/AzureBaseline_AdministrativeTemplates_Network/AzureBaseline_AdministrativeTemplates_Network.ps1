Configuration AzureBaseline_AdministrativeTemplates_Network
{
    param
    (
        [Parameter()]
        [string]$EnableInsecureGuestLogons = 'Disabled',

        [Parameter()]
        [string]$AllowSimultaneousConnectionsToTheInternetOrAWindowsDomain = 'Require Signing',

        [Parameter()]
        [string]$TurnOffMulticastNameResolution = 'Require Signing'
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Registry 'EnableInsecureGuestLogons'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'EnableInsecureGuestLogons'
            ValueData = $EnableInsecureGuestLogons
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AllowSimultaneousConnectionsToTheInternetOrAWindowsDomain'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AllowSimultaneousConnectionsToTheInternetOrAWindowsDomain'
            ValueData = $AllowSimultaneousConnectionsToTheInternetOrAWindowsDomain
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'TurnOffMulticastNameResolution'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'TurnOffMulticastNameResolution'
            ValueData = $TurnOffMulticastNameResolution
            ValueType = 'String'
            Ensure = 'Present'
}}
}

