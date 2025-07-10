Configuration AzureBaseline_SecurityOptions_MicrosoftNetworkClient
{
    param
    (
        [Parameter()]
        [string]$MicrosoftNetworkClientDigitallySignCommunicationsAlways = 'Enabled',

        [Parameter()]
        [string]$MicrosoftNetworkClientSendUnencryptedPasswordToThirdpartySMBServers = 'Disabled',

        [Parameter()]
        [string]$MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession = '1,15',

        [Parameter()]
        [string]$MicrosoftNetworkServerDigitallySignCommunicationsAlways = 'Enabled',

        [Parameter()]
        [string]$MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire = 'Enabled'

    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'MicrosoftNetworkClientDigitallySignCommunicationsAlways'
        {
            Name = 'MicrosoftNetworkClientDigitallySignCommunicationsAlways'
            Microsoft_network_client_Digitally_sign_communications_always = $MicrosoftNetworkClientDigitallySignCommunicationsAlways
        }
        SecurityOption 'MicrosoftNetworkClientSendUnencryptedPasswordToThirdpartySMBServers'
        {
            Name = 'MicrosoftNetworkClientSendUnencryptedPasswordToThirdpartySMBServers'
            Microsoft_network_client_Send_unencrypted_password_to_third_party_SMB_servers = $MicrosoftNetworkClientSendUnencryptedPasswordToThirdpartySMBServers
        }
        SecurityOption 'MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession'
        {
            Name = 'MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession'
            Microsoft_network_server_Amount_of_idle_time_required_before_suspending_session = $MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession
        }
        SecurityOption 'MicrosoftNetworkServerDigitallySignCommunicationsAlways'
        {
            Name = 'MicrosoftNetworkServerDigitallySignCommunicationsAlways'
            Microsoft_network_server_Digitally_sign_communications_always = $MicrosoftNetworkServerDigitallySignCommunicationsAlways
        }
        SecurityOption 'MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire'
        {
            Name = 'MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire'
            Microsoft_network_server_Disconnect_clients_when_logon_hours_expire = $MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire

}}
}

