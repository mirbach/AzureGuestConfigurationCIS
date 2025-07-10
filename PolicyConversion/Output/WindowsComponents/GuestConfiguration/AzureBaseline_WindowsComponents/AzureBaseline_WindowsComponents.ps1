Configuration AzureBaseline_WindowsComponents
{
    param
    (
        [Parameter()]
        [string]$SendFileSamplesWhenFurtherAnalysisIsRequired = 'Require Signing',

        [Parameter()]
        [string]$AllowIndexingOfEncryptedFiles = 'Disabled',

        [Parameter()]
        [string]$AllowTelemetry = 'Prompt for consent on the secure desktop',

        [Parameter()]
        [string]$AllowUnencryptedTraffic = 'Disabled',

        [Parameter()]
        [string]$AlwaysInstallWithElevatedPrivileges = 'Disabled',

        [Parameter()]
        [string]$AlwaysPromptForPasswordUponConnection = 'Require Signing',

        [Parameter()]
        [string]$ApplicationSpecifyTheMaximumLogFileSizeKB = '32768',

        [Parameter()]
        [string]$AutomaticallySendMemoryDumpsForOSgeneratedErrorReports = 'Require Signing',

        [Parameter()]
        [string]$ConfigureDefaultConsent = '4',

        [Parameter()]
        [string]$ConfigureWindowsSmartScreen = 'Require Signing',

        [Parameter()]
        [string]$DisallowDigestAuthentication = 'Disabled',

        [Parameter()]
        [string]$DisallowWinRMFromStoringRunAsCredentials = 'Require Signing',

        [Parameter()]
        [string]$DoNotAllowPasswordsToBeSaved = 'Require Signing',

        [Parameter()]
        [string]$SecuritySpecifyTheMaximumLogFileSizeKB = '196608',

        [Parameter()]
        [string]$SetClientConnectionEncryptionLevel = '3',

        [Parameter()]
        [string]$SetTheDefaultBehaviorForAutoRun = 'Require Signing',

        [Parameter()]
        [string]$SetupSpecifyTheMaximumLogFileSizeKB = '32768',

        [Parameter()]
        [string]$SystemSpecifyTheMaximumLogFileSizeKB = '32768',

        [Parameter()]
        [string]$TurnOffDataExecutionPreventionForExplorer = 'Disabled',

        [Parameter()]
        [string]$SpecifyTheIntervalToCheckForDefinitionUpdates = '8'
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Registry 'SendFileSamplesWhenFurtherAnalysisIsRequired'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SendFileSamplesWhenFurtherAnalysisIsRequired'
            ValueData = $SendFileSamplesWhenFurtherAnalysisIsRequired
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AllowIndexingOfEncryptedFiles'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AllowIndexingOfEncryptedFiles'
            ValueData = $AllowIndexingOfEncryptedFiles
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AllowTelemetry'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AllowTelemetry'
            ValueData = $AllowTelemetry
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AllowUnencryptedTraffic'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AllowUnencryptedTraffic'
            ValueData = $AllowUnencryptedTraffic
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AlwaysInstallWithElevatedPrivileges'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AlwaysInstallWithElevatedPrivileges'
            ValueData = $AlwaysInstallWithElevatedPrivileges
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AlwaysPromptForPasswordUponConnection'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AlwaysPromptForPasswordUponConnection'
            ValueData = $AlwaysPromptForPasswordUponConnection
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'ApplicationSpecifyTheMaximumLogFileSizeKB'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'ApplicationSpecifyTheMaximumLogFileSizeKB'
            ValueData = $ApplicationSpecifyTheMaximumLogFileSizeKB
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'AutomaticallySendMemoryDumpsForOSgeneratedErrorReports'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'AutomaticallySendMemoryDumpsForOSgeneratedErrorReports'
            ValueData = $AutomaticallySendMemoryDumpsForOSgeneratedErrorReports
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'ConfigureDefaultConsent'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'ConfigureDefaultConsent'
            ValueData = $ConfigureDefaultConsent
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'ConfigureWindowsSmartScreen'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'ConfigureWindowsSmartScreen'
            ValueData = $ConfigureWindowsSmartScreen
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'DisallowDigestAuthentication'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'DisallowDigestAuthentication'
            ValueData = $DisallowDigestAuthentication
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'DisallowWinRMFromStoringRunAsCredentials'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'DisallowWinRMFromStoringRunAsCredentials'
            ValueData = $DisallowWinRMFromStoringRunAsCredentials
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'DoNotAllowPasswordsToBeSaved'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'DoNotAllowPasswordsToBeSaved'
            ValueData = $DoNotAllowPasswordsToBeSaved
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'SecuritySpecifyTheMaximumLogFileSizeKB'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SecuritySpecifyTheMaximumLogFileSizeKB'
            ValueData = $SecuritySpecifyTheMaximumLogFileSizeKB
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'SetClientConnectionEncryptionLevel'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SetClientConnectionEncryptionLevel'
            ValueData = $SetClientConnectionEncryptionLevel
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'SetTheDefaultBehaviorForAutoRun'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SetTheDefaultBehaviorForAutoRun'
            ValueData = $SetTheDefaultBehaviorForAutoRun
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'SetupSpecifyTheMaximumLogFileSizeKB'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SetupSpecifyTheMaximumLogFileSizeKB'
            ValueData = $SetupSpecifyTheMaximumLogFileSizeKB
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'SystemSpecifyTheMaximumLogFileSizeKB'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SystemSpecifyTheMaximumLogFileSizeKB'
            ValueData = $SystemSpecifyTheMaximumLogFileSizeKB
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'TurnOffDataExecutionPreventionForExplorer'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'TurnOffDataExecutionPreventionForExplorer'
            ValueData = $TurnOffDataExecutionPreventionForExplorer
            ValueType = 'String'
            Ensure = 'Present'
        }
        Registry 'SpecifyTheIntervalToCheckForDefinitionUpdates'
        {
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'SpecifyTheIntervalToCheckForDefinitionUpdates'
            ValueData = $SpecifyTheIntervalToCheckForDefinitionUpdates
            ValueType = 'String'
            Ensure = 'Present'
}}
}

