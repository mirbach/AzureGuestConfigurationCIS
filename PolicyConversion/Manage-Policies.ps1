# Manage Azure Guest Configuration Policies
# This script provides functions to deploy, remove, get, and manage Azure Guest Configuration policies

param(
    [Parameter(Mandatory = $false, HelpMessage = "Deploy all policies to Azure")]
    [switch]$DeployPolicies,
    
    [Parameter(Mandatory = $false, HelpMessage = "Remove all policies from Azure")]
    [switch]$RemovePolicies,
    
    [Parameter(Mandatory = $false, HelpMessage = "Get policies from Azure")]
    [switch]$GetPolicies,
    
    [Parameter(Mandatory = $false, HelpMessage = "Remove policy assignments from Azure")]
    [switch]$RemoveAssignments,
    
    [Parameter(Mandatory = $false, HelpMessage = "Build all DSC packages")]
    [switch]$BuildDSCPackages,
    
    [Parameter(Mandatory = $false, HelpMessage = "Update policy files with correct DSC package hashes")]
    [switch]$UpdateHashes,
    
    [Parameter(Mandatory = $false, HelpMessage = "Upload DSC packages to Azure Storage")]
    [switch]$UploadPackages,
    
    [Parameter(Mandatory = $false, HelpMessage = "Specific policy name to manage")]
    [string]$PolicyName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Resource Group Name")]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Force rebuild/overwrite")]
    [switch]$Force
)

# Load Azure configuration
$azureConfigFile = Join-Path $PSScriptRoot "..\azure.config"
if (Test-Path $azureConfigFile) {
    . $azureConfigFile
    Write-Host "Loaded Azure configuration from azure.config" -ForegroundColor Green
} else {
    Write-Warning "Azure configuration file not found. Please create azure.config with required variables."
    return
}

# Use provided parameters or fall back to config file values
if (-not $SubscriptionId) { $SubscriptionId = $AzureSubscriptionId }
if (-not $ResourceGroupName) { $ResourceGroupName = $AzureResourceGroupName }

