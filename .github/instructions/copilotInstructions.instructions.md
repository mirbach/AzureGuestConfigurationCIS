---
applyTo: '**'
---

# Coding Standards and Domain Knowledge

## General Guidelines
- Always check documentation and existing code before suggesting changes
- Gather context first - Don't make assumptions
- Create a file azure.config and store the following variables:
  - $AzureSubscriptionId
  - $AzureResourceGroupName
  - $AzureLocation
  - $AzureStorageAccountName
  - $AzureStorageContainerName
- Always refer to the azure.config file for Azure variables

## Script and Fix Management
- Do not create separate fix scripts
- Use convert-policies.ps1 to convert policies
- When issues are found:
  1. Delete the output policies folder
  2. Fix the original conversion script
  3. Reconvert the policies using the updated script
- Always update the original script when making corrections

## Policy Conversion Script (Convert-Policies.ps1)

### Purpose
Converts Azure Policy JSON files from PolicyConversion\Input to DeployIfNotExists Guest Configuration policies.

### Key Features
- Converts all 29 input policies to Guest Configuration format
- Generates short folder names with "GG-" prefix
- Creates both DeployIfNotExists and AuditIfNotExists policies
- Generates proper DSC configurations for each policy type
- Uses azure.config for all Azure variables
- Supports mapping of policy parameters to DSC resource properties

### Usage Examples

#### Convert All Policies
```powershell
.\Convert-Policies.ps1
```

#### Convert Specific Policy
```powershell
.\Convert-Policies.ps1 -PolicyName "Security Options - Accounts"
```

#### Convert with Clean Output (delete existing output first)
```powershell
.\Convert-Policies.ps1 -CleanOutput
```

#### Convert Specific Policy with Clean Output
```powershell
.\Convert-Policies.ps1 -PolicyName "Security Options - Accounts" -CleanOutput
```

### Output Structure
- Creates folders in PolicyConversion\Output\ with "GG-" prefix
- Each folder contains:
  - DeployIfNotExists policy JSON
  - AuditIfNotExists policy JSON
  - GuestConfiguration folder with DSC configuration

### DSC Resource Mapping
- Security Options → SecurityPolicyDsc resources
- User Rights Assignment → UserRightsAssignment resources
- Audit Policies → AuditPolicyDsc resources
- Account Policies → AccountPolicyDsc resources
- Administrative Templates → Various policy-specific resources

## Policy Management Script (Manage-Policies.ps1)

### Purpose
Comprehensive management of Azure Guest Configuration policies including deployment, DSC package building, and Azure Storage operations.

### Available Functions

#### 1. Deploy Policies to Azure
```powershell
.\Manage-Policies.ps1 -DeployPolicies
.\Manage-Policies.ps1 -DeployPolicies -PolicyName "SecurityOptions"
```

#### 2. Remove Policies from Azure
```powershell
.\Manage-Policies.ps1 -RemovePolicies
.\Manage-Policies.ps1 -RemovePolicies -PolicyName "SecurityOptions"
```

#### 3. Get Policies from Azure
```powershell
.\Manage-Policies.ps1 -GetPolicies
.\Manage-Policies.ps1 -GetPolicies -PolicyName "SecurityOptions"
```

#### 4. Remove Policy Assignments
```powershell
.\Manage-Policies.ps1 -RemoveAssignments
.\Manage-Policies.ps1 -RemoveAssignments -PolicyName "SecurityOptions"
```

#### 5. Build DSC Packages
```powershell
.\Manage-Policies.ps1 -BuildDSCPackages
.\Manage-Policies.ps1 -BuildDSCPackages -PolicyName "SecurityOptions"
.\Manage-Policies.ps1 -BuildDSCPackages -Force
```

#### 6. Update Policy Hashes
```powershell
.\Manage-Policies.ps1 -UpdateHashes
.\Manage-Policies.ps1 -UpdateHashes -PolicyName "SecurityOptions"
```

#### 7. Upload DSC Packages to Azure Storage
```powershell
.\Manage-Policies.ps1 -UploadPackages
.\Manage-Policies.ps1 -UploadPackages -PolicyName "SecurityOptions"
```

### Complete DSC Package Workflow
Run these commands in sequence for full DSC package management:

```powershell
# 1. Build all packages and calculate hashes
.\Manage-Policies.ps1 -BuildDSCPackages

# 2. Update policy files with calculated hashes
.\Manage-Policies.ps1 -UpdateHashes

# 3. Upload packages to Azure Storage
.\Manage-Policies.ps1 -UploadPackages
```

### Parameters
- `-PolicyName`: Target specific policy (partial name matching)
- `-SubscriptionId`: Override subscription ID from azure.config
- `-ResourceGroupName`: Override resource group name from azure.config
- `-Force`: Force rebuild/overwrite existing packages

### Azure Configuration Requirements
Ensure azure.config contains:
- `$AzureSubscriptionId`: Your Azure subscription ID
- `$AzureResourceGroupName`: Resource group for policy deployment
- `$AzureLocation`: Azure region
- `$AzureStorageAccountName`: Storage account for DSC packages
- `$AzureStorageContainerName`: Container name for DSC packages

## Policy Quality Assurance
- When fixing one policy, identify if there are others that need similar fixes
- When converting policies, ensure the output policy matches the original policy's parameters
- Always compare the original policy from the input folder to verify the output policy is correct
- Ensure only the parameters of the original policies exist in the output

## Testing Requirements
- Test all 29 policies after any changes
- Verify output matches original policy parameters
- Ensure no additional parameters are introduced during conversion
- Test DSC package building for all policies
- Verify policy hashes are correctly updated after package building
- Test Azure deployment of policies

## Troubleshooting Common Issues

### DSC Package Build Failures
- Check DSC resource property names match module schema
- Verify parameter values are valid for the DSC resource
- Ensure only supported DSC modules are used (avoid PSDesiredStateConfiguration)
- Use PSDscResources for Guest Configuration compatibility

### Policy Conversion Issues
- Verify input policy JSON structure is correct
- Check parameter mapping in Convert-Policies.ps1
- Ensure ConvertTo-ShortFolderName generates valid folder names
- Verify DSC resource generation logic for each policy type

### Azure Deployment Issues
- Verify Azure authentication and subscription context
- Check policy JSON structure and required fields
- Ensure DSC package contentUri and contentHash are correct
- Verify storage account and container accessibility