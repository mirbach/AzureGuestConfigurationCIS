# Update Content Hashes for Guest Configuration Packages
# This script calculates the actual SHA256 hash of each Guest Configuration package
# and updates the azure-config.json files with the real hash values.

param(
    [Parameter(Mandatory = $false, HelpMessage = "Specific policy folder to update (updates all if not specified)")]
    [string]$PolicyFolder = $null
)

function Get-FileHash256 {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    return $hash.Hash
}

function Update-AzureConfigHash {
    param(
        [string]$AzureConfigPath,
        [string]$PackagePath
    )
    
    if (-not (Test-Path $AzureConfigPath)) {
        Write-Warning "azure-config.json not found: $AzureConfigPath"
        return $false
    }
    
    if (-not (Test-Path $PackagePath)) {
        Write-Warning "Package file not found: $PackagePath"
        return $false
    }
    
    try {
        # Calculate the actual hash
        $actualHash = Get-FileHash256 -FilePath $PackagePath
        
        # Load the current config
        $config = Get-Content $AzureConfigPath | ConvertFrom-Json
        
        # Update the hash
        $oldHash = $config.Package.CurrentContentHash
        $config.Package.CurrentContentHash = $actualHash
        
        # Save the updated config
        $config | ConvertTo-Json -Depth 10 | Out-File $AzureConfigPath -Encoding UTF8
        
        Write-Host "  ✓ Updated hash: $($oldHash) → $($actualHash.Substring(0,16))..." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to update hash for $AzureConfigPath`: $($_.Exception.Message)"
        return $false
    }
}

Write-Host "=== Guest Configuration Content Hash Updater ===" -ForegroundColor Cyan
Write-Host "This script calculates and updates the SHA256 content hashes for Guest Configuration packages.`n" -ForegroundColor White

$outputDir = ".\Output"
if (-not (Test-Path $outputDir)) {
    Write-Error "Output directory not found: $outputDir"
    exit 1
}

$successCount = 0
$failureCount = 0

# Get list of policy folders to process
if ($PolicyFolder) {
    $policyFolders = @(Get-ChildItem $outputDir -Directory | Where-Object { $_.Name -eq $PolicyFolder })
    if ($policyFolders.Count -eq 0) {
        Write-Error "Policy folder not found: $PolicyFolder"
        exit 1
    }
} else {
    $policyFolders = Get-ChildItem $outputDir -Directory
}

Write-Host "Processing $($policyFolders.Count) policy folders...`n" -ForegroundColor Yellow

foreach ($folder in $policyFolders) {
    Write-Host "Processing: $($folder.Name)" -ForegroundColor Cyan
    
    # Find the Guest Configuration directory
    $gcDir = Get-ChildItem (Join-Path $folder.FullName "GuestConfiguration") -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gcDir) {
        Write-Warning "  No GuestConfiguration directory found"
        $failureCount++
        continue
    }
    
    # Find the azure-config.json file
    $azureConfigPath = Join-Path $gcDir.FullName "azure-config.json"
    if (-not (Test-Path $azureConfigPath)) {
        Write-Warning "  azure-config.json not found"
        $failureCount++
        continue
    }
    
    # Find the package file
    $packageFiles = Get-ChildItem (Join-Path $gcDir.FullName "Output") -Filter "*.zip" -ErrorAction SilentlyContinue
    if ($packageFiles.Count -eq 0) {
        Write-Warning "  No package (.zip) files found in Output directory"
        $failureCount++
        continue
    }
    
    $packagePath = $packageFiles[0].FullName
    Write-Host "  Package: $($packageFiles[0].Name)" -ForegroundColor Gray
    
    # Update the hash
    if (Update-AzureConfigHash -AzureConfigPath $azureConfigPath -PackagePath $packagePath) {
        $successCount++
    } else {
        $failureCount++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Magenta
Write-Host "Successfully updated: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor Red

if ($failureCount -eq 0) {
    Write-Host "`n✓ All content hashes have been updated successfully!" -ForegroundColor Green
    Write-Host "The azure-config.json files now contain the actual SHA256 hashes of the packages." -ForegroundColor White
} else {
    Write-Host "`n⚠ Some packages failed to update. Please check the warnings above." -ForegroundColor Yellow
}
