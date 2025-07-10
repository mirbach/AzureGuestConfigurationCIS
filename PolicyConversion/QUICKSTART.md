# Quick Start Guide - Policy Conversion

This guide walks you through converting your 29 AuditIfNotExists policies to DeployIfNotExists policies with Guest Configuration.

## Step 1: Prepare Your Input Files

1. Place all 29 AuditIfNotExists policy JSON files in the `Input/` folder
2. Name them descriptively (e.g., `user-account-control.json`, `audit-logon-events.json`)

Example input file structure:
```
Input/
├── user-account-control.json
├── audit-logon-events.json
├── password-policy.json
├── registry-security-settings.json
└── ...
```

## Step 2: Convert All Policies

Run the conversion script to process all policies:

```powershell
cd c:\git\AzureGuestConfigurationCIS\PolicyConversion
.\Convert-Policies.ps1
```

This will:
- Convert each AuditIfNotExists policy to DeployIfNotExists
- Generate Guest Configuration package structure
- Create supporting scripts and configuration files
- Generate placeholder DSC configurations (requires customization)

## Step 3: Customize DSC Resources

For each converted policy, you need to customize the DSC configuration:

```powershell
# Analyze a policy to get DSC resource suggestions
.\Detect-DSCResources.ps1 -PolicyFile "Input\user-account-control.json"

# List all available DSC resource types
.\Detect-DSCResources.ps1 -ListAvailableResources

# Generate DSC resource templates
.\Detect-DSCResources.ps1 -GenerateTemplates
```

### Example Customization

For a User Account Control policy, edit the generated DSC configuration:

```powershell
# File: Output/UserAccountControl/GuestConfiguration/AzureBaseline_UserAccountControl/AzureBaseline_UserAccountControl.ps1

Configuration AzureBaseline_UserAccountControl
{
    param
    (
        [Parameter()]
        [string]$UACAdminApprovalMode = 'Enabled',
        
        [Parameter()]
        [string]$UACElevationPrompt = 'Prompt for consent on the secure desktop'
    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'UACAdminApprovalMode'
        {
            Name = 'User_Account_Control_Admin_Approval_Mode_for_the_Built_in_Administrator_account'
            Value = $UACAdminApprovalMode
        }

        SecurityOption 'UACElevationPrompt'
        {
            Name = 'User_Account_Control_Behavior_of_the_elevation_prompt_for_administrators_in_Admin_Approval_Mode'
            Value = $UACElevationPrompt
        }
    }
}
```

## Step 4: Build All Packages

After customizing DSC configurations, build all Guest Configuration packages:

```powershell
# Build all packages
.\Manage-Policies.ps1 -Action Build

# Or build with force to rebuild existing packages
.\Manage-Policies.ps1 -Action Build -Force

# Build specific policy only
.\Manage-Policies.ps1 -Action Build -PolicyFilter "UserAccountControl"
```

## Step 5: Deploy to Azure Storage

Deploy all packages to Azure Storage:

```powershell
# Deploy all packages
.\Manage-Policies.ps1 -Action Deploy

# Deploy specific policy only
.\Manage-Policies.ps1 -Action Deploy -PolicyFilter "UserAccountControl"
```

## Step 6: Deploy Policies to Azure

Deploy all policy definitions to Azure:

```powershell
.\Manage-Policies.ps1 -Action DeployPolicies
```

## Step 7: Monitor Status

Check the status of all conversions and deployments:

```powershell
# Show overall status
.\Manage-Policies.ps1 -Action Status

# Test all configurations
.\Manage-Policies.ps1 -Action Test
```

## Common DSC Resource Types

### Registry Settings
```powershell
Registry 'SettingName'
{
    Key = 'HKEY_LOCAL_MACHINE\Software\Path'
    ValueName = 'SettingName'
    ValueData = $ParameterValue
    ValueType = 'String'
    Ensure = 'Present'
}
```

### Security Policy Settings
```powershell
SecurityOption 'PolicyName'
{
    Name = 'Policy_Name_From_Secedit'
    Value = $ParameterValue
}
```

### Audit Policy Settings
```powershell
AuditPolicySubcategory 'AuditSetting'
{
    Name = 'Subcategory Name'
    AuditFlag = $ParameterValue
    Ensure = 'Present'
}
```

### User Rights Assignment
```powershell
UserRightsAssignment 'UserRight'
{
    Policy = 'Policy_Name'
    Identity = $ParameterValue
    Ensure = 'Present'
}
```

## Bulk Operations Reference

```powershell
# Convert all policies
.\Convert-Policies.ps1

# Build all packages
.\Manage-Policies.ps1 -Action Build

# Deploy all packages to storage
.\Manage-Policies.ps1 -Action Deploy

# Update all policy files with new hashes
.\Manage-Policies.ps1 -Action UpdatePolicies

# Deploy all policies to Azure
.\Manage-Policies.ps1 -Action DeployPolicies

# Show status of all policies
.\Manage-Policies.ps1 -Action Status

# Test all configurations
.\Manage-Policies.ps1 -Action Test

# Clean all output directories
.\Manage-Policies.ps1 -Action Clean
```

## Troubleshooting

### DSC Configuration Compilation Issues
```powershell
# Test individual configuration
cd "Output\PolicyName\GuestConfiguration\ConfigurationName"
.\Test-Configuration.ps1 -AssignmentType Audit
```

### Package Build Issues
```powershell
# Force rebuild with verbose output
cd "Output\PolicyName\GuestConfiguration\ConfigurationName"
.\Build-And-Deploy-Package.ps1 -Force -Verbose
```

### Azure Deployment Issues
```powershell
# Check Azure connectivity
Get-AzContext

# Re-authenticate if needed
Connect-AzAccount
```

## Next Steps

1. **Customize DSC Resources**: Review each generated DSC configuration and customize based on your requirements
2. **Test Locally**: Use the Test-Configuration.ps1 scripts to validate configurations
3. **Deploy Gradually**: Start with a few policies and test compliance before deploying all 29
4. **Monitor Compliance**: Use Azure Policy portal to monitor compliance across your environment
5. **Scale Assignment**: Assign policies to appropriate scopes (resource groups, subscriptions)

## Output Structure

Each converted policy will have this structure:

```
Output/
└── PolicyName/
    ├── AuditIfNotExists - PolicyName.json
    ├── DeployIfNotExists - PolicyName.json
    └── GuestConfiguration/
        └── ConfigurationName/
            ├── ConfigurationName.ps1
            ├── Build-And-Deploy-Package.ps1
            ├── Deploy-GuestConfigurationPackage.ps1
            ├── Test-Configuration.ps1
            ├── Update-PolicyFiles.ps1
            ├── Fix-GuestConfigurationPackage.ps1
            ├── Setup-Prerequisites.ps1
            ├── azure-config.json
            ├── README.md
            ├── Modules/
            └── Output/
```

This structure ensures each policy is self-contained and follows the established patterns from your working System Audit Policies example.
