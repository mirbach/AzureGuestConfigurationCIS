Configuration AzureBaseline_SecurityOptions_Recoveryconsole
{
    param
    (
        [Parameter()]
        [string]$RecoveryConsoleAllowFloppyCopyAndAccessToAllDrivesAndAllFolders = 'Disabled'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'RecoveryConsoleAllowFloppyCopyAndAccessToAllDrivesAndAllFolders'
        {
            Name = 'RecoveryConsoleAllowFloppyCopyAndAccessToAllDrivesAndAllFolders'
            Recovery_console_Allow_floppy_copy_and_access_to_all_drives_and_folders = $RecoveryConsoleAllowFloppyCopyAndAccessToAllDrivesAndAllFolders            }
}
}
