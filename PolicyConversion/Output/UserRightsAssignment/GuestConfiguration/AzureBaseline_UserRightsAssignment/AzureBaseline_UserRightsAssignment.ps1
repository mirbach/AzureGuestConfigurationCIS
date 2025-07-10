Configuration AzureBaseline_UserRightsAssignment
{
    param
    (
        [Parameter()]
        [string[]]$AccessFromNetwork = @('Authenticated Users'),

        [Parameter()]
        [string[]]$AllowLogonLocally = @('Administrators', 'Users')
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        UserRightsAssignment AccessFromNetwork
        {
            Policy = 'Access_this_computer_from_the_network'
            Identity = $AccessFromNetwork
        }

        UserRightsAssignment AllowLogonLocally
        {
            Policy = 'Allow_log_on_locally'
            Identity = $AllowLogonLocally
        }
    }
}
