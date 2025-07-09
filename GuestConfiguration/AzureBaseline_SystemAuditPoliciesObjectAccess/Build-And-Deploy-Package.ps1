# Build and Deploy Guest Configuration Package Script
# This script creates the Guest Configuration package and optionally deploys it to Azure Storage

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Output",
    
    [Parameter(Mandatory = $false, HelpMessage = "Deploy to Azure Storage after building")]
    [switch]$Deploy,
    
    [Parameter(Mandatory = $false, HelpMessage = "Update policy files with new ContentHash")]
    [switch]$UpdatePolicyFiles,
    
    [Parameter(Mandatory = $false, HelpMessage = "Azure Subscription ID (required if Deploy is used)")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Resource Group Name (required if Deploy is used)")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Storage Account Name (required if Deploy is used)")]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Force rebuild even if package exists")]
    [switch]$Force
)

# Configuration name
$configName = "AzureBaseline_SystemAuditPoliciesObjectAccess"

Write-Host "=== Guest Configuration Package Builder ===" -ForegroundColor Magenta
Write-Host "Configuration: $configName" -ForegroundColor Cyan

# Import required modules for building
$requiredModules = @('GuestConfiguration')
if ($Deploy) {
    $requiredModules += @('Az.Accounts', 'Az.Storage')
}

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Force -Scope CurrentUser
    }
    Import-Module $module -Force
}

# Set paths
$configurationPath = ".\$configName.ps1"
$outputPath = $OutputPath

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Check if package already exists and Force is not specified
$packageFile = "$outputPath\$configName.zip"
if ((Test-Path $packageFile) -and -not $Force) {
    Write-Host "Package already exists at: $packageFile" -ForegroundColor Yellow
    Write-Host "Use -Force to rebuild or proceed with deployment..." -ForegroundColor Yellow
} else {
    # Build the package
    Write-Host "Building Guest Configuration package..." -ForegroundColor Green
    
    # Compile the configuration
    Write-Host "  Compiling DSC configuration..." -ForegroundColor Cyan
    
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
        $compiledConfig = & $configName -OutputPath $outputPath -ConfigurationData $configData
        Write-Host "  ✓ Configuration compiled successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to compile DSC configuration: $($_.Exception.Message)"
        exit 1
    }

    # Create Guest Configuration package
    Write-Host "  Creating Guest Configuration package..." -ForegroundColor Cyan

    # Find the generated .mof file
    $mofFile = Get-ChildItem -Path $outputPath -Filter "*.mof" | Select-Object -First 1
    if (-not $mofFile) {
        Write-Error "No .mof file found in output directory: $outputPath"
        exit 1
    }

    # Create the package
    try {
        $packagePath = New-GuestConfigurationPackage -Name $configName -Configuration $mofFile.FullName -Path $outputPath -Type AuditAndSet -Version '1.0.0.0' -Force
        Write-Host "  ✓ Package created successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create Guest Configuration package: $($_.Exception.Message)"
        exit 1
    }
}

# Calculate package hash
$hash = Get-FileHash -Path $packageFile -Algorithm SHA256
Write-Host "Package Information:" -ForegroundColor Green
Write-Host "  Location: $packageFile" -ForegroundColor White
Write-Host "  Size: $([math]::Round((Get-Item $packageFile).Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host "  SHA256: $($hash.Hash)" -ForegroundColor Yellow

# Deploy to Azure Storage if requested
if ($Deploy) {
    if (-not $ResourceGroupName -or -not $StorageAccountName) {
        Write-Error "ResourceGroupName and StorageAccountName are required when using -Deploy"
        exit 1
    }
    
    Write-Host "Deploying to Azure Storage..." -ForegroundColor Green
    
    # Connect to Azure
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
    
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
    
    # Use the existing deployment script
    try {
        & ".\Deploy-GuestConfigurationPackage.ps1" -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $packageUri = "https://$StorageAccountName.blob.core.windows.net/guestconfiguration/$configName.zip"
        Write-Host "  ✓ Package deployed to Azure Storage" -ForegroundColor Green
        Write-Host "  Package URI: $packageUri" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to deploy package to Azure Storage: $($_.Exception.Message)"
        exit 1
    }
}

# Update policy files if requested
if ($UpdatePolicyFiles) {
    if (-not $Deploy) {
        Write-Warning "UpdatePolicyFiles requires Deploy to be enabled. Package URI will be assumed."
        if (-not $StorageAccountName) {
            Write-Error "StorageAccountName is required when updating policy files"
            exit 1
        }
        $packageUri = "https://$StorageAccountName.blob.core.windows.net/guestconfiguration/$configName.zip"
    }
    
    Write-Host "Updating policy files..." -ForegroundColor Green
    
    try {
        & ".\Update-PolicyFiles.ps1" -PackageUri $packageUri -ContentHash $hash.Hash
        Write-Host "  ✓ Policy files updated with new ContentHash" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update policy files: $($_.Exception.Message)"
        exit 1
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Magenta
Write-Host "✓ Package built: $packageFile" -ForegroundColor Green
if ($Deploy) {
    Write-Host "✓ Package deployed to Azure Storage" -ForegroundColor Green
}
if ($UpdatePolicyFiles) {
    Write-Host "✓ Policy files updated" -ForegroundColor Green
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
if (-not $Deploy) {
    Write-Host "- Run with -Deploy to upload to Azure Storage" -ForegroundColor White
}
if (-not $UpdatePolicyFiles) {
    Write-Host "- Run with -UpdatePolicyFiles to update policy JSON files" -ForegroundColor White
}
Write-Host "- Deploy policies using Deploy-Policies-PowerShell.ps1" -ForegroundColor White
Write-Host "- Assign policies in Azure Portal" -ForegroundColor White
