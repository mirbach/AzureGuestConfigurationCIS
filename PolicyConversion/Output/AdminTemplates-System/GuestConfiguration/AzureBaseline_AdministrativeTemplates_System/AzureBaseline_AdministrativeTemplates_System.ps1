Configuration AzureBaseline_AdministrativeTemplates_System
{
    param
    (
        [Parameter()]
        [string]$AlwaysUseClassicLogon = 'Disabled',

        [Parameter()]
        [string]$BootStartDriverInitializationPolicy = '3',

        [Parameter()]
        [string]$EnableWindowsNTPClient = 'Require Signing',

        [Parameter()]
        [string]$TurnOnConveniencePINSignin = 'Disabled'
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Registry 'AlwaysUseClassicLogon'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AlwaysUseClassicLogon'
            ValueData = $AlwaysUseClassicLogon
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'BootStartDriverInitializationPolicy'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'BootStartDriverInitializationPolicy'
            ValueData = $BootStartDriverInitializationPolicy
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'EnableWindowsNTPClient'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'EnableWindowsNTPClient'
            ValueData = $EnableWindowsNTPClient
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'TurnOnConveniencePINSignin'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'TurnOnConveniencePINSignin'
            ValueData = $TurnOnConveniencePINSignin
            ValueType = 'String'
            Ensure = 'Present'
}}
}

