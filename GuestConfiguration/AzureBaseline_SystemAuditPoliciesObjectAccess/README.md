# Azure Guest Configuration - System Audit Policies Object Access

This Guest Configuration package configures Windows audit policies for Object Access subcategories including File System, File Share, and Detailed File Share auditing.

## Contents

- **AzureBaseline_SystemAuditPoliciesObjectAccess.ps1**: Main PowerShell DSC configuration
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

2. **Build the Guest Configuration package:**
```powershell
.\Build-GuestConfigurationPackage.ps1
```

3. **Deploy to Azure:**
```powershell
# Use the saved configuration from step 1
$config = Get-Content ".\azure-config.json" | ConvertFrom-Json
.\Deploy-GuestConfigurationPackage.ps1 -SubscriptionId $config.SubscriptionId -ResourceGroupName $config.ResourceGroupName -StorageAccountName $config.StorageAccountName
```

4. **Update policy files with package URI:**
```powershell
# After deployment, update the policy JSON files with the package URI
.\Update-PolicyFiles.ps1 -PackageUri "https://yourstorageaccount.blob.core.windows.net/guestconfiguration/AzureBaseline_SystemAuditPoliciesObjectAccess.zip"
```

Note: The policy files use prefixes to clearly identify their type:
- `[AuditIfNotExists] Windows machines should meet requirements...` - Audit-only policy
- `[DeployIfNotExists] Windows machines should meet requirements...` - Deployment policy
The display names within the files include [GG Serverhardening] to distinguish them from built-in Microsoft policies.

### Option 2: Manual Setup

1. **Create storage account manually** (see prerequisites section above)
2. **Build the package:**

2. **Build the package:**
```powershell
.\Build-GuestConfigurationPackage.ps1
```

3. **Deploy to Azure:**
```powershell
.\Deploy-GuestConfigurationPackage.ps1 -SubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -StorageAccountName "your-storage-account"
```

4. **Update policy files with package URI:**
```powershell
# Copy the package URI from the deployment output and update policy files
.\Update-PolicyFiles.ps1 -PackageUri "https://yourstorageaccount.blob.core.windows.net/guestconfiguration/AzureBaseline_SystemAuditPoliciesObjectAccess.zip"
```

## Package Building Details

The build script will:
- Compile the DSC configuration
- Create the Guest Configuration package
- Test the package validity

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
AzureBaseline_SystemAuditPoliciesObjectAccess/
├── AzureBaseline_SystemAuditPoliciesObjectAccess.ps1  # Main DSC configuration
├── Build-GuestConfigurationPackage.ps1               # Package builder
├── Setup-Prerequisites.ps1                           # Azure resources setup
├── Deploy-GuestConfigurationPackage.ps1              # Azure deployment
├── Test-Configuration.ps1                            # Local testing script
├── README.md                                          # This documentation
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

### "Storage account does not exist"
- Run `Setup-Prerequisites.ps1` first, or manually create the storage account
- Ensure you have the correct subscription ID and resource group name

### "Package not found"
- Run `Build-GuestConfigurationPackage.ps1` before deploying
- Check that the Output directory contains the .zip file

### "Access denied to storage account"
- Ensure you have Contributor or Storage Account Contributor permissions
- Verify the storage account allows blob public access

### "Guest Configuration assignment fails"
- Check that the VM has the Guest Configuration extension installed
- Verify the VM has internet connectivity to download packages
- Review Guest Configuration logs in Event Viewer (Windows Logs > Applications and Services Logs > Microsoft > Windows > Guest Configuration)
