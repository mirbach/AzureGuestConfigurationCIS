Configuration AzureBaseline_SecurityOptions_Shutdown
{
    param
    (
        [Parameter()]
        [string]$ShutdownAllowSystemToBeShutDownWithoutHavingToLogOn = 'Disabled',

        [Parameter()]
        [string]$ShutdownClearVirtualMemoryPagefile = 'Disabled'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'ShutdownAllowSystemToBeShutDownWithoutHavingToLogOn'
        {
            Name = 'ShutdownAllowSystemToBeShutDownWithoutHavingToLogOn'
            Shutdown_Allow_system_to_be_shut_down_without_having_to_log_on = $ShutdownAllowSystemToBeShutDownWithoutHavingToLogOn
        }
        SecurityOption 'ShutdownClearVirtualMemoryPagefile'
        {
            Name = 'ShutdownClearVirtualMemoryPagefile'
            Shutdown_Clear_virtual_memory_pagefile = $ShutdownClearVirtualMemoryPagefile
}}
}
