# Fix Guest Configuration Package Metadata
# This script fixes the metaconfig.json file in the Guest Configuration package

param(
    [Parameter(Mandatory = $false)]
    [string]$PackagePath = ".\Output\AzureBaseline_SecurityOptions_Shutdown.zip",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigurationName = "AzureBaseline_SecurityOptions_Shutdown"
)

Write-Host "Fixing Guest Configuration package metadata..." -ForegroundColor Green

if (-not (Test-Path $PackagePath)) {
    Write-Error "Package not found at: $PackagePath"
    exit 1
}

# Create temporary directory
$tempDir = New-TemporaryFile
Remove-Item $tempDir
$tempDir = New-Item -ItemType Directory -Path $tempDir.FullName

try {
    # Extract the package
    Write-Host "Extracting package..." -ForegroundColor Cyan
    Expand-Archive -Path $PackagePath -DestinationPath $tempDir -Force
    
    # Find the metaconfig.json file
    $metaConfigFile = Get-ChildItem -Path $tempDir -Filter "*.metaconfig.json" | Select-Object -First 1
    if (-not $metaConfigFile) {
        Write-Error "metaconfig.json not found in package"
        exit 1
    }
    
    Write-Host "Found metaconfig file: $($metaConfigFile.Name)" -ForegroundColor Cyan
    
    # Read current metadata
    $metaConfig = Get-Content $metaConfigFile.FullName | ConvertFrom-Json
    Write-Host "Current metadata:" -ForegroundColor Yellow
    Write-Host "  Type: $($metaConfig.Type)" -ForegroundColor White
    Write-Host "  Version: $($metaConfig.Version)" -ForegroundColor White
    Write-Host "  Name: '$($metaConfig.Name)'" -ForegroundColor White
    Write-Host "  ContentHash: '$($metaConfig.ContentHash)'" -ForegroundColor White
    
    # Calculate content hash of the MOF file
    $mofFile = Get-ChildItem -Path $tempDir -Filter "*.mof" | Select-Object -First 1
    if ($mofFile) {
        $mofHash = Get-FileHash -Path $mofFile.FullName -Algorithm SHA256
        Write-Host "MOF file hash: $($mofHash.Hash)" -ForegroundColor Cyan
    }
    
    # Update metadata with proper values
    $metaConfig | Add-Member -Name "Name" -Value $ConfigurationName -MemberType NoteProperty -Force
    
    # Set ContentHash to MOF file hash (this is required for Azure Guest Configuration)
    if ($mofFile) {
        $metaConfig | Add-Member -Name "ContentHash" -Value $mofHash.Hash.ToLower() -MemberType NoteProperty -Force
    } else {
        $metaConfig | Add-Member -Name "ContentHash" -Value "" -MemberType NoteProperty -Force
    }
    
    Write-Host "Updated metadata:" -ForegroundColor Green
    Write-Host "  Type: $($metaConfig.Type)" -ForegroundColor White
    Write-Host "  Version: $($metaConfig.Version)" -ForegroundColor White
    Write-Host "  Name: '$($metaConfig.Name)'" -ForegroundColor White
    Write-Host "  ContentHash: '$($metaConfig.ContentHash)'" -ForegroundColor White
    
    # Write updated metadata
    $metaConfig | ConvertTo-Json -Depth 10 | Set-Content $metaConfigFile.FullName -Encoding UTF8
    
    # Create backup of original package
    $backupPath = $PackagePath -replace '\.zip$', '_backup.zip'
    Copy-Item $PackagePath $backupPath
    Write-Host "Backup created: $backupPath" -ForegroundColor Yellow
    
    # Remove original package
    Remove-Item $PackagePath
    
    # Recreate package with fixed metadata
    Write-Host "Recreating package with fixed metadata..." -ForegroundColor Cyan
    Compress-Archive -Path "$tempDir\*" -DestinationPath $PackagePath -Force
    
    # Calculate new package hash
    $newHash = Get-FileHash -Path $PackagePath -Algorithm SHA256
    Write-Host "Package fixed successfully!" -ForegroundColor Green
    Write-Host "New package hash: $($newHash.Hash)" -ForegroundColor Yellow
    Write-Host "Package location: $PackagePath" -ForegroundColor White
    
}
finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
}

Write-Host "`nNext steps:" -ForegroundColor Magenta
Write-Host "1. Re-upload package to Azure Storage" -ForegroundColor White
Write-Host "2. Update policy files with new ContentHash" -ForegroundColor White
Write-Host "3. Deploy updated policies" -ForegroundColor White

