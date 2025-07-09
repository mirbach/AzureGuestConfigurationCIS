# Build and Publish Guest Configuration Package Script
# This script creates and publishes the Guest Configuration package directly to Azure Storage

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Output",
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

# Import required modules
$requiredModules = @('GuestConfiguration', 'Az.Accounts', 'Az.Storage')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Force -Scope CurrentUser
    }
    Import-Module $module
}

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Green
$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
}

# Set paths
$configurationPath = ".\AzureBaseline_SystemAuditPoliciesObjectAccess.ps1"
$outputPath = $OutputPath

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force
}

# Compile the configuration
Write-Host "Compiling DSC configuration..." -ForegroundColor Green

try {
    # Load the configuration
    . $configurationPath

    # Create the configuration with default parameters for package creation
    $configData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowPlainTextPassword = $true
            }
        )
    }

    # Compile the configuration
    $compiledConfig = AzureBaseline_SystemAuditPoliciesObjectAccess -OutputPath $outputPath -ConfigurationData $configData
    Write-Host "✓ Configuration compiled successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to compile DSC configuration: $($_.Exception.Message)"
    exit 1
}

# Find the generated .mof file
$mofFile = Get-ChildItem -Path $outputPath -Filter "*.mof" | Select-Object -First 1
if (-not $mofFile) {
    Write-Error "No .mof file found in output directory: $outputPath"
    exit 1
}

Write-Host "Using MOF file: $($mofFile.FullName)" -ForegroundColor Cyan

# Create and publish the package directly to Azure Storage
Write-Host "Creating and publishing Guest Configuration package..." -ForegroundColor Green

try {
    $publishResult = Publish-GuestConfigurationPackage -Path $mofFile.FullName -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageContainerName "guestconfiguration" -Force
    
    Write-Host "✓ Package published successfully" -ForegroundColor Green
    Write-Host "Package URI: $($publishResult.ContentUri)" -ForegroundColor Yellow
    Write-Host "Package ContentHash: $($publishResult.ContentHash)" -ForegroundColor Yellow
    
    # Save the package information for policy updates
    $packageInfo = @{
        Name = "AzureBaseline_SystemAuditPoliciesObjectAccess"
        Version = "1.0.0.0"
        ContentUri = $publishResult.ContentUri
        ContentHash = $publishResult.ContentHash
        CreatedDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    }
    
    $packageInfo | ConvertTo-Json | Out-File -FilePath ".\azure-package.json" -Encoding UTF8
    Write-Host "✓ Package information saved to azure-package.json" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to publish Guest Configuration package: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nPackage creation and publishing completed!" -ForegroundColor Green
Write-Host "Use the following information in your Azure Policies:" -ForegroundColor Magenta
Write-Host "  Content URI: $($publishResult.ContentUri)" -ForegroundColor White
Write-Host "  Content Hash: $($publishResult.ContentHash)" -ForegroundColor White
Write-Host "  Version: 1.0.0.0" -ForegroundColor White
