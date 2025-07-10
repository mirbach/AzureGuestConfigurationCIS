Configuration AzureBaseline_SecurityOptions_Accounts
{
    param
    (
        [Parameter()]
        [string]$AccountsGuestAccountStatus = 'Disabled'

    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'AccountsGuestAccountStatus'
        {
            Name = 'AccountsGuestAccountStatus'
            Accounts_Guest_account_status = $AccountsGuestAccountStatus
        }
    }
}