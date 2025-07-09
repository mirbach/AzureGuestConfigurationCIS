# Guest Configuration Scripts Overview

This directory contains scripts for managing the AzureBaseline_SystemAuditPoliciesObjectAccess Guest Configuration package.

## Main Scripts

### 🔧 Build-And-Deploy-Package.ps1 (RECOMMENDED)
**Comprehensive script that handles the complete workflow:**
- Builds the Guest Configuration package locally
- Optionally deploys to Azure Storage
- Optionally updates policy JSON files with new ContentHash
- Provides flexible parameters for different scenarios

**Usage Examples:**
```powershell
# Build only
.\Build-And-Deploy-Package.ps1

# Build and deploy to Azure
.\Build-And-Deploy-Package.ps1 -Deploy -SubscriptionId "xxx" -ResourceGroupName "xxx" -StorageAccountName "xxx"

# Complete workflow: Build + Deploy + Update policies
.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles -SubscriptionId "xxx" -ResourceGroupName "xxx" -StorageAccountName "xxx"

# Force rebuild
.\Build-And-Deploy-Package.ps1 -Force
```

## Supporting Scripts

### 📤 Deploy-GuestConfigurationPackage.ps1
Uploads a pre-built package to Azure Storage. Used internally by Build-And-Deploy-Package.ps1.

### 🔄 Update-PolicyFiles.ps1
Updates Azure Policy JSON files with new package URI and ContentHash. Used internally by Build-And-Deploy-Package.ps1.

### 🧪 Test-Configuration.ps1
Tests the Guest Configuration package on the local machine.

### ⚙️ Setup-Prerequisites.ps1
Installs required PowerShell modules and dependencies.

## Workflow

1. **Build & Deploy**: `.\Build-And-Deploy-Package.ps1 -Deploy -UpdatePolicyFiles ...`
2. **Test Locally**: `.\Test-Configuration.ps1`
3. **Deploy Policies**: `..\..\Deploy-Policies-PowerShell.ps1`
4. **Assign in Azure Portal**

## Configuration Files

- `AzureBaseline_SystemAuditPoliciesObjectAccess.ps1` - DSC Configuration
- `azure-config.json` - Azure deployment metadata
- `Output/` - Generated packages and MOF files
- `Modules/` - Custom DSC resources
