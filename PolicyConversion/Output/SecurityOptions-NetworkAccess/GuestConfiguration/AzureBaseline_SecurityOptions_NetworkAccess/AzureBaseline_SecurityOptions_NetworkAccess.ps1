Configuration AzureBaseline_SecurityOptions_NetworkAccess
{
    param
    (
        [Parameter()]
        [string]$NetworkAccessRemotelyAccessibleRegistryPaths = 'System\CurrentControlSet\Control\ProductOptions|#|System\CurrentControlSet\Control\Server Applications|#|Software\Microsoft\Windows NT\CurrentVersion',

        [Parameter()]
        [string]$NetworkAccessRemotelyAccessibleRegistryPathsAndSubpaths = 'System\CurrentControlSet\Control\Print\Printers|#|System\CurrentControlSet\Services\Eventlog|#|Software\Microsoft\OLAP Server|#|Software\Microsoft\Windows NT\CurrentVersion\Print|#|Software\Microsoft\Windows NT\CurrentVersion\Windows|#|System\CurrentControlSet\Control\ContentIndex|#|System\CurrentControlSet\Control\Terminal Server|#|System\CurrentControlSet\Control\Terminal Server\UserConfig|#|System\CurrentControlSet\Control\Terminal Server\DefaultUserConfiguration|#|Software\Microsoft\Windows NT\CurrentVersion\Perflib|#|System\CurrentControlSet\Services\SysmonLog',

        [Parameter()]
        [string]$NetworkAccessSharesThatCanBeAccessedAnonymously = 'Disabled'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'NetworkAccessRemotelyAccessibleRegistryPaths'
        {
            Name = 'NetworkAccessRemotelyAccessibleRegistryPaths'
            Network_access_Remotely_accessible_registry_paths = $NetworkAccessRemotelyAccessibleRegistryPaths
        }
        SecurityOption 'NetworkAccessRemotelyAccessibleRegistryPathsAndSubpaths'
        {
            Name = 'NetworkAccessRemotelyAccessibleRegistryPathsAndSubpaths'
            Network_access_Remotely_accessible_registry_paths = $NetworkAccessRemotelyAccessibleRegistryPathsAndSubpaths
        }
        SecurityOption 'NetworkAccessSharesThatCanBeAccessedAnonymously'
        {
            Name = 'NetworkAccessSharesThatCanBeAccessedAnonymously'
            Network_access_Shares_that_can_be_accessed_anonymously = $NetworkAccessSharesThatCanBeAccessedAnonymously
}}
}
