# Azure Guest Configuration CIS

Configure VMs using Azure Guest Configuration to meet CIS (Center for Internet Security) requirements.

## Contents

This repository contains Azure Policy definitions and Guest Configuration packages for implementing CIS security controls on Windows virtual machines.

### Policies

1. **AuditIfNotExists Policy**: `Windows machines should meet requirements for 'System Audit Policies - Object Access'.json`
   - Audits compliance with system audit policy requirements
   - Reports non-compliant machines without making changes

2. **DeployIfNotExists Policy**: `DeployIfNotExists - Windows machines should meet requirements for 'System Audit Policies - Object Access'.json`
   - Automatically configures audit policy settings on non-compliant machines
   - Includes remediation capabilities

### Guest Configuration Package

Located in `GuestConfiguration/AzureBaseline_SystemAuditPoliciesObjectAccess/`:

- PowerShell DSC configuration for audit policy settings
- Custom AuditPolicyDsc module for managing Windows audit policies
- Build and deployment scripts
- Testing utilities

## Audit Policy Settings

The configuration manages the following Object Access audit subcategories:

- **Audit Detailed File Share**: Controls auditing of detailed file share access events
- **Audit File Share**: Controls auditing of file share operations  
- **Audit File System**: Controls auditing of file system access events

Each setting can be configured to:
- No Auditing
- Success
- Failure  
- Success and Failure

## Quick Start

1. **For Audit Only**: Deploy the AuditIfNotExists policy to assess current compliance
2. **For Remediation**: Deploy the DeployIfNotExists policy to automatically configure settings
3. **For Testing**: Use the Guest Configuration package to test locally before deployment

## Security Considerations

- Enabling success auditing for file operations can generate high volumes of events
- Consider the impact on log storage and performance when enabling comprehensive auditing
- Review audit settings regularly to ensure they meet your security requirements

## Requirements

- Windows Server 2012 R2 or later / Windows 10 or later
- Azure Guest Configuration extension installed on target VMs
- Appropriate RBAC permissions for policy assignment and Guest Configuration

For detailed usage instructions, see the README in the GuestConfiguration folder.
