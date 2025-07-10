Configuration AzureBaseline_WindowsFirewallProperties
{
    param
    (
        [Parameter()]
        [string]$WindowsFirewallDomainUseProfileSettings = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallDomainBehaviorForOutboundConnections = 'Disabled',

        [Parameter()]
        [string]$WindowsFirewallDomainApplyLocalConnectionSecurityRules = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallDomainApplyLocalFirewallRules = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallDomainDisplayNotifications = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPrivateUseProfileSettings = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPrivateBehaviorForOutboundConnections = 'Disabled',

        [Parameter()]
        [string]$WindowsFirewallPrivateApplyLocalConnectionSecurityRules = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPrivateApplyLocalFirewallRules = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPrivateDisplayNotifications = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPublicUseProfileSettings = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPublicBehaviorForOutboundConnections = 'Disabled',

        [Parameter()]
        [string]$WindowsFirewallPublicApplyLocalConnectionSecurityRules = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPublicApplyLocalFirewallRules = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallPublicDisplayNotifications = 'Require Signing',

        [Parameter()]
        [string]$WindowsFirewallDomainAllowUnicastResponse = 'Disabled',

        [Parameter()]
        [string]$WindowsFirewallPrivateAllowUnicastResponse = 'Disabled',

        [Parameter()]
        [string]$WindowsFirewallPublicAllowUnicastResponse = 'Require Signing'
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Registry 'WindowsFirewallDomainUseProfileSettings'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallDomainUseProfileSettings'
            ValueData = $WindowsFirewallDomainUseProfileSettings
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallDomainBehaviorForOutboundConnections'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallDomainBehaviorForOutboundConnections'
            ValueData = $WindowsFirewallDomainBehaviorForOutboundConnections
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallDomainApplyLocalConnectionSecurityRules'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallDomainApplyLocalConnectionSecurityRules'
            ValueData = $WindowsFirewallDomainApplyLocalConnectionSecurityRules
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallDomainApplyLocalFirewallRules'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallDomainApplyLocalFirewallRules'
            ValueData = $WindowsFirewallDomainApplyLocalFirewallRules
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallDomainDisplayNotifications'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallDomainDisplayNotifications'
            ValueData = $WindowsFirewallDomainDisplayNotifications
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPrivateUseProfileSettings'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPrivateUseProfileSettings'
            ValueData = $WindowsFirewallPrivateUseProfileSettings
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPrivateBehaviorForOutboundConnections'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPrivateBehaviorForOutboundConnections'
            ValueData = $WindowsFirewallPrivateBehaviorForOutboundConnections
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPrivateApplyLocalConnectionSecurityRules'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPrivateApplyLocalConnectionSecurityRules'
            ValueData = $WindowsFirewallPrivateApplyLocalConnectionSecurityRules
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPrivateApplyLocalFirewallRules'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPrivateApplyLocalFirewallRules'
            ValueData = $WindowsFirewallPrivateApplyLocalFirewallRules
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPrivateDisplayNotifications'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPrivateDisplayNotifications'
            ValueData = $WindowsFirewallPrivateDisplayNotifications
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPublicUseProfileSettings'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPublicUseProfileSettings'
            ValueData = $WindowsFirewallPublicUseProfileSettings
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPublicBehaviorForOutboundConnections'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPublicBehaviorForOutboundConnections'
            ValueData = $WindowsFirewallPublicBehaviorForOutboundConnections
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPublicApplyLocalConnectionSecurityRules'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPublicApplyLocalConnectionSecurityRules'
            ValueData = $WindowsFirewallPublicApplyLocalConnectionSecurityRules
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPublicApplyLocalFirewallRules'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPublicApplyLocalFirewallRules'
            ValueData = $WindowsFirewallPublicApplyLocalFirewallRules
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPublicDisplayNotifications'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPublicDisplayNotifications'
            ValueData = $WindowsFirewallPublicDisplayNotifications
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallDomainAllowUnicastResponse'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallDomainAllowUnicastResponse'
            ValueData = $WindowsFirewallDomainAllowUnicastResponse
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPrivateAllowUnicastResponse'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPrivateAllowUnicastResponse'
            ValueData = $WindowsFirewallPrivateAllowUnicastResponse
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'WindowsFirewallPublicAllowUnicastResponse'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'WindowsFirewallPublicAllowUnicastResponse'
            ValueData = $WindowsFirewallPublicAllowUnicastResponse
            ValueType = 'String'
            Ensure = 'Present'
}}
}

