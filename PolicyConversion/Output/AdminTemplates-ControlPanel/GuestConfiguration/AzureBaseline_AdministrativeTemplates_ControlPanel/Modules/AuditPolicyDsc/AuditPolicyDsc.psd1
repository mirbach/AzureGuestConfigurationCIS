@{
    RootModule = 'AuditPolicyDsc.psm1'
    ModuleVersion = '1.4.0.0'
    GUID = 'fb835567-1d96-40b0-8318-9dcb77d33a9b'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = '(c) Microsoft Corporation. All rights reserved.'
    Description = 'This module contains DSC resources for managing audit policies.'
    PowerShellVersion = '5.0'
    CLRVersion = '4.0'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    DscResourcesToExport = @('AuditPolicySubcategory')
    PrivateData = @{
        PSData = @{
            Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')
            LicenseUri = 'https://github.com/PowerShell/AuditPolicyDsc/blob/master/LICENSE'
            ProjectUri = 'https://github.com/PowerShell/AuditPolicyDsc'
            IconUri = ''
            ReleaseNotes = 'Updated to support audit policy configuration for Guest Configuration'
        }
    }
    HelpInfoURI = 'https://github.com/PowerShell/AuditPolicyDsc'
}
