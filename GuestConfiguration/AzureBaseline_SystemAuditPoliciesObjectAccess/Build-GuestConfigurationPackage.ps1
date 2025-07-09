# Build Guest Configuration Package Script
# This script creates the Guest Configuration package for the AzureBaseline_SystemAuditPoliciesObjectAccess configuration

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Output"
)

# Import required modules
if (-not (Get-Module -ListAvailable -Name GuestConfiguration))
{
    Install-Module -Name GuestConfiguration -Force -Scope CurrentUser
}

Import-Module GuestConfiguration

# Set paths
$configurationPath = ".\AzureBaseline_SystemAuditPoliciesObjectAccess.ps1"
$outputPath = $OutputPath

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath))
{
    New-Item -Path $outputPath -ItemType Directory -Force
}

# Compile the configuration
Write-Host "Compiling DSC configuration..." -ForegroundColor Green

try 
{
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
}
catch 
{
    Write-Error "Failed to compile DSC configuration: $($_.Exception.Message)"
    Write-Host "Error details: $($_.Exception)" -ForegroundColor Red
    exit 1
}

# Create Guest Configuration package
Write-Host "Creating Guest Configuration package..." -ForegroundColor Green

# Find the generated .mof file (DSC generates localhost.mof by default)
$mofFile = Get-ChildItem -Path $outputPath -Filter "*.mof" | Select-Object -First 1
if (-not $mofFile) {
    Write-Error "No .mof file found in output directory: $outputPath"
    exit 1
}

Write-Host "Using MOF file: $($mofFile.FullName)" -ForegroundColor Cyan

# Create the package with verbose output
Write-Host "Creating Guest Configuration package with Name: 'AzureBaseline_SystemAuditPoliciesObjectAccess', Version: '1.0.0.0'" -ForegroundColor Cyan
$packagePath = New-GuestConfigurationPackage -Name 'AzureBaseline_SystemAuditPoliciesObjectAccess' -Configuration $mofFile.FullName -Path $outputPath -Type AuditAndSet -Version '1.0.0.0' -Force -Verbose

Write-Host "Guest Configuration package created at: $packagePath" -ForegroundColor Yellow

# Verify package contents
Write-Host "Verifying package contents..." -ForegroundColor Green
$tempVerifyDir = New-TemporaryFile; Remove-Item $tempVerifyDir; $tempVerifyDir = New-Item -ItemType Directory -Path $tempVerifyDir.FullName
Expand-Archive -Path $packagePath.Path -DestinationPath $tempVerifyDir
$metaConfigContent = Get-Content "$tempVerifyDir\*.metaconfig.json" | ConvertFrom-Json
Write-Host "Package Name: $($metaConfigContent.Name)" -ForegroundColor Yellow
Write-Host "Package Version: $($metaConfigContent.Version)" -ForegroundColor Yellow
Write-Host "Package ContentHash: $($metaConfigContent.ContentHash)" -ForegroundColor Yellow
Remove-Item -Recurse -Force $tempVerifyDir

# Test the package (optional)
Write-Host "Testing Guest Configuration package..." -ForegroundColor Green
try
{
    if (Get-Command Test-GuestConfigurationPackage -ErrorAction SilentlyContinue) {
        $testResult = Test-GuestConfigurationPackage -Path $packagePath.Path
        Write-Host "Package test result: $($testResult.Valid)" -ForegroundColor $(if ($testResult.Valid) { 'Green' } else { 'Red' })
    } else {
        Write-Host "Test-GuestConfigurationPackage cmdlet not available - skipping package validation" -ForegroundColor Yellow
    }
}
catch
{
    Write-Warning "Package test failed: $($_.Exception.Message)"
}

Write-Host "Build completed!" -ForegroundColor Green
Write-Host "Package location: $($packagePath.Path)" -ForegroundColor Yellow
Write-Host "Package size: $([math]::Round((Get-Item $packagePath.Path).Length / 1KB, 2)) KB" -ForegroundColor Yellow
