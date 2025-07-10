# Azure Guest Configuration - System Audit Policies Object Access

This Guest Configuration package configures Windows audit policies for Object Access subcategories including File System, File Share, and Detailed File Share auditing.

## Contents

- **AzureBaseline_AdministrativeTemplates_MSSLegacy.ps1**: Main PowerShell DSC configuration
- **Modules/AuditPolicyDsc**: Custom DSC resource module for managing audit policies
- **Build-GuestConfigurationPackage.ps1**: Script to build the Guest Configuration package

## Prerequisites

### Local Development Requirements
1. PowerShell 5.1 or later
2. GuestConfiguration PowerShell module
3. Administrative privileges (for testing locally)

### Azure Requirements
1. **Azure Subscription** with appropriate permissions
2. **Resource Group** to contain the storage account
3. **Storage Account** for hosting Guest Configuration packages
   - Must be a general-purpose v2 storage account
   - Must allow blob public access (for Guest Configuration agent to download packages)
   - Recommended: Use a dedicated storage account for Guest Configuration packages
4. **Azure PowerShell modules**:
   - Az.Accounts
   - Az.Storage
   - Az.Resources
   - GuestConfiguration

### RBAC Permissions Required
- **Contributor** or **Storage Account Contributor** on the storage account
- **Guest Configuration Resource Contributor** role for Guest Configuration operations
- **Policy Contributor** role to deploy Azure Policies

### Creating the Storage Account

The storage account must be created before running the deployment script. You can create it using:

#### Azure CLI:
```bash
# Create resource group (if needed)
az group create --name "rg-guestconfig" --location "East US"

# Create storage account
az storage account create \
  --name "stguestconfig$(Get-Random)" \
  --resource-group "rg-guestconfig" \
  --location "East US" \
  --sku "Standard_LRS" \
  --kind "StorageV2" \
  --allow-blob-public-access true
```

#### Azure PowerShell:
```powershell
# Create resource group (if needed)
New-AzResourceGroup -Name "rg-guestconfig" -Location "East US"

# Create storage account
$storageAccountName = "stguestconfig$(Get-Random)"
New-AzStorageAccount -ResourceGroupName "rg-guestconfig" `
  -Name $storageAccountName `
  -Location "East US" `
  -SkuName "Standard_LRS" `
  -Kind "StorageV2" `
  -AllowBlobPublicAccess $true
```

#### Azure Portal:
1. Navigate to Storage accounts > Create
2. Select your subscription and resource group
3. Enter a unique storage account name
4. Choose Standard performance and LRS redundancy
5. On the Advanced tab, ensure "Allow Blob public access" is enabled
6. Review and create

## Quick Start

### Option 1: Automated Setup (Recommended)

1. **Run the prerequisites setup script:**
```powershell
.\Setup-Prerequisites.ps1 -SubscriptionId "your-subscription-id" -InstallModules
```
This will:
- Install required PowerShell modules
- Create a resource group (if needed)
- Create a storage account with proper configuration
- Save configuration for later use

2. **Build, deploy, and update policies in one command:**
```powershell
# Use the saved configuration from step 1
$config = Get-Content ".\azure-config.json" | ConvertFrom-Json
.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles -SubscriptionId $config.SubscriptionId -ResourceGroupName $config.ResourceGroupName -StorageAccountName $config.StorageAccountName
```

**Alternative: Step-by-step approach**
```powershell
# Build the package
.\Build-And-Deploy-Package.ps1

# Deploy to Azure
.\Build-And-Deploy-Package.ps1 -Deploy -SubscriptionId $config.SubscriptionId -ResourceGroupName $config.ResourceGroupName -StorageAccountName $config.StorageAccountName

# Update policy files
.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles -SubscriptionId $config.SubscriptionId -ResourceGroupName $config.ResourceGroupName -StorageAccountName $config.StorageAccountName
```

Note: The policy files use prefixes to clearly identify their type:
- `[AuditIfNotExists] Windows machines should meet requirements...` - Audit-only policy
- `[DeployIfNotExists] Windows machines should meet requirements...` - Deployment policy
The display names within the files include [GG Serverhardening] to distinguish them from built-in Microsoft policies.

### Option 2: Manual Setup

1. **Create storage account manually** (see prerequisites section above)
2. **Build, deploy, and update policies:**
```powershell
# All-in-one command
.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles -SubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -StorageAccountName "your-storage-account"
```

**Alternative: Step-by-step approach**
```powershell
# Build the package
.\Build-And-Deploy-Package.ps1

# Deploy to Azure
.\Build-And-Deploy-Package.ps1 -Deploy -SubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -StorageAccountName "your-storage-account"

