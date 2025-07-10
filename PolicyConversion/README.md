# Policy Conversion Automation

This folder contains tools to automate the conversion of 29+ AuditIfNotExists policies to DeployIfNotExists policies with Guest Configuration packages.

## ✅ Current Status

- **✅ 29 policies successfully converted and built**
- **✅ All Guest Configuration packages build successfully**  
- **✅ Automated content hash updates integrated**
- **✅ Path length issues resolved**
- **✅ Ready for Azure deployment and policy assignment**

## Folder Structure

```
PolicyConversion/
├── Input/                          # Original AuditIfNotExists policies (30 files)
├── Output/                         # Generated DeployIfNotExists policies and Guest Configuration packages (29 folders)
│   ├── AdminTemplates-ControlPanel/
│   ├── AdminTemplates-MSSLegacy/
│   ├── AdminTemplates-Network/
│   ├── AdminTemplates-System/
│   ├── AuditPolicies-AccountLogon/
│   ├── AuditPolicies-AccountMgmt/
│   ├── AuditPolicies-DetailedTracking/
│   ├── AuditPolicies-LogonLogoff/
│   ├── AuditPolicies-ObjectAccess/
│   ├── AuditPolicies-PolicyChange/
│   ├── AuditPolicies-PrivilegeUse/
│   ├── AuditPolicies-System/
│   ├── SecurityOptions-Accounts/
│   ├── SecurityOptions-Audit/
│   ├── SecurityOptions-Devices/
│   ├── SecurityOptions-InteractiveLogon/
│   ├── SecurityOptions-MSNetworkClient/
│   ├── SecurityOptions-MSNetworkServer/
│   ├── SecurityOptions-NetworkAccess/
│   ├── SecurityOptions-NetworkSecurity/
│   ├── SecurityOptions-RecoveryConsole/
│   ├── SecurityOptions-Shutdown/
│   ├── SecurityOptions-SystemObjects/
│   ├── SecurityOptions-SystemSettings/
│   ├── SecurityOptions-UAC/
│   ├── SecuritySettings-AccountPolicies/
│   ├── UserRightsAssignment/
│   ├── WindowsComponents/
│   └── WindowsFirewall/
├── Templates/                      # Template files for generation
└── Scripts for automation and management
```

## Quick Start

```powershell
cd c:\git\AzureGuestConfigurationCIS\PolicyConversion

# View current status
.\Manage-Policies.ps1 -Action Status

# Build all packages (with automatic hash updates)
.\Manage-Policies.ps1 -Action Build

# Update only content hashes
.\Manage-Policies.ps1 -Action UpdateHashes

# Deploy packages to Azure Storage (with automatic hash updates)
.\Manage-Policies.ps1 -Action Deploy

# Deploy policies to Azure
.\Manage-Policies.ps1 -Action DeployPolicies
```

## Key Scripts

| Script | Purpose |
|--------|---------|
| `Manage-Policies.ps1` | **Main bulk operations script** - build, deploy, status, hash updates |
| `Convert-Policies.ps1` | Convert AuditIfNotExists to DeployIfNotExists |
| `Import-AzurePolicies.ps1` | Import policies from Azure |

## Actions Available

- **`Status`** - View current state of all policies and packages
- **`Build`** - Build all Guest Configuration packages *(includes automatic hash updates)*
- **`Deploy`** - Deploy packages to Azure Storage *(includes automatic hash updates)*
- **`UpdateHashes`** - Update content hashes in azure-config.json files
- **`UpdatePolicies`** - Update policy files with new content hashes
- **`DeployPolicies`** - Deploy all policies to Azure
- **`Test`** - Test DSC configurations
- **`Clean`** - Clean output directories

## 🔧 Automatic Hash Updates

The system now automatically updates SHA256 content hashes:

- **During Build**: Hash is automatically updated after each successful package build
- **During Deployment**: Hash is automatically updated after each successful deployment  
- **Manual Updates**: Use `UpdateHashes` action to update all hashes manually

This ensures the `azure-config.json` files always contain the current package hashes without manual intervention.

## Features

- **✅ Complete Automation**: End-to-end conversion and deployment pipeline
- **✅ Automatic Hash Management**: Content hashes updated automatically after builds/deployments
- **✅ Bulk Operations**: Process all 29 policies with single commands
- **✅ Path Length Resolution**: Short directory names prevent Windows path limit issues
- **✅ Status Reporting**: Detailed progress and success/failure tracking
- **✅ Template-Based**: Consistent structure across all policies
- **✅ Error Handling**: Robust error detection and reporting

## Configuration

The script uses the existing `azure-config.json` structure for consistent deployment:

```json
{
  "SubscriptionId": "e749c27d-1157-4753-929c-adfddb9c814c",
  "StorageAccount": {
    "Name": "saserverhardeningdkleac",
    "ResourceGroupName": "RG_ARC_Local_All_RestoreTest",
    "ContainerName": "guestconfiguration"
  },
  "Deployment": {
    "TargetResourceGroup": "RG_ARC_Local_All_RestoreTest",
    "Location": "westeurope"
  }
}
```

## Next Steps

1. Run the conversion script on all 29 policies
2. Review and customize DSC resources for each policy type
3. Test individual policies in the target environment
4. Deploy policies using the established deployment scripts
5. Monitor compliance across all policies
