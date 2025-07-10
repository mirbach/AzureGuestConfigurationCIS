Configuration AzureBaseline_SecurityOptions_Devices
{
    param
    (
        [Parameter()]
        [string]$DevicesAllowedToFormatAndEjectRemovableMedia = 'Administrators'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'DevicesAllowedToFormatAndEjectRemovableMedia'
        {
            Name = 'DevicesAllowedToFormatAndEjectRemovableMedia'
            Devices_Allowed_to_format_and_eject_removable_media = $DevicesAllowedToFormatAndEjectRemovableMedia
        }
    }
}
