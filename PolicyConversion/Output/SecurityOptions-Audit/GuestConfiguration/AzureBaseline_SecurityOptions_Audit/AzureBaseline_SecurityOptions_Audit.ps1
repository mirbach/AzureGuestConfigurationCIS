Configuration AzureBaseline_SecurityOptions_Audit
{
    param
    (
        [Parameter()]
        [string]$AuditShutDownSystemImmediatelyIfUnableToLogSecurityAudits = 'Disabled'

    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'AuditShutDownSystemImmediatelyIfUnableToLogSecurityAudits'
        {
            Name = 'AuditShutDownSystemImmediatelyIfUnableToLogSecurityAudits'
            Audit_Shut_down_system_immediately_if_unable_to_log_security_audits = $AuditShutDownSystemImmediatelyIfUnableToLogSecurityAudits
}
}
}
