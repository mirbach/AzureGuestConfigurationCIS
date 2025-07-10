Configuration AzureBaseline_SecurityOptions_Systemsettings
{
    param
    (
        [Parameter()]
        [string]$SystemSettingsUseCertificateRulesOnWindowsExecutablesForSoftwareRestrictionPolicies = 'Enabled'

    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'SystemSettingsUseCertificateRulesOnWindowsExecutablesForSoftwareRestrictionPolicies'
        {
            Name = 'SystemSettingsUseCertificateRulesOnWindowsExecutablesForSoftwareRestrictionPolicies'
            System_settings_Use_Certificate_Rules_on_Windows_Executables_for_Software_Restriction_Policies = $SystemSettingsUseCertificateRulesOnWindowsExecutablesForSoftwareRestrictionPolicies            }
}
}

