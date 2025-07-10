# Deploy Guest Configuration Package to Azure Storage
# This script uploads the Guest Configuration package to Azure Storage where it can be referenced by Azure Policy
#
# PREREQUISITES:
# 1. Storage account must exist (this script does NOT create it)
# 2. Required Azure PowerShell modules (Az.Accounts, Az.Storage, GuestConfiguration)
# 3. Appropriate RBAC permissions on the storage account
# 4. Guest Configuration package must be built first
# 
# NOTE: This script uploads the package to Azure Storage. The package URI can then be used in Azure Policy definitions.

param(
    [Parameter(Mandatory = $false, HelpMessage = "Azure Subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Resource Group containing the storage account")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Storage Account name (must exist)")]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Container name for Guest Configuration packages")]
    [string]$ContainerName = "guestconfiguration",
    
    [Parameter(Mandatory = $false, HelpMessage = "Path to the Guest Configuration package")]
    [string]$PackagePath = ".\Output\AzureBaseline_SecurityOptions_Accounts.zip"
)

# Load configuration from azure-config.json if parameters are not provided
$configFile = ".\azure-config.json"
if (Test-Path $configFile) {
    Write-Host "Loading configuration from azure-config.json..." -ForegroundColor Green
    $config = Get-Content $configFile | ConvertFrom-Json
    
    # Use config values if parameters are not provided
    if (-not $SubscriptionId -and $config.SubscriptionId) {
        $SubscriptionId = $config.SubscriptionId
    }
    if (-not $ResourceGroupName -and $config.StorageAccount.ResourceGroupName) {
        $ResourceGroupName = $config.StorageAccount.ResourceGroupName
    }
    if (-not $StorageAccountName -and $config.StorageAccount.Name) {
        $StorageAccountName = $config.StorageAccount.Name
    }
    if (-not $ContainerName -and $config.StorageAccount.ContainerName) {
        $ContainerName = $config.StorageAccount.ContainerName
    }
    
    Write-Host "Configuration loaded:" -ForegroundColor Yellow
    Write-Host "  Subscription ID: $SubscriptionId" -ForegroundColor Gray
    Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Gray
    Write-Host "  Storage Account: $StorageAccountName" -ForegroundColor Gray
    Write-Host "  Container: $ContainerName" -ForegroundColor Gray
} else {
    Write-Warning "Configuration file azure-config.json not found."
}

# Validate required parameters
if (-not $SubscriptionId) {
    throw "SubscriptionId is required. Provide it as parameter or in azure-config.json"
}
if (-not $ResourceGroupName) {
    throw "ResourceGroupName is required. Provide it as parameter or in azure-config.json"
}
if (-not $StorageAccountName) {
    throw "StorageAccountName is required. Provide it as parameter or in azure-config.json"
}

# Import required modules
$requiredModules = @('Az.Accounts', 'Az.Storage', 'GuestConfiguration')
foreach ($module in $requiredModules)
{
    if (-not (Get-Module -ListAvailable -Name $module))
    {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Force -Scope CurrentUser
    }
    Import-Module $module
}

try
{
    # Validate prerequisites
    Write-Host "Validating prerequisites..." -ForegroundColor Green
    
    # Check if package exists
    if (-not (Test-Path $PackagePath))
    {
        throw "Guest Configuration package not found at: $PackagePath`nPlease run Build-GuestConfigurationPackage.ps1 first."
    }
    
    # Use existing Azure session or connect if needed
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        $context = Connect-AzAccount -SubscriptionId $SubscriptionId
        if (-not $context) {
            throw "Failed to connect to Azure. Please check your credentials and subscription ID."
        }
    } else {
        Write-Host "Using existing Azure session: $($context.Account.Id)" -ForegroundColor Green
        if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        }
    }
    
    # Verify storage account exists
    Write-Host "Verifying storage account exists..." -ForegroundColor Green
    try
    {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
        Write-Host "✓ Storage account found: $StorageAccountName" -ForegroundColor Green
    }
    catch
    {
        throw "Storage account '$StorageAccountName' not found in resource group '$ResourceGroupName'.`nPlease create the storage account first. See README.md for instructions."
    }
    
    # Get storage account context
    Write-Host "Getting storage account context..." -ForegroundColor Green
    $ctx = $storageAccount.Context
    
    # Create container if it doesn't exist
    $container = Get-AzStorageContainer -Name $ContainerName -Context $ctx -ErrorAction SilentlyContinue
    if (-not $container)
    {
        Write-Host "Creating container: $ContainerName" -ForegroundColor Yellow
        New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob
    }
    
    # Upload the package
    Write-Host "Uploading Guest Configuration package..." -ForegroundColor Green
    $packageName = Split-Path $PackagePath -Leaf
    try
    {
        $blob = Set-AzStorageBlobContent -File $PackagePath -Container $ContainerName -Blob $packageName -Context $ctx -Force
        Write-Host "✓ Package uploaded successfully" -ForegroundColor Green
    }
    catch
    {
        throw "Failed to upload package to storage account: $($_.Exception.Message)"
    }
    
    # Get the package URI
    $packageUri = $blob.ICloudBlob.StorageUri.PrimaryUri.ToString()
    Write-Host "✓ Package uploaded successfully" -ForegroundColor Green
    Write-Host "Package URI: $packageUri" -ForegroundColor Yellow
    
    Write-Host "Guest Configuration package deployment completed!" -ForegroundColor Green
    Write-Host "The package is now available in Azure Storage and ready for use in policies." -ForegroundColor Cyan
    
    # Output the information needed for the policy
    Write-Host "`n=== Policy Configuration Information ===" -ForegroundColor Magenta
    Write-Host "Use these values in your Azure Policy:" -ForegroundColor White
    Write-Host "  Package URI: $packageUri" -ForegroundColor Yellow
    Write-Host "  Configuration Name: AzureBaseline_SecurityOptions_Accounts" -ForegroundColor Yellow
    Write-Host "  Configuration Version: 1.*" -ForegroundColor Yellow
    
    Write-Host "`n=== Next Steps ===" -ForegroundColor Magenta
    Write-Host "1. Update your Azure Policy JSON files to reference this package URI" -ForegroundColor White
    Write-Host "2. Import the policy definitions into Azure Portal or via Azure CLI/PowerShell" -ForegroundColor White
    Write-Host "3. Assign the policies to your desired scope (subscription/resource group)" -ForegroundColor White
    Write-Host "4. Configure policy parameters as needed" -ForegroundColor White
    
    Write-Host "`n=== Example Policy URI Update ===" -ForegroundColor Magenta
    Write-Host "In your policy JSON files, update the 'contentUri' field to:" -ForegroundColor White
    Write-Host "  `"contentUri`": `"$packageUri`"" -ForegroundColor Yellow
}
catch
{
    Write-Error "Failed to deploy Guest Configuration package: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nDeployment completed!" -ForegroundColor Green