# Update policy files
.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles -SubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -StorageAccountName "your-storage-account"
```

## Package Building Details

The `Build-And-Deploy-Package.ps1` script provides a unified workflow that:

### Build Process:
- Compiles the DSC configuration
- Creates the Guest Configuration package using `New-GuestConfigurationPackage`
- **Automatically fixes package metadata** including:
  - Sets the `Name` field in `metaconfig.json` if missing
  - Calculates and sets the `ContentHash` field to the SHA256 hash of the MOF file
  - Ensures proper package structure for Azure validation
- Tests the package validity

### Deploy Process (with `-Deploy` flag):
- Uploads the package to Azure Storage
- Creates the `guestconfiguration` container if it doesn't exist
- Verifies package accessibility after upload

### Policy Update Process (with `-UpdatePolicyFiles` flag):
- Automatically updates both AuditIfNotExists and DeployIfNotExists policy files
- Sets the correct `contentUri` pointing to the Azure Storage location
- Calculates and sets the `contentHash` to match the package SHA256 hash
- Updates all guestConfiguration sections in the policy templates

### Usage Examples:
```powershell
# Build only
.\Build-And-Deploy-Package.ps1

# Build and deploy
.\Build-And-Deploy-Package.ps1 -Deploy -SubscriptionId "xxx" -ResourceGroupName "xxx" -StorageAccountName "xxx"

# Complete workflow: Build, deploy, and update policies
.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles -SubscriptionId "xxx" -ResourceGroupName "xxx" -StorageAccountName "xxx"

# Force rebuild existing package
.\Build-And-Deploy-Package.ps1 -Force
```

## Configuration Parameters

The configuration accepts the following parameters:

- **AuditDetailedFileShare**: Controls auditing of detailed file share access
  - Values: "No Auditing", "Success", "Failure", "Success and Failure"
  - Default: "No Auditing"

- **AuditFileShare**: Controls auditing of file share operations
  - Values: "No Auditing", "Success", "Failure", "Success and Failure"
  - Default: "No Auditing"

- **AuditFileSystem**: Controls auditing of file system access
  - Values: "No Auditing", "Success", "Failure", "Success and Failure"
  - Default: "No Auditing"

## Configuration File

The project now uses a centralized configuration file (`azure-config.json`) to store Azure resource information:

```json
{
  "Location": "West Europe",
  "SubscriptionId": "e749c27d-1157-4753-929c-adfddb9c814c",
  "StorageAccount": {
    "Name": "saserverhardeningdkleac",
    "ResourceGroupName": "RG_ARC_Local_All_RestoreTest",
    "ContainerName": "guestconfiguration"
  },
  "Deployment": {
    "TargetResourceGroup": "RG_ARC_Local_All_RestoreTest",
    "Location": "westeurope"
  },
  "Policy": {
    "AuditPolicyName": "GG-Audit-SystemAuditPolicies-ObjectAccess",
    "DeployPolicyName": "GG-Deploy-SystemAuditPolicies-ObjectAccess"
  },
  "Package": {
    "Name": "AzureBaseline_AdministrativeTemplates_MSSLegacy",
    "Version": "1.0.0.0",
    "CurrentContentHash": "AF2A9739BA08FC08F0C9C1C601BD577DD79D5FED00745BFAAAC3A683F3B1EFAA"
  }
}
```

This configuration file is automatically loaded by:
- `Build-And-Deploy-Package.ps1`
- `Deploy-GuestConfigurationPackage.ps1`
- `Deploy-Policies-PowerShell.ps1`

Parameters can still be provided explicitly to override configuration file values.

## Policy Deployment

After building and deploying the package, deploy the policies to Azure:

```powershell
# Deploy both AuditIfNotExists and DeployIfNotExists policies
.\Deploy-Policies-PowerShell.ps1
```

The policies will be created with the following IDs:
- `GG-Audit-SystemAuditPolicies-ObjectAccess` (AuditIfNotExists)
- `GG-Deploy-SystemAuditPolicies-ObjectAccess` (DeployIfNotExists)

## Policy Usage

The DeployIfNotExists policy will:

1. Check if the Guest Configuration assignment exists
2. If not, deploy the assignment with the specified parameters
3. The Guest Configuration agent will apply the audit policy settings
4. Monitor compliance and report status

## Security Considerations

- Enabling "Success" auditing for file operations can generate high volumes of events
- Consider the impact on log storage and performance
- Review audit settings regularly to ensure they meet security requirements

## Troubleshooting

If the Guest Configuration fails to apply:

1. Check that the Guest Configuration extension is installed
2. Verify the VM has internet connectivity to download the package
3. Review Guest Configuration logs in Event Viewer
4. Ensure the VM meets the minimum requirements for Guest Configuration

## Files Structure

```
AzureBaseline_AdministrativeTemplates_MSSLegacy/
├── AzureBaseline_AdministrativeTemplates_MSSLegacy.ps1  # Main DSC configuration
├── Build-And-Deploy-Package.ps1                      # Unified build/deploy script
├── Setup-Prerequisites.ps1                           # Azure resources setup
├── Deploy-GuestConfigurationPackage.ps1              # Azure deployment (legacy)
├── Update-PolicyFiles.ps1                            # Policy file updater (legacy)
├── Fix-GuestConfigurationPackage.ps1                 # Package repair utility
├── Test-Configuration.ps1                            # Local testing script
├── README.md                                          # This documentation
├── SCRIPTS-OVERVIEW.md                                # Script documentation
├── azure-config.json                                 # Generated config file
└── Modules/
    └── AuditPolicyDsc/
        ├── AuditPolicyDsc.psd1
        ├── AuditPolicyDsc.psm1
        └── DSCResources/
            └── AuditPolicySubcategory/
                ├── AuditPolicySubcategory.psd1
                ├── AuditPolicySubcategory.psm1
                └── AuditPolicySubcategory.schema.mof