# Function to deploy policies to Azure
function Deploy-Policies {
    param(
        [string]$OutputPath,
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Deploying Guest Configuration Policies ===" -ForegroundColor Magenta
    
    try {
        # Connect to Azure
        Connect-AzAccount -SubscriptionId $SubscriptionId
        Set-AzContext -SubscriptionId $SubscriptionId
        
        # Get policy directories
        $policyDirs = if ($SpecificPolicy) {
            Get-ChildItem $OutputPath -Directory | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        } else {
            Get-ChildItem $OutputPath -Directory
        }
        
        foreach ($policyDir in $policyDirs) {
            Write-Host "Processing policy directory: $($policyDir.Name)" -ForegroundColor Cyan
            
            # Find policy JSON files
            $auditPolicy = Get-ChildItem $policyDir.FullName -Filter "AuditIfNotExists*.json" -File | Select-Object -First 1
            $deployPolicy = Get-ChildItem $policyDir.FullName -Filter "DeployIfNotExists*.json" -File | Select-Object -First 1
            
            if ($auditPolicy) {
                $auditPolicyContent = Get-Content $auditPolicy.FullName | ConvertFrom-Json
                $auditPolicyName = "GG-Audit-" + ($auditPolicyContent.properties.displayName -replace '\[.*?\]\s*', '' -replace '[^a-zA-Z0-9\-_]', '')
                
                Write-Host "  Deploying Audit Policy: $auditPolicyName" -ForegroundColor Yellow
                try {
                    New-AzPolicyDefinition -Name $auditPolicyName -Policy $auditPolicy.FullName -Mode Indexed
                    Write-Host "  ✓ Audit policy deployed successfully" -ForegroundColor Green
                } catch {
                    Write-Warning "  Failed to deploy audit policy: $($_.Exception.Message)"
                }
            }
            
            if ($deployPolicy) {
                $deployPolicyContent = Get-Content $deployPolicy.FullName | ConvertFrom-Json
                $deployPolicyName = "GG-Deploy-" + ($deployPolicyContent.properties.displayName -replace '\[.*?\]\s*', '' -replace '[^a-zA-Z0-9\-_]', '')
                
                Write-Host "  Deploying Deploy Policy: $deployPolicyName" -ForegroundColor Yellow
                try {
                    New-AzPolicyDefinition -Name $deployPolicyName -Policy $deployPolicy.FullName -Mode Indexed
                    Write-Host "  ✓ Deploy policy deployed successfully" -ForegroundColor Green
                } catch {
                    Write-Warning "  Failed to deploy deploy policy: $($_.Exception.Message)"
                }
            }
        }
        
        Write-Host "=== Policy Deployment Complete ===" -ForegroundColor Green
    } catch {
        Write-Error "Failed to deploy policies: $($_.Exception.Message)"
    }
}

# Function to remove policies from Azure
function Remove-Policies {
    param(
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Removing Guest Configuration Policies ===" -ForegroundColor Magenta
    
    try {
        # Connect to Azure
        Connect-AzAccount -SubscriptionId $SubscriptionId
        Set-AzContext -SubscriptionId $SubscriptionId
        
        # Get all policy definitions
        $policies = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -like "*GG Serverhardening*" }
        
        if ($SpecificPolicy) {
            $policies = $policies | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        }
        
        foreach ($policy in $policies) {
            Write-Host "Removing policy: $($policy.Name)" -ForegroundColor Yellow
            try {
                Remove-AzPolicyDefinition -Id $policy.PolicyDefinitionId -Force
                Write-Host "  ✓ Policy removed successfully" -ForegroundColor Green
            } catch {
                Write-Warning "  Failed to remove policy: $($_.Exception.Message)"
            }
        }
        
        Write-Host "=== Policy Removal Complete ===" -ForegroundColor Green
    } catch {
        Write-Error "Failed to remove policies: $($_.Exception.Message)"
    }
}

# Function to get policies from Azure
function Get-Policies {
    param(
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Getting Guest Configuration Policies ===" -ForegroundColor Magenta
    
    try {
        # Connect to Azure
        Connect-AzAccount -SubscriptionId $SubscriptionId
        Set-AzContext -SubscriptionId $SubscriptionId
        
        # Get all policy definitions
        $policies = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -like "*GG Serverhardening*" }
        
        if ($SpecificPolicy) {
            $policies = $policies | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        }
        
        Write-Host "Found $($policies.Count) Guest Configuration policies:" -ForegroundColor Cyan
        
        foreach ($policy in $policies) {
            Write-Host "  - $($policy.Name)" -ForegroundColor Yellow
            Write-Host "    Display Name: $($policy.Properties.DisplayName)" -ForegroundColor Gray
            Write-Host "    Policy Type: $($policy.Properties.PolicyType)" -ForegroundColor Gray
            Write-Host "    Category: $($policy.Properties.Metadata.category)" -ForegroundColor Gray
            Write-Host ""
        }
        
        return $policies
    } catch {
        Write-Error "Failed to get policies: $($_.Exception.Message)"
    }
}

# Function to remove policy assignments from Azure
function Remove-PolicyAssignments {
    param(
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Removing Policy Assignments ===" -ForegroundColor Magenta
    
    try {
        # Connect to Azure
        Connect-AzAccount -SubscriptionId $SubscriptionId
        Set-AzContext -SubscriptionId $SubscriptionId
        
        # Get all policy assignments
        $assignments = Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*GG Serverhardening*" }
        
        if ($SpecificPolicy) {
            $assignments = $assignments | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        }
        
        foreach ($assignment in $assignments) {
            Write-Host "Removing assignment: $($assignment.Name)" -ForegroundColor Yellow
            try {
                Remove-AzPolicyAssignment -Id $assignment.PolicyAssignmentId
                Write-Host "  ✓ Assignment removed successfully" -ForegroundColor Green
            } catch {
                Write-Warning "  Failed to remove assignment: $($_.Exception.Message)"
            }
        }
        
        Write-Host "=== Assignment Removal Complete ===" -ForegroundColor Green
    } catch {
        Write-Error "Failed to remove assignments: $($_.Exception.Message)"
    }
}

# Function to build DSC packages
function Build-DSCPackages {
    param(
        [string]$OutputPath,
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Building DSC Packages ===" -ForegroundColor Magenta
    
    try {
        # Check if GuestConfiguration module is available
        if (-not (Get-Module -ListAvailable -Name GuestConfiguration)) {
            Write-Host "Installing GuestConfiguration module..." -ForegroundColor Yellow
            Install-Module -Name GuestConfiguration -Force -AllowClobber
        }
        
        # Import required modules
        Import-Module GuestConfiguration -Force
        
        $policyDirs = if ($SpecificPolicy) {
            Get-ChildItem -Path $OutputPath -Directory | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        } else {
            Get-ChildItem -Path $OutputPath -Directory
        }
        
        foreach ($policyDir in $policyDirs) {
            $configDir = Get-ChildItem -Path $policyDir.FullName -Directory -Filter "GuestConfiguration" -ErrorAction SilentlyContinue
            if ($configDir) {
                $dscConfigDir = Get-ChildItem -Path $configDir.FullName -Directory | Select-Object -First 1
                if ($dscConfigDir) {
                    Write-Host "Building package for: $($policyDir.Name)" -ForegroundColor Cyan
                    
                    $configPath = Join-Path $dscConfigDir.FullName "*.ps1"
                    $configFile = Get-ChildItem -Path $configPath | Select-Object -First 1
                    
                    if ($configFile) {
                        try {
                            # First, compile the DSC configuration to create .mof file
                            Write-Host "  Compiling DSC configuration..." -ForegroundColor Yellow
                            
                            # Load and execute the configuration
                            . $configFile.FullName
                            
                            # Get the configuration name from the file
                            $configName = [System.IO.Path]::GetFileNameWithoutExtension($configFile.Name)
                            
                            # Compile the configuration
                            & $configName -OutputPath $dscConfigDir.FullName
                            
                            # Find the generated .mof file
                            $mofFile = Get-ChildItem -Path $dscConfigDir.FullName -Filter "localhost.mof" | Select-Object -First 1
                            
                            if ($mofFile) {
                                Write-Host "  ✓ DSC configuration compiled successfully" -ForegroundColor Green
                                
                                # Create the package using the .mof file
                                $packagePath = New-GuestConfigurationPackage -Name $dscConfigDir.Name -Configuration $mofFile.FullName -Path $dscConfigDir.FullName -Force:$Force
                                
                                if ($packagePath -and (Test-Path $packagePath)) {
                                    Write-Host "  ✓ Package created: $packagePath" -ForegroundColor Green
                                    
                                    # Calculate and store hash
                                    $hash = Get-FileHash -Path $packagePath -Algorithm SHA256
                                    $hashFile = Join-Path $dscConfigDir.FullName "package.hash"
                                    $hash.Hash | Out-File -FilePath $hashFile -Encoding UTF8
                                    Write-Host "  ✓ Hash calculated and saved: $($hash.Hash)" -ForegroundColor Green
                                } else {
                                    Write-Warning "  ✗ Failed to create package for $($dscConfigDir.Name)"
                                }
                            } else {
                                Write-Warning "  ✗ Failed to compile DSC configuration - no .mof file generated"
                            }
                        } catch {
                            Write-Warning "  ✗ Error building package for $($dscConfigDir.Name): $($_.Exception.Message)"
                        }
                    } else {
                        Write-Warning "  ✗ No PowerShell configuration file found in $($dscConfigDir.FullName)"
                    }
                } else {
                    Write-Warning "  ✗ No DSC configuration directory found in $($configDir.FullName)"
                }
            } else {
                Write-Warning "  ✗ No GuestConfiguration directory found for policy: $($policyDir.Name)"
            }
        }
        
        Write-Host "=== DSC Package Building Complete ===" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to build DSC packages: $($_.Exception.Message)"
    }
}

# Function to update policy hashes
function Update-PolicyHashes {
    param(
        [string]$OutputPath,
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Updating Policy Hashes ===" -ForegroundColor Magenta
    
    try {
        $policyDirs = if ($SpecificPolicy) {
            Get-ChildItem -Path $OutputPath -Directory | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        } else {
            Get-ChildItem -Path $OutputPath -Directory
        }
        
        foreach ($policyDir in $policyDirs) {
            Write-Host "Processing policy: $($policyDir.Name)" -ForegroundColor Cyan
            
            # Find the hash file
            $configDir = Get-ChildItem -Path $policyDir.FullName -Directory -Filter "GuestConfiguration" -ErrorAction SilentlyContinue
            if ($configDir) {
                $dscConfigDir = Get-ChildItem -Path $configDir.FullName -Directory | Select-Object -First 1
                if ($dscConfigDir) {
                    $hashFile = Join-Path $dscConfigDir.FullName "package.hash"
                    
                    if (Test-Path $hashFile) {
                        $hash = Get-Content $hashFile -Raw | ForEach-Object { $_.Trim() }
                        Write-Host "  Found hash: $hash" -ForegroundColor Yellow
                        
                        # Update DeployIfNotExists policy
                        $deployPolicyFile = Get-ChildItem -Path $policyDir.FullName -Filter "DeployIfNotExists*.json" | Select-Object -First 1
                        if ($deployPolicyFile) {
                            try {
                                $policyContent = Get-Content $deployPolicyFile.FullName -Raw | ConvertFrom-Json -Depth 100
                                
                                # Update contentHash in metadata
                                if ($policyContent.properties.metadata.guestConfiguration) {
                                    $policyContent.properties.metadata.guestConfiguration.contentHash = $hash
                                }
                                
                                # Update contentHash in policy rule template resources
                                if ($policyContent.properties.policyRule.then.details.deployment.properties.template.resources) {
                                    foreach ($resource in $policyContent.properties.policyRule.then.details.deployment.properties.template.resources) {
                                        if ($resource.properties.guestConfiguration) {
                                            $resource.properties.guestConfiguration.contentHash = $hash
                                        }
                                    }
                                }
                                
                                # Save updated policy
                                $policyContent | ConvertTo-Json -Depth 100 | Set-Content $deployPolicyFile.FullName -Encoding UTF8
                                Write-Host "  ✓ Updated DeployIfNotExists policy with hash" -ForegroundColor Green
                            } catch {
                                Write-Warning "  ✗ Failed to update DeployIfNotExists policy: $($_.Exception.Message)"
                            }
                        }
                        
                        # Update AuditIfNotExists policy if it exists
                        $auditPolicyFile = Get-ChildItem -Path $policyDir.FullName -Filter "AuditIfNotExists*.json" | Select-Object -First 1
                        if ($auditPolicyFile) {
                            try {
                                $auditContent = Get-Content $auditPolicyFile.FullName -Raw | ConvertFrom-Json -Depth 100
                                
                                # Update contentHash in metadata
                                if ($auditContent.properties.metadata.guestConfiguration) {
                                    $auditContent.properties.metadata.guestConfiguration.contentHash = $hash
                                }
                                
                                # Save updated policy
                                $auditContent | ConvertTo-Json -Depth 100 | Set-Content $auditPolicyFile.FullName -Encoding UTF8
                                Write-Host "  ✓ Updated AuditIfNotExists policy with hash" -ForegroundColor Green
                            } catch {
                                Write-Warning "  ✗ Failed to update AuditIfNotExists policy: $($_.Exception.Message)"
                            }
                        }
                    } else {
                        Write-Warning "  ✗ Hash file not found: $hashFile"
                        Write-Host "    Run with -BuildDSCPackages first to generate hashes" -ForegroundColor Yellow
                    }
                } else {
                    Write-Warning "  ✗ No DSC configuration directory found"
                }
            } else {
                Write-Warning "  ✗ No GuestConfiguration directory found"
            }
        }
        
        Write-Host "=== Policy Hash Update Complete ===" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to update policy hashes: $($_.Exception.Message)"
    }
}

# Function to upload DSC packages to Azure Storage
function Upload-DSCPackages {
    param(
        [string]$OutputPath,
        [string]$SpecificPolicy = $null
    )
    
    Write-Host "=== Uploading DSC Packages to Azure Storage ===" -ForegroundColor Magenta
    
    try {
        # Ensure we're connected to Azure
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount -SubscriptionId $SubscriptionId
        } else {
            Write-Host "Using existing Azure context: $($context.Account.Id)" -ForegroundColor Green
        }
        
        # Set context to correct subscription
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        
        # Get storage account
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $AzureResourceGroupName -Name $AzureStorageAccountName -ErrorAction SilentlyContinue
        if (-not $storageAccount) {
            Write-Error "Storage account '$AzureStorageAccountName' not found in resource group '$AzureResourceGroupName'"
            return
        }
        
        $ctx = $storageAccount.Context
        
        # Ensure container exists
        $container = Get-AzStorageContainer -Name $AzureStorageContainerName -Context $ctx -ErrorAction SilentlyContinue
        if (-not $container) {
            Write-Host "Creating storage container: $AzureStorageContainerName" -ForegroundColor Yellow
            New-AzStorageContainer -Name $AzureStorageContainerName -Context $ctx -Permission Blob | Out-Null
        }
        
        $policyDirs = if ($SpecificPolicy) {
            Get-ChildItem -Path $OutputPath -Directory | Where-Object { $_.Name -like "*$SpecificPolicy*" }
        } else {
            Get-ChildItem -Path $OutputPath -Directory
        }
        
        foreach ($policyDir in $policyDirs) {
            Write-Host "Processing policy: $($policyDir.Name)" -ForegroundColor Cyan
            
            $configDir = Get-ChildItem -Path $policyDir.FullName -Directory -Filter "GuestConfiguration" -ErrorAction SilentlyContinue
            if ($configDir) {
                $dscConfigDir = Get-ChildItem -Path $configDir.FullName -Directory | Select-Object -First 1
                if ($dscConfigDir) {
                    # Find the package file
                    $packageFile = Get-ChildItem -Path $dscConfigDir.FullName -Filter "*.zip" | Select-Object -First 1
                    
                    if ($packageFile) {
                        try {
                            $blobName = $packageFile.Name
                            Write-Host "  Uploading: $blobName" -ForegroundColor Yellow
                            
                            $blob = Set-AzStorageBlobContent -File $packageFile.FullName -Container $AzureStorageContainerName -Blob $blobName -Context $ctx -Force
                            
                            if ($blob) {
                                Write-Host "  ✓ Uploaded successfully" -ForegroundColor Green
                                Write-Host "    URL: $($blob.ICloudBlob.StorageUri.PrimaryUri)" -ForegroundColor Gray
                            } else {
                                Write-Warning "  ✗ Upload failed for $blobName"
                            }
                        } catch {
                            Write-Warning "  ✗ Error uploading $($packageFile.Name): $($_.Exception.Message)"
                        }
                    } else {
                        Write-Warning "  ✗ No package file found in $($dscConfigDir.FullName)"
                        Write-Host "    Run with -BuildDSCPackages first to create packages" -ForegroundColor Yellow
                    }
                } else {
                    Write-Warning "  ✗ No DSC configuration directory found"
                }
            } else {
                Write-Warning "  ✗ No GuestConfiguration directory found"
            }
        }
        
        Write-Host "=== DSC Package Upload Complete ===" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to upload DSC packages: $($_.Exception.Message)"
    }
}

# Main execution
$outputPath = Join-Path $PSScriptRoot "Output"

if ($DeployPolicies) {
    Deploy-Policies -OutputPath $outputPath -SpecificPolicy $PolicyName
} elseif ($RemovePolicies) {
    Remove-Policies -SpecificPolicy $PolicyName
} elseif ($GetPolicies) {
    Get-Policies -SpecificPolicy $PolicyName
} elseif ($RemoveAssignments) {
    Remove-PolicyAssignments -SpecificPolicy $PolicyName
} elseif ($BuildDSCPackages) {
    Build-DSCPackages -OutputPath $outputPath -SpecificPolicy $PolicyName
} elseif ($UpdateHashes) {
    Update-PolicyHashes -OutputPath $outputPath -SpecificPolicy $PolicyName
} elseif ($UploadPackages) {
    Upload-DSCPackages -OutputPath $outputPath -SpecificPolicy $PolicyName
} else {
    Write-Host "Azure Guest Configuration Policy Management Tool" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Available functions:" -ForegroundColor Cyan
    Write-Host "  1. Deploy policies to Azure:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -DeployPolicies" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Remove policies from Azure:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -RemovePolicies" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Get policies from Azure:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -GetPolicies" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. Remove policy assignments from Azure:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -RemoveAssignments" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  5. Build DSC packages:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -BuildDSCPackages" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  6. Update policy hashes:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -UpdateHashes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  7. Upload DSC packages to Azure Storage:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -UploadPackages" -ForegroundColor Gray
    Write-Host ""
    Write-Host "DSC Package Workflow (run in order):" -ForegroundColor Cyan
    Write-Host "  1. Build packages and calculate hashes:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -BuildDSCPackages" -ForegroundColor Gray
    Write-Host "  2. Update policy files with hashes:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -UpdateHashes" -ForegroundColor Gray
    Write-Host "  3. Upload packages to Azure Storage:" -ForegroundColor Yellow
    Write-Host "     .\Manage-Policies.ps1 -UploadPackages" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Optional parameters:" -ForegroundColor Cyan
    Write-Host "  -PolicyName: Target specific policy" -ForegroundColor Gray
    Write-Host "  -SubscriptionId: Override subscription ID" -ForegroundColor Gray
    Write-Host "  -ResourceGroupName: Override resource group name" -ForegroundColor Gray
    Write-Host "  -Force: Force rebuild/overwrite" -ForegroundColor Gray
}
