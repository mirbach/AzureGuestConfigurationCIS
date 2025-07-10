Configuration AzureBaseline_SecurityOptions_NetworkSecurity
{
    param
    (
        [Parameter()]
        [string]$NetworkSecurityConfigureEncryptionTypesAllowedForKerberos = 'AES256_HMAC_SHA1',

        [Parameter()]
        [string]$NetworkSecurityLANManagerAuthenticationLevel = 'Send NTLMv2 responses only. Refuse LM & NTLM',

        [Parameter()]
        [string]$NetworkSecurityLDAPClientSigningRequirements = 'Require Signing',

        [Parameter()]
        [string]$NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCClients = 'Both options checked',

        [Parameter()]
        [string]$NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCServers = 'Both options checked'

    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'NetworkSecurityConfigureEncryptionTypesAllowedForKerberos'
        {
            Name = 'NetworkSecurityConfigureEncryptionTypesAllowedForKerberos'
            Network_security_Configure_encryption_types_allowed_for_Kerberos = $NetworkSecurityConfigureEncryptionTypesAllowedForKerberos
        }
        SecurityOption 'NetworkSecurityLANManagerAuthenticationLevel'
        {
            Name = 'NetworkSecurityLANManagerAuthenticationLevel'
            Network_security_LAN_Manager_authentication_level = $NetworkSecurityLANManagerAuthenticationLevel
        }
        SecurityOption 'NetworkSecurityLDAPClientSigningRequirements'
        {
            Name = 'NetworkSecurityLDAPClientSigningRequirements'
            Network_security_LDAP_client_signing_requirements = $NetworkSecurityLDAPClientSigningRequirements
        }
        SecurityOption 'NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCClients'
        {
            Name = 'NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCClients'
            Network_security_Minimum_session_security_for_NTLM_SSP_based_including_secure_RPC_clients = $NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCClients
        }
        SecurityOption 'NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCServers'
        {
            Name = 'NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCServers'
            Network_security_Minimum_session_security_for_NTLM_SSP_based_including_secure_RPC_servers = $NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCServers
        }
    }
}