```

## Common Issues and Solutions

### Build and Package Issues

### "Package metadata is missing or incorrect"
The `Build-And-Deploy-Package.ps1` script automatically fixes common metadata issues:
- Missing `Name` field in `metaconfig.json`
- Missing or empty `ContentHash` field in `metaconfig.json`
- Run with `-Force` to rebuild the package if needed

### "Input provided for ContentUri/ContentHash is invalid"
This Azure validation error can occur during policy remediation. Solutions:
1. **Rebuild the package**: Run `.\Build-And-Deploy-Package.ps1 -Force` to ensure metadata is correct
2. **Verify package accessibility**: Check that the package URL is accessible from Azure
3. **Check hash consistency**: Ensure the `contentHash` in policy files matches the actual package hash
4. **Azure service issues**: This error can sometimes indicate temporary Azure service issues - try again later
5. **Use Fix-GuestConfigurationPackage.ps1**: If package has metadata issues, run this script to repair it

### "Storage account does not exist"
- Run `Setup-Prerequisites.ps1` first, or manually create the storage account
- Ensure you have the correct subscription ID and resource group name

### "Package not found"
- Run `Build-And-Deploy-Package.ps1` before deploying
- Check that the Output directory contains the .zip file

### "Access denied to storage account"
- Ensure you have Contributor or Storage Account Contributor permissions
- Verify the storage account allows blob public access

### Policy Deployment Issues

### "Policy assignments must include a 'managed identity' when assigning 'DeployIfNotExists' policy definitions"
This is expected behavior for DeployIfNotExists policies. When creating policy assignments:
- Use Azure Portal, Azure CLI, or PowerShell with `-AssignIdentity` parameter
- Ensure the managed identity has appropriate permissions

### "Guest Configuration assignment fails"
- Check that the VM has the Guest Configuration extension installed
- Verify the VM has internet connectivity to download packages
- Review Guest Configuration logs in Event Viewer (Windows Logs > Applications and Services Logs > Microsoft > Windows > Guest Configuration)

### Package Validation Issues

### "No report was generated. The package likely was not formed correctly"
This indicates package structure issues:
1. Run `.\Fix-GuestConfigurationPackage.ps1` to repair metadata
2. Rebuild the package with `.\Build-And-Deploy-Package.ps1 -Force`
3. Check that the MOF file is valid and contains expected configuration

### ContentHash Mismatch
If you encounter hash-related errors:
1. The `contentHash` in policy files must match the SHA256 hash of the entire package
2. The `ContentHash` in `metaconfig.json` must match the SHA256 hash of the MOF file
3. Both hashes should be in lowercase hexadecimal format
4. Use the unified script to ensure consistency: `.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles`

### Azure Service Issues
If errors persist despite correct package structure:
- Check Azure Service Health for Guest Configuration service issues
- Try deploying to a different Azure region
- Contact Azure Support for service-specific issues

### Debugging Steps
1. **Verify package structure**: Extract the .zip file and check `metaconfig.json` content
2. **Test package accessibility**: Use `Invoke-WebRequest` to verify the package URL is accessible
3. **Check hash consistency**: Compare package hash with policy file `contentHash`
4. **Review Azure Activity Log**: Check for detailed error messages in Azure portal
5. **Enable verbose logging**: Use `-Verbose` parameter with PowerShell commands

