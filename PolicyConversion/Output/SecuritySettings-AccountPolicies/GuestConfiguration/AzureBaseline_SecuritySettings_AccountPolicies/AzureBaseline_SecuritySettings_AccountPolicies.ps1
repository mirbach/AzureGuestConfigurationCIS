Configuration AzureBaseline_SecuritySettings_AccountPolicies
{
    param
    (
        [Parameter()]
        [int]$EnforcePasswordHistory = 12,

        [Parameter()]
        [int]$MaximumPasswordAge = 60,

        [Parameter()]
        [int]$MinimumPasswordAge = 1,

        [Parameter()]
        [int]$MinimumPasswordLength = 14,

        [Parameter()]
        [string]$PasswordMustMeetComplexityRequirements = 'Enabled',

        [Parameter()]
        [string]$StorePasswordsUsingReversibleEncryption = 'Disabled'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        AccountPolicy AccountPolicySettings
        {
            Name = 'Account Policy Settings'
            Enforce_password_history = $EnforcePasswordHistory
            Maximum_password_age = $MaximumPasswordAge
            Minimum_password_age = $MinimumPasswordAge
            Minimum_password_length = $MinimumPasswordLength
            Password_must_meet_complexity_requirements = $PasswordMustMeetComplexityRequirements
            Store_passwords_using_reversible_encryption = $StorePasswordsUsingReversibleEncryption
        }
    }
}

