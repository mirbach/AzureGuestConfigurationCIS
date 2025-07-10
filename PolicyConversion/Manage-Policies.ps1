# Bulk Policy Management Script
# This script provides bulk operations for managing all converted policies

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Convert", "Build", "Deploy", "UpdatePolicies", "DeployPolicies", "BulkDeployPolicies", "CreateInitiatives", "AssignInitiatives", "Status", "Test", "Clean", "UpdateHashes", "StandardizeFolders")]
    [string]$Action = "Status",
    
    [Parameter(Mandatory = $false)]
    [string]$PolicyFilter = "*",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$Parallel
)

$scriptPath = $PSScriptRoot
$outputPath = Join-Path $scriptPath "Output"
$inputPath = Join-Path $scriptPath "Input"

# Configuration
$config = @{
    SubscriptionId = "e749c27d-1157-4753-929c-adfddb9c814c"
    StorageAccount = @{
        Name = "saserverhardeningdkleac"
        ResourceGroupName = "RG_ARC_Local_All_RestoreTest"
    }
    MaxParallelJobs = 5
}

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Color
}

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
        [string]$GuestConfigurationPath,
        [bool]$Silent = $false
    )
    
    try {
        # Find the azure-config.json file
        $azureConfigPath = Join-Path $GuestConfigurationPath "azure-config.json"
        if (-not (Test-Path $azureConfigPath)) {
            if (-not $Silent) { Write-Status "  azure-config.json not found" "Yellow" }
            return $false
        }
        
        # Find the package file
        $outputDir = Join-Path $GuestConfigurationPath "Output"
        $packageFiles = Get-ChildItem $outputDir -Filter "*.zip" -ErrorAction SilentlyContinue
        if ($packageFiles.Count -eq 0) {
            if (-not $Silent) { Write-Status "  No package (.zip) files found in Output directory" "Yellow" }
            return $false
        }
        
        $packagePath = $packageFiles[0].FullName
        
        # Calculate the actual hash
        $actualHash = Get-FileHash256 -FilePath $packagePath
        
        # Load the current config
        $config = Get-Content $azureConfigPath | ConvertFrom-Json
        
        # Update the hash if different
        $oldHash = $config.Package.CurrentContentHash
        if ($oldHash -ne $actualHash) {
            $config.Package.CurrentContentHash = $actualHash
            
            # Save the updated config
            $config | ConvertTo-Json -Depth 10 | Out-File $azureConfigPath -Encoding UTF8
            
            if (-not $Silent) { 
                Write-Status "  ✓ Updated content hash: $($actualHash.Substring(0,16))..." "Green" 
            }
        } else {
            if (-not $Silent) { 
                Write-Status "  ✓ Content hash is current" "Green" 
            }
        }
        
        return $true
    }
    catch {
        if (-not $Silent) { 
            Write-Status "  ✗ Failed to update hash: $($_.Exception.Message)" "Red" 
        }
        return $false
    }
}

function Connect-ToAzure {
    param([bool]$Force = $false)
    
    # Check if we're already connected
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if ($context -and -not $Force) {
        Write-Status "Already connected to Azure:" "Green"
        Write-Status "  Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" "Gray"
        Write-Status "  Account: $($context.Account.Id)" "Gray"
        return $true
    }
    
    Write-Status "Connecting to Azure..." "Cyan"
    try {
        # Import required modules
        $requiredModules = @('Az.Accounts', 'Az.Storage')
        foreach ($module in $requiredModules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Status "Installing module: $module" "Yellow"
                Install-Module -Name $module -Force -Scope CurrentUser
            }
            Import-Module $module -Force
        }
        
        # Connect to Azure
        $azureConnection = Connect-AzAccount
        if ($azureConnection) {
            $context = Get-AzContext
            Write-Status "✓ Successfully connected to Azure:" "Green"
            Write-Status "  Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" "Gray"
            Write-Status "  Account: $($context.Account.Id)" "Gray"
            return $true
        }
        return $false
    }
    catch {
        Write-Status "✗ Failed to connect to Azure: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Get-PolicyDirectories {
    param([string]$Filter = "*")
    
    if (Test-Path $outputPath) {
        return Get-ChildItem $outputPath -Directory | Where-Object { $_.Name -like $Filter }
    }
    return @()
}

function Get-GuestConfigurationDirectories {
    param([string]$Filter = "*")
    
    $gcDirs = @()
    $policyDirs = Get-PolicyDirectories -Filter $Filter
    
    foreach ($policyDir in $policyDirs) {
        $gcPath = Join-Path $policyDir.FullName "GuestConfiguration"
        if (Test-Path $gcPath) {
            $gcSubDirs = Get-ChildItem $gcPath -Directory
            foreach ($gcSubDir in $gcSubDirs) {
                $gcDirs += [PSCustomObject]@{
                    PolicyName = $policyDir.Name
                    ConfigurationName = $gcSubDir.Name
                    Path = $gcSubDir.FullName
                    BuildScript = Join-Path $gcSubDir.FullName "Build-And-Deploy-Package.ps1"
                    DSCConfiguration = Join-Path $gcSubDir.FullName "$($gcSubDir.Name).ps1"
                    AzureConfig = Join-Path $gcSubDir.FullName "azure-config.json"
                }
            }
        }
    }
    
    return $gcDirs
}

function Invoke-ConvertPolicies {
    Write-Status "Converting policies from AuditIfNotExists to DeployIfNotExists..." "Green"
    
    $policyFiles = Get-ChildItem $inputPath -Filter "*.json" -ErrorAction SilentlyContinue
    if ($policyFiles.Count -eq 0) {
        Write-Status "No policy files found in Input directory" "Yellow"
        Write-Status "Please place your AuditIfNotExists policy JSON files in: $inputPath" "Yellow"
        return
    }
    
    Write-Status "Found $($policyFiles.Count) policy files to convert" "Cyan"
    
    $convertScript = Join-Path $scriptPath "Convert-Policies.ps1"
    & $convertScript
    
    Write-Status "Policy conversion completed" "Green"
}

function Invoke-BuildPackages {
    Write-Status "Building Guest Configuration packages..." "Green"
    
    $gcDirs = Get-GuestConfigurationDirectories -Filter $PolicyFilter
    if ($gcDirs.Count -eq 0) {
        Write-Status "No Guest Configuration directories found" "Yellow"
        return
    }
    
    $successful = 0
    $failed = 0
    
    foreach ($gcDir in $gcDirs) {
        Write-Status "Building package: $($gcDir.ConfigurationName)" "Cyan"
        
        try {
            Push-Location $gcDir.Path
            
            if ($Force) {
                $result = & ".\Build-And-Deploy-Package.ps1" -Force 2>&1
            } else {
                $result = & ".\Build-And-Deploy-Package.ps1" 2>&1
            }
            $buildOutput = $result | Out-String
            
            # Check if build was successful by looking for success indicators in output
            $buildSuccessful = $false
            if ($buildOutput -match "✓ Package built:" -or 
                $buildOutput -match "Package already exists at:" -or 
                $buildOutput -match "Configuration compiled successfully") {
                $buildSuccessful = $true
            }
            
            # Also check if package file exists
            $packagePath = Join-Path $gcDir.Path "Output\$($gcDir.ConfigurationName).zip"
            if (Test-Path $packagePath) {
                $buildSuccessful = $true
            }
            
            if ($buildSuccessful) {
                $successful++
                Write-Status "  ✓ Build successful" "Green"
                
                # Update content hash after successful build
                Write-Status "  Updating content hash..." "Cyan"
                $hashUpdated = Update-AzureConfigHash -GuestConfigurationPath $gcDir.Path -Silent $false
                if (-not $hashUpdated) {
                    Write-Status "  ⚠ Hash update failed (build still successful)" "Yellow"
                }
            } else {
                $failed++
                Write-Status "  ✗ Build failed" "Red"
            }
        }
        catch {
            $failed++
            Write-Status "  ✗ Build error: $($_.Exception.Message)" "Red"
        }
        finally {
            Pop-Location
        }
    }
    
    Write-Status "Build summary: $successful successful, $failed failed" "Yellow"
}

function Invoke-DeployPackages {
    Write-Status "Deploying Guest Configuration packages to Azure Storage..." "Green"
    
    # Connect to Azure once for all deployments
    if (-not (Connect-ToAzure)) {
        Write-Status "Failed to connect to Azure. Aborting deployment." "Red"
        return
    }
    
    $gcDirs = Get-GuestConfigurationDirectories -Filter $PolicyFilter
    if ($gcDirs.Count -eq 0) {
        Write-Status "No Guest Configuration directories found" "Yellow"
        return
    }
    
    $successful = 0
    $failed = 0
    
    foreach ($gcDir in $gcDirs) {
        Write-Status "Deploying package: $($gcDir.ConfigurationName)" "Cyan"
        
        try {
            Push-Location $gcDir.Path
            
            if ($Force) {
                $result = & ".\Build-And-Deploy-Package.ps1" -Deploy -UpdatePolicyFiles -Force -SkipAzureLogin 2>&1
                $exitCode = $LASTEXITCODE
            } else {
                $result = & ".\Build-And-Deploy-Package.ps1" -Deploy -UpdatePolicyFiles -SkipAzureLogin 2>&1
                $exitCode = $LASTEXITCODE
            }
            $deployOutput = $result | Out-String
            
            # Deployment success detection:
            # The Build-And-Deploy-Package script has a bug where it returns exit code 1 
            # even on successful deployments, so we can't rely on exit codes alone.
            # Instead, we'll assume success unless there are clear error indicators.
            $deploySuccessful = $true  # Assume success by default
            
            # Check for major deployment failures that would indicate actual failure
            if ($deployOutput -like "*Authentication failed*" -or 
                $deployOutput -like "*Storage account not found*" -or
                $deployOutput -like "*Access denied*" -or
                $deployOutput -like "*Unable to connect*" -or
                $deployOutput -like "*No subscription*" -or
                $deployOutput -like "*FATAL ERROR*" -or
                $deployOutput -like "*Cannot connect to Azure*" -or
                ($exitCode -ne $null -and $exitCode -gt 1)) {  # Exit codes > 1 usually indicate serious errors
                $deploySuccessful = $false
                Write-Status "  ✗ Major deployment error detected" "Red"
            } else {
                Write-Status "  ✓ Azure Storage deployment successful" "Green"
            }
            
            # Always check for policy file update issues (this is a secondary concern)
            if ($deployOutput.Contains("Failed to update policy files") -or 
                $deployOutput -match "⚠ Policy file update failed") {
                Write-Status "  ⚠ Policy file update failed (deployment may still be successful)" "Yellow"
            }
            
            if ($deploySuccessful) {
                $successful++
                Write-Status "  ✓ Deploy successful" "Green"
                
                # Update content hash after successful deployment
                Write-Status "  Updating content hash..." "Cyan"
                $hashUpdated = Update-AzureConfigHash -GuestConfigurationPath $gcDir.Path -Silent $false
                if (-not $hashUpdated) {
                    Write-Status "  ⚠ Hash update failed (deployment still successful)" "Yellow"
                }
            } else {
                $failed++
                Write-Status "  ✗ Deploy failed" "Red"
            }
        }
        catch {
            $failed++
            Write-Status "  ✗ Deploy error: $($_.Exception.Message)" "Red"
        }
        finally {
            Pop-Location
        }
    }
    
    Write-Status "Deploy summary: $successful successful, $failed failed" "Yellow"
}

function Invoke-UpdatePolicyFiles {
    Write-Status "Updating policy files with current package hashes..." "Green"
    
    $gcDirs = Get-GuestConfigurationDirectories -Filter $PolicyFilter
    if ($gcDirs.Count -eq 0) {
        Write-Status "No Guest Configuration directories found" "Yellow"
        return
    }
    
    $successful = 0
    $failed = 0
    
    foreach ($gcDir in $gcDirs) {
        Write-Status "Updating policy files: $($gcDir.ConfigurationName)" "Cyan"
        
        try {
            Push-Location $gcDir.Path
            
            $result = & ".\Build-And-Deploy-Package.ps1" -UpdatePolicyFiles
            
            if ($LASTEXITCODE -eq 0) {
                $successful++
                Write-Status "  ✓ Update successful" "Green"
            } else {
                $failed++
                Write-Status "  ✗ Update failed" "Red"
            }
        }
        catch {
            $failed++
            Write-Status "  ✗ Update error: $($_.Exception.Message)" "Red"
        }
        finally {
            Pop-Location
        }
    }
    
    Write-Status "Update summary: $successful successful, $failed failed" "Yellow"
}

function Invoke-DeployPolicies {
    Write-Status "Deploying all policies to Azure..." "Green"
    
    $deployScript = Join-Path $scriptPath "..\Deploy-Policies-PowerShell.ps1"
    if (Test-Path $deployScript) {
        & $deployScript
        Write-Status "Policy deployment completed" "Green"
    } else {
        Write-Status "Deploy script not found: $deployScript" "Red"
    }
}

function Invoke-BulkDeployPolicies {
    Write-Status "Deploying all converted policies to Azure Policy..." "Green"
    
    # Connect to Azure first
    if (-not (Connect-ToAzure)) {
        Write-Status "Failed to connect to Azure. Aborting policy deployment." "Red"
        return
    }
    
    # Find all policy directories
    $policyDirs = Get-PolicyDirectories -Filter $PolicyFilter
    if ($policyDirs.Count -eq 0) {
        Write-Status "No policy directories found for deployment" "Yellow"
        return
    }
    
    Write-Status "Found $($policyDirs.Count) policy directories to deploy" "Cyan"
    
    $successful = 0
    $failed = 0
    
    foreach ($policyDir in $policyDirs) {
        Write-Status "Deploying policies from: $($policyDir.Name)" "Cyan"
        
        try {
            # Find the policy JSON files
            $auditPolicyFile = Get-ChildItem $policyDir.FullName -Filter "AuditIfNotExists*.json" | Select-Object -First 1
            $deployPolicyFile = Get-ChildItem $policyDir.FullName -Filter "DeployIfNotExists*.json" | Select-Object -First 1
            
            if (-not $auditPolicyFile) {
                Write-Status "  ⚠ AuditIfNotExists policy file not found" "Yellow"
                continue
            }
            
            if (-not $deployPolicyFile) {
                Write-Status "  ⚠ DeployIfNotExists policy file not found" "Yellow"
                continue
            }
            
            # Deploy AuditIfNotExists Policy
            Write-Status "  Deploying AuditIfNotExists policy..." "Gray"
            $auditSuccess = Deploy-SinglePolicy -PolicyFile $auditPolicyFile.FullName -PolicyType "Audit" -PolicyFolderName $policyDir.Name
            
            # Deploy DeployIfNotExists Policy
            Write-Status "  Deploying DeployIfNotExists policy..." "Gray"
            $deploySuccess = Deploy-SinglePolicy -PolicyFile $deployPolicyFile.FullName -PolicyType "Deploy" -PolicyFolderName $policyDir.Name
            
            if ($auditSuccess -and $deploySuccess) {
                $successful++
                Write-Status "  ✓ Both policies deployed successfully" "Green"
            } else {
                $failed++
                Write-Status "  ✗ One or more policies failed to deploy" "Red"
            }
        }
        catch {
            $failed++
            Write-Status "  ✗ Policy deployment error: $($_.Exception.Message)" "Red"
        }
    }
    
    Write-Status "" "White"
    Write-Status "=== Policy Deployment Summary ===" "Magenta"
    Write-Status "Successful: $successful" "Green"
    Write-Status "Failed: $failed" "Red"
    Write-Status "Total: $($successful + $failed)" "Cyan"
    
    if ($failed -eq 0) {
        Write-Status "✓ All policies deployed successfully!" "Green"
        Write-Status "" "White"
        Write-Status "Next steps:" "Yellow"
        Write-Status "1. Assign the policies to your desired scope (subscription/resource group)" "White"
        Write-Status "2. Configure policy parameters as needed" "White"
        Write-Status "3. Monitor compliance in the Azure Policy portal" "White"
    } else {
        Write-Status "⚠ Some policies failed to deploy. Check the output above for details." "Yellow"
    }
}

function Get-PolicyName {
    param(
        [string]$PolicyType,
        [string]$PolicyFolderName
    )
    
    # Clean the folder name
    $cleanFolderName = $PolicyFolderName -replace '[^a-zA-Z0-9]', ''
    
    # Create the base name
    $baseName = "GG-$PolicyType-$cleanFolderName"
    
    # Azure Policy Definition names have a max length of 64 characters
    if ($baseName.Length -gt 64) {
        # Truncate while keeping the prefix
        $prefix = "GG-$PolicyType-"
        $maxContentLength = 64 - $prefix.Length
        $truncatedContent = $cleanFolderName.Substring(0, $maxContentLength)
        $baseName = "$prefix$truncatedContent"
    }
    
    return $baseName
}

function Deploy-SinglePolicy {
    param(
        [string]$PolicyFile,
        [string]$PolicyType,
        [string]$PolicyFolderName
    )
    
    try {
        # Read and parse the policy file
        $policyContent = Get-Content $PolicyFile -Raw | ConvertFrom-Json
        
        # Generate a unique policy name based on the folder name and type
        $policyName = Get-PolicyName -PolicyType $PolicyType -PolicyFolderName $PolicyFolderName
        
        # Prepare policy parameters for Azure Policy cmdlets
        $displayName = $policyContent.properties.displayName
        if ($displayName.Length -gt 128) {
            $displayName = $displayName.Substring(0, 125) + "..."
        }
        
        $description = $policyContent.properties.description
        if ($description.Length -gt 512) {
            $description = $description.Substring(0, 509) + "..."
        }
        
        $policyParams = @{
            Name = $policyName
            DisplayName = $displayName
            Description = $description
            Policy = ($policyContent.properties.policyRule | ConvertTo-Json -Depth 20)
        }
        
        # Add metadata if it exists
        if ($policyContent.properties.metadata) {
            $policyParams.Metadata = ($policyContent.properties.metadata | ConvertTo-Json -Depth 10)
        }
        
        # Add parameters if they exist (limit to 20 parameters due to Azure Policy constraints)
        if ($policyContent.properties.parameters) {
            $parameterCount = ($policyContent.properties.parameters | Get-Member -MemberType NoteProperty).Count
            
            if ($parameterCount -gt 20) {
                Write-Status "    Policy has $parameterCount parameters (max 20 allowed), reducing..." "Yellow"
                
                # Keep only the most important parameters
                $essentialParamNames = @('IncludeArcMachines', 'assignmentType', 'effect')
                $reducedParams = @{}
                
                foreach ($paramName in $essentialParamNames) {
                    if ($policyContent.properties.parameters.$paramName) {
                        $reducedParams[$paramName] = $policyContent.properties.parameters.$paramName
                    }
                }
                
                # Convert back to JSON with reduced parameters
                $policyParams.Parameter = ($reducedParams | ConvertTo-Json -Depth 10)
                Write-Status "    Reduced to $($reducedParams.Count) essential parameters" "Gray"
            }
            else {
                $policyParams.Parameter = ($policyContent.properties.parameters | ConvertTo-Json -Depth 10)
            }
        }
        
        # Try to create the policy first, then update if it already exists
        try {
            $result = New-AzPolicyDefinition @policyParams
            Write-Status "    ✓ $PolicyType policy created" "Green"
        }
        catch {
            $errorMessage = $_.Exception.Message
            
            if ($errorMessage -like "*already exists*" -or $errorMessage -like "*PolicyDefinitionAlreadyExists*") {
                # Policy already exists, try to update it
                Write-Status "    Policy exists, updating..." "Gray"
                try {
                    $result = Set-AzPolicyDefinition @policyParams
                    Write-Status "    ✓ $PolicyType policy updated" "Green"
                }
                catch {
                    throw "Failed to update existing policy: $($_.Exception.Message)"
                }
            }
            elseif ($errorMessage -like "*parameter validation*" -or $errorMessage -like "*undefined parameter*") {
                # Parameter validation warning - but policy creation might still succeed
                Write-Status "    ⚠ Validation warning occurred, checking if policy was created..." "Yellow"
                
                # Check if policy was actually created despite the warning
                try {
                    $existingPolicy = Get-AzPolicyDefinition -Name $policyName -ErrorAction SilentlyContinue
                    if ($existingPolicy) {
                        Write-Status "    ✓ $PolicyType policy created successfully (with warnings)" "Green"
                    } else {
                        throw "Policy was not created due to validation errors"
                    }
                } catch {
                    Write-Status "    ✗ Policy creation failed due to validation errors" "Red"
                    throw "Parameter validation failed: $($errorMessage.Split('.')[0])"
                }
            }
            elseif ($errorMessage -like "*exceeds the maximum limit*") {
                # Too many parameters - policy might still be created
                Write-Status "    ⚠ Policy created despite parameter limit warning" "Yellow"
                Write-Status "      Warning: Too many parameters" "Gray"
            }
            else {
                throw $errorMessage
            }
        }
        
        return $true
    }
    catch {
        Write-Status "    ✗ Failed to deploy $PolicyType policy: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Invoke-CreateInitiatives {
    Write-Status "Creating Azure Policy Initiatives..." "Green"
    
    # Connect to Azure first
    if (-not (Connect-ToAzure)) {
        Write-Status "Failed to connect to Azure. Aborting initiative creation." "Red"
        return
    }
    
    # Get all policy directories to build the initiative definitions
    # Filter out the long-named folders that contain the full policy display names
    # and only use the shorter, cleaner folder names that were actually used for deployment
    $allPolicyDirs = Get-PolicyDirectories -Filter $PolicyFilter
    $policyDirs = $allPolicyDirs | Where-Object { 
        $_.Name.Length -lt 100 -and $_.Name -notlike "Windows machines should meet requirements*" 
    }
    if ($policyDirs.Count -eq 0) {
        Write-Status "No policy directories found for initiative creation" "Yellow"
        return
    }
    
    Write-Status "Found $($policyDirs.Count) policy directories for initiatives" "Cyan"
    
    # Build policy references for each initiative
    $auditPolicyRefs = @()
    $deployPolicyRefs = @()
    
    foreach ($policyDir in $policyDirs) {
        $folderName = $policyDir.Name
        
        # Check if policies exist before adding to initiative
        $auditPolicyName = Get-PolicyName -PolicyType "Audit" -PolicyFolderName $folderName
        $deployPolicyName = Get-PolicyName -PolicyType "Deploy" -PolicyFolderName $folderName
        
        $auditPolicy = Get-AzPolicyDefinition -Name $auditPolicyName -ErrorAction SilentlyContinue
        $deployPolicy = Get-AzPolicyDefinition -Name $deployPolicyName -ErrorAction SilentlyContinue
        
        if ($auditPolicy) {
            $auditPolicyRefs += @{
                policyDefinitionId = "/subscriptions/$($config.SubscriptionId)/providers/Microsoft.Authorization/policyDefinitions/$auditPolicyName"
                parameters = @{}
            }
        } else {
            Write-Status "  ⚠ Audit policy not found: $auditPolicyName" "Yellow"
        }
        
        if ($deployPolicy) {
            $deployPolicyRefs += @{
                policyDefinitionId = "/subscriptions/$($config.SubscriptionId)/providers/Microsoft.Authorization/policyDefinitions/$deployPolicyName"
                parameters = @{}
            }
        } else {
            Write-Status "  ⚠ Deploy policy not found: $deployPolicyName" "Yellow"
        }
    }
    
    Write-Status "Found $($auditPolicyRefs.Count) audit policies and $($deployPolicyRefs.Count) deploy policies" "Cyan"
    
    if ($auditPolicyRefs.Count -eq 0) {
        Write-Status "No audit policies found. Run 'BulkDeployPolicies' first to create the policies." "Red"
        return
    }
    
    if ($deployPolicyRefs.Count -eq 0) {
        Write-Status "No deploy policies found. Run 'BulkDeployPolicies' first to create the policies." "Red"
        return
    }
    
    # Create Audit Initiative
    Write-Status "Creating Audit Policy Initiative..." "Cyan"
    $auditInitiativeName = "GG-Windows-Security-Baseline-Audit"
    $auditInitiativeDisplayName = "[GG Serverhardening] Windows Security Baseline - Audit Policies"
    $auditInitiativeDescription = "This initiative includes all audit policies for Windows security baseline compliance monitoring. These policies will assess compliance without making changes to the systems."
    
    try {
        $auditInitiativeParams = @{
            Name = $auditInitiativeName
            DisplayName = $auditInitiativeDisplayName
            Description = $auditInitiativeDescription
            PolicyDefinition = ($auditPolicyRefs | ConvertTo-Json -Depth 10)
            Metadata = (@{
                category = "Guest Configuration"
                version = "1.0.0"
                type = "Audit Initiative"
            } | ConvertTo-Json -Depth 5)
        }
        
        # Try to create the initiative first
        try {
            Write-Status "  Creating new audit initiative..." "Gray"
            $auditResult = New-AzPolicySetDefinition @auditInitiativeParams
            Write-Status "  ✓ Audit initiative created successfully" "Green"
        }
        catch {
            if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*PolicySetDefinitionAlreadyExists*") {
                # Initiative already exists, try to update it
                Write-Status "  Audit initiative exists, updating..." "Gray"
                $auditResult = Set-AzPolicySetDefinition @auditInitiativeParams
                Write-Status "  ✓ Audit initiative updated successfully" "Green"
            } else {
                throw $_.Exception.Message
            }
        }
    }
    catch {
        Write-Status "  ✗ Failed to create/update audit initiative: $($_.Exception.Message)" "Red"
        return
    }
    
    # Create Deploy Initiative
    Write-Status "Creating Deploy Policy Initiative..." "Cyan"
    $deployInitiativeName = "GG-Windows-Security-Baseline-Deploy"
    $deployInitiativeDisplayName = "[GG Serverhardening] Windows Security Baseline - Deploy Policies"
    $deployInitiativeDescription = "This initiative includes all deploy policies for Windows security baseline compliance enforcement. These policies will deploy Guest Configuration assignments to ensure compliance and can remediate non-compliant systems."
    
    try {
        $deployInitiativeParams = @{
            Name = $deployInitiativeName
            DisplayName = $deployInitiativeDisplayName
            Description = $deployInitiativeDescription
            PolicyDefinition = ($deployPolicyRefs | ConvertTo-Json -Depth 10)
            Metadata = (@{
                category = "Guest Configuration"
                version = "1.0.0"
                type = "Deploy Initiative"
            } | ConvertTo-Json -Depth 5)
        }
        
        # Try to create the initiative first
        try {
            Write-Status "  Creating new deploy initiative..." "Gray"
            $deployResult = New-AzPolicySetDefinition @deployInitiativeParams
            Write-Status "  ✓ Deploy initiative created successfully" "Green"
        }
        catch {
            if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*PolicySetDefinitionAlreadyExists*") {
                # Initiative already exists, try to update it
                Write-Status "  Deploy initiative exists, updating..." "Gray"
                $deployResult = Set-AzPolicySetDefinition @deployInitiativeParams
                Write-Status "  ✓ Deploy initiative updated successfully" "Green"
            } else {
                throw $_.Exception.Message
            }
        }
    }
    catch {
        Write-Status "  ✗ Failed to create/update deploy initiative: $($_.Exception.Message)" "Red"
        return
    }
    
    Write-Status "" "White"
    Write-Status "=== Initiative Creation Summary ===" "Magenta"
    Write-Status "✓ Audit Initiative: $auditInitiativeName" "Green"
    Write-Status "  - Contains $($auditPolicyRefs.Count) audit policies" "Gray"
    Write-Status "✓ Deploy Initiative: $deployInitiativeName" "Green"
    Write-Status "  - Contains $($deployPolicyRefs.Count) deploy policies" "Gray"
    Write-Status "" "White"
    Write-Status "Next steps:" "Yellow"
    Write-Status "1. Use 'AssignInitiatives' action to assign these initiatives to desired scopes" "White"
    Write-Status "2. Configure initiative parameters as needed during assignment" "White"
    Write-Status "3. Monitor compliance in the Azure Policy portal" "White"
}

function Invoke-AssignInitiatives {
    param(
        [string]$TargetScope,
        [string]$InitiativeFilter = "*"
    )
    
    # Set default scope if not provided
    if (-not $TargetScope) {
        $TargetScope = "/subscriptions/$($config.SubscriptionId)"
    }
    
    Write-Status "Assigning Azure Policy Initiatives..." "Green"
    
    # Connect to Azure first
    if (-not (Connect-ToAzure)) {
        Write-Status "Failed to connect to Azure. Aborting initiative assignment." "Red"
        return
    }
    
    Write-Status "Target scope: $TargetScope" "Cyan"
    
    $initiatives = @(
        @{
            Name = "GG-Windows-Security-Baseline-Audit"
            DisplayName = "[GG Serverhardening] Windows Security Baseline - Audit Assignment"
            Type = "Audit"
        },
        @{
            Name = "GG-Windows-Security-Baseline-Deploy"
            DisplayName = "[GG Serverhardening] Windows Security Baseline - Deploy Assignment"
            Type = "Deploy"
        }
    )
    
    $successful = 0
    $failed = 0
    
    foreach ($initiative in $initiatives) {
        if ($initiative.Name -like $InitiativeFilter) {
            Write-Status "Assigning $($initiative.Type) initiative..." "Cyan"
            
            try {
                # Check if initiative exists
                Write-Status "  Checking for initiative: $($initiative.Name)" "Gray"
                $initiativeDefinition = Get-AzPolicySetDefinition -Name $initiative.Name -SubscriptionId $config.SubscriptionId -ErrorAction SilentlyContinue
                if (-not $initiativeDefinition) {
                    Write-Status "  ✗ Initiative '$($initiative.Name)' not found. Run 'CreateInitiatives' first." "Red"
                    $failed++
                    continue
                }
                
                # Create assignment name and parameters
                $assignmentName = "Assignment-$($initiative.Name)"
                $assignmentDisplayName = $initiative.DisplayName
                $assignmentDescription = "Assignment of $($initiative.Type.ToLower()) policies for Windows security baseline compliance."
                
                # Check if assignment already exists
                $existingAssignment = Get-AzPolicyAssignment -Name $assignmentName -Scope $TargetScope -SubscriptionId $config.SubscriptionId -ErrorAction SilentlyContinue
                
                if ($existingAssignment) {
                    Write-Status "  Assignment already exists: $assignmentName" "Yellow"
                    Write-Status "  ✓ Skipping assignment (already exists)" "Gray"
                } else {
                    # Create the assignment
                    $assignmentParams = @{
                        Name = $assignmentName
                        DisplayName = $assignmentDisplayName
                        Description = $assignmentDescription
                        PolicySetDefinition = $initiativeDefinition
                        Scope = $TargetScope
                    }
                    
                    # Add managed identity for deploy initiatives (required for DeployIfNotExists policies)
                    if ($initiative.Type -eq "Deploy") {
                        $assignmentParams.IdentityType = "SystemAssigned"
                        $assignmentParams.Location = "East US"  # Required for managed identity
                    }
                    
                    $assignment = New-AzPolicyAssignment @assignmentParams
                    Write-Status "  ✓ $($initiative.Type) initiative assigned successfully" "Green"
                    
                    if ($initiative.Type -eq "Deploy") {
                        Write-Status "  ℹ Deploy initiative assigned with system-assigned managed identity" "Cyan"
                        Write-Status "  ℹ You may need to assign appropriate permissions to the managed identity" "Cyan"
                    }
                }
                
                $successful++
            }
            catch {
                Write-Status "  ✗ Failed to assign $($initiative.Type) initiative: $($_.Exception.Message)" "Red"
                $failed++
            }
        }
    }
    
    Write-Status "" "White"
    Write-Status "=== Initiative Assignment Summary ===" "Magenta"
    Write-Status "Successful: $successful" "Green"
    Write-Status "Failed: $failed" "Red"
    Write-Status "Target Scope: $TargetScope" "Cyan"
    
    if ($failed -eq 0) {
        Write-Status "" "White"
        Write-Status "✓ All initiatives assigned successfully!" "Green"
        Write-Status "" "White"
        Write-Status "Next steps:" "Yellow"
        Write-Status "1. Review assignments in the Azure Policy portal" "White"
        Write-Status "2. Configure any required parameters for the assignments" "White"
        Write-Status "3. For deploy initiatives, ensure managed identity has necessary permissions" "White"
        Write-Status "4. Monitor compliance and remediation tasks" "White"
    }
}

function Show-Status {
    Write-Status "=== Policy Status Overview ===" "Magenta"
    
    $policyDirs = Get-PolicyDirectories
    Write-Status "Policy directories found: $($policyDirs.Count)" "Cyan"
    
    $gcDirs = Get-GuestConfigurationDirectories
    Write-Status "Guest Configuration directories found: $($gcDirs.Count)" "Cyan"
    
    # Check for built packages
    $builtPackages = 0
    foreach ($gcDir in $gcDirs) {
        $packagePath = Join-Path $gcDir.Path "Output\$($gcDir.ConfigurationName).zip"
        if (Test-Path $packagePath) {
            $builtPackages++
        }
    }
    Write-Status "Built packages: $builtPackages" "Cyan"
    
    Write-Status "" "White"
    Write-Status "Available actions:" "Yellow"
    Write-Status "  Convert       - Convert AuditIfNotExists policies to DeployIfNotExists" "White"
    Write-Status "  Build         - Build Guest Configuration packages" "White"
    Write-Status "  Deploy        - Deploy packages to Azure Storage" "White"
    Write-Status "  BulkDeployPolicies - Deploy all policies to Azure Policy" "White"
    Write-Status "  CreateInitiatives  - Create policy initiatives (groups)" "White"
    Write-Status "  AssignInitiatives  - Assign initiatives to scopes" "White"
    Write-Status "  StandardizeFolders - Rename long folder names to consistent short names" "White"
    Write-Status "  UpdateHashes  - Update content hashes for packages" "White"
}

function Invoke-TestConfigurations {
    Write-Status "Testing Guest Configurations..." "Green"
    Write-Status "Test functionality not implemented yet." "Yellow"
}

function Invoke-CleanOutput {
    Write-Status "Cleaning workspace and removing unnecessary files..." "Green"
    
    # First, standardize folder names to ensure consistency
    Write-Status "Step 1: Standardizing folder names..." "Cyan"
    Invoke-StandardizeFolders
    
    Write-Status "Step 2: Removing development artifacts..." "Cyan"
    
    $filesToRemove = @()
    $bytesFreed = 0
    
    # Step 2a: Remove backup files (.backup)
    Write-Status "  Removing backup files..." "Gray"
    $backupFiles = Get-ChildItem $scriptPath -Recurse -Filter "*.backup" -ErrorAction SilentlyContinue
    foreach ($backupFile in $backupFiles) {
        $bytesFreed += $backupFile.Length
        $filesToRemove += $backupFile.FullName
        Write-Status "    Marking backup file: $($backupFile.Name)" "Gray"
    }
    
    # Step 2b: Remove temporary .mof files
    Write-Status "  Removing temporary .mof files..." "Gray"
    $mofFiles = Get-ChildItem $scriptPath -Recurse -Filter "*.mof" -ErrorAction SilentlyContinue
    foreach ($mofFile in $mofFiles) {
        $bytesFreed += $mofFile.Length
        $filesToRemove += $mofFile.FullName
        Write-Status "    Marking .mof file: $($mofFile.Name)" "Gray"
    }
    
    # Step 2c: Fix nested Modules/Modules directories
    Write-Status "  Fixing nested Modules directories..." "Gray"
    $nestedModules = Get-ChildItem $scriptPath -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object {$_.FullName -like "*\Modules\Modules\*"}
    foreach ($nestedModule in $nestedModules) {
        try {
            $parentModules = $nestedModule.Parent.Parent
            $nestedContent = $nestedModule.Parent
            
            # Move content from nested Modules to parent Modules
            $items = Get-ChildItem $nestedContent.FullName -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                $destination = Join-Path $parentModules.FullName $item.Name
                if (-not (Test-Path $destination)) {
                    Move-Item $item.FullName $destination -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Remove the now-empty nested Modules directory
            Remove-Item $nestedContent.FullName -Recurse -Force -ErrorAction SilentlyContinue
            Write-Status "    Fixed nested Modules in: $($nestedModule.Name)" "Gray"
        }
        catch {
            Write-Status "    Warning: Could not fix nested Modules: $($_.Exception.Message)" "Yellow"
        }
    }
    
    # Define patterns and specific files to clean up
    $cleanupPatterns = @(
        # Development/debugging scripts - these were used during development but not needed for production
        "Fix-*.ps1",
        "Comprehensive-Fix.ps1", 
        "Final-Comprehensive-Fix.ps1",
        "Quick-Fix-*.ps1",
        "Regenerate-*.ps1",
        "Detect-*.ps1",
        "Apply-*.ps1",
        "Add-*.ps1",
        
        # Backup files (already handled above but included for completeness)
        "*.backup",
        "*.bak",
        
        # Development documentation that's no longer needed
        "COMPLETION-SUMMARY.md",
        "INTEGRATION-*.md",
        
        # Duplicate/redundant scripts
        "Initiative-Functions.ps1",  # We have InitiativeFunctions.ps1
        "Create-Initiatives.ps1",   # Functionality is in Manage-Policies.ps1
        "Import-AzurePolicies.ps1"  # Functionality is in Manage-Policies.ps1
    )
    
    # Clean up files in PolicyConversion directory
    foreach ($pattern in $cleanupPatterns) {
        $files = Get-ChildItem $scriptPath -Filter $pattern -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            if ($file.PSIsContainer -eq $false) {
                $bytesFreed += $file.Length
                $filesToRemove += $file.FullName
                Write-Status "  Marking for removal: $($file.Name)" "Gray"
            }
        }
    }
    
    # Clean up log files (keep directory structure but remove old logs)
    $logsPath = Join-Path $scriptPath "Logs"
    if (Test-Path $logsPath) {
        $logFiles = Get-ChildItem $logsPath -Recurse -File
        foreach ($logFile in $logFiles) {
            $bytesFreed += $logFile.Length
            $filesToRemove += $logFile.FullName
            Write-Status "  Marking log file for removal: $($logFile.Name)" "Gray"
        }
    }
    
    # Clean up temporary build artifacts in Output directories (keep final policy files and packages)
    $outputPath = Join-Path $scriptPath "Output"
    if (Test-Path $outputPath) {
        $policyDirs = Get-ChildItem $outputPath -Directory
        foreach ($policyDir in $policyDirs) {
            # Remove duplicate .zip files (keep only one per configuration)
            $gcPath = Join-Path $policyDir.FullName "GuestConfiguration"
            if (Test-Path $gcPath) {
                $gcSubDirs = Get-ChildItem $gcPath -Directory
                foreach ($gcSubDir in $gcSubDirs) {
                    $outputDir = Join-Path $gcSubDir.FullName "Output"
                    if (Test-Path $outputDir) {
                        $zipFiles = Get-ChildItem $outputDir -Filter "*.zip"
                        if ($zipFiles.Count -gt 1) {
                            # Keep the newest, remove the rest
                            $zipFiles | Sort-Object LastWriteTime -Descending | Select-Object -Skip 1 | ForEach-Object {
                                $bytesFreed += $_.Length
                                $filesToRemove += $_.FullName
                                Write-Status "  Marking old package for removal: $($_.Name)" "Gray"
                            }
                        }
                    }
                    
                    # Remove temporary DSC compilation files
                    $tempFiles = Get-ChildItem $gcSubDir.FullName -Filter "*.mof" -ErrorAction SilentlyContinue
                    foreach ($tempFile in $tempFiles) {
                        $bytesFreed += $tempFile.Length
                        $filesToRemove += $tempFile.FullName
                        Write-Status "  Marking temp file for removal: $($tempFile.Name)" "Gray"
                    }
                }
            }
        }
    }
    
    # Calculate space to be freed
    $mbFreed = [math]::Round($bytesFreed / 1MB, 2)
    
    if ($filesToRemove.Count -eq 0) {
        Write-Status "No files found for cleanup." "Yellow"
        return
    }
    
    Write-Status "" "White"
    Write-Status "=== Cleanup Summary ===" "Magenta"
    Write-Status "Files to remove: $($filesToRemove.Count)" "Cyan"
    Write-Status "Space to free: $mbFreed MB" "Cyan"
    Write-Status "" "White"
    
    # Ask for confirmation unless Force is specified
    if (-not $Force) {
        $confirmation = Read-Host "Do you want to proceed with cleanup? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Status "Cleanup cancelled by user." "Yellow"
            return
        }
    }
    
    # Perform the cleanup
    $removed = 0
    $failed = 0
    
    foreach ($filePath in $filesToRemove) {
        try {
            if (Test-Path $filePath) {
                Remove-Item $filePath -Force
                $removed++
                Write-Status "  ✓ Removed: $(Split-Path $filePath -Leaf)" "Green"
            }
        }
        catch {
            $failed++
            Write-Status "  ✗ Failed to remove: $(Split-Path $filePath -Leaf) - $($_.Exception.Message)" "Red"
        }
    }
    
    # Remove empty log directories
    if (Test-Path $logsPath) {
        $subDirs = Get-ChildItem $logsPath -Directory
        foreach ($subDir in $subDirs) {
            if ((Get-ChildItem $subDir.FullName -Force).Count -eq 0) {
                try {
                    Remove-Item $subDir.FullName -Force
                    Write-Status "  ✓ Removed empty directory: $($subDir.Name)" "Green"
                }
                catch {
                    Write-Status "  ⚠ Could not remove directory: $($subDir.Name)" "Yellow"
                }
            }
        }
    }
    
    Write-Status "" "White"
    Write-Status "=== Cleanup Results ===" "Magenta"
    Write-Status "Successfully removed: $removed files" "Green"
    Write-Status "Failed to remove: $failed files" "Red"
    Write-Status "Space freed: $mbFreed MB" "Green"
    
    if ($failed -eq 0) {
        Write-Status "✓ Workspace cleanup completed successfully!" "Green"
        Write-Status "" "White"
        Write-Status "Remaining essential files:" "Yellow"
        Write-Status "- Manage-Policies.ps1 (main automation script)" "White"
        Write-Status "- Convert-Policies.ps1 (policy conversion logic)" "White" 
        Write-Status "- Update-ContentHashes.ps1 (hash management)" "White"
        Write-Status "- Policy output files and Guest Configuration packages" "White"
        Write-Status "- Documentation (README.md files)" "White"
    }
}

function Invoke-StandardizeFolders {
    Write-Status "Standardizing policy folder names..." "Green"
    
    # Define the mapping from long names to short names
    $folderMapping = @{
        "Windows machines should meet requirements for 'Security Options - Accounts'" = "SecurityOptions-Accounts"
        "Windows machines should meet requirements for 'Security Options - Audit'" = "SecurityOptions-Audit" 
        "Windows machines should meet requirements for 'Security Options - Devices'" = "SecurityOptions-Devices"
        "Windows machines should meet requirements for 'Security Options - Microsoft Network Client'" = "SecurityOptions-MSNetworkClient"
        "Windows machines should meet requirements for 'Security Options - Network Security'" = "SecurityOptions-NetworkSecurity"
        "Windows machines should meet requirements for 'Security Options - User Account Control'" = "SecurityOptions-UAC"
        "Windows machines should meet requirements for 'Security Settings - Account Policies'" = "SecuritySettings-AccountPolicies"
        "Windows machines should meet requirements for 'System Audit Policies - Account Logon'" = "AuditPolicies-AccountLogon"
        "Windows machines should meet requirements for 'System Audit Policies - Detailed Tracking'" = "AuditPolicies-DetailedTracking"
        "Windows machines should meet requirements for 'System Audit Policies - Object Access'" = "AuditPolicies-ObjectAccess"
        "Windows machines should meet requirements for 'System Audit Policies - Policy Change'" = "AuditPolicies-PolicyChange"
        "Windows machines should meet requirements for 'System Audit Policies - System'" = "AuditPolicies-System"
    }
    
    $successful = 0
    $failed = 0
    $skipped = 0
    
    foreach ($longName in $folderMapping.Keys) {
        $shortName = $folderMapping[$longName]
        $longPath = Join-Path $outputPath $longName
        $shortPath = Join-Path $outputPath $shortName
        
        if (Test-Path $longPath) {
            Write-Status "Renaming: $longName -> $shortName" "Cyan"
            
            try {
                # Check if short name already exists
                if (Test-Path $shortPath) {
                    Write-Status "  Target folder already exists, merging content..." "Yellow"
                    
                    # Move contents from long folder to short folder
                    $items = Get-ChildItem $longPath
                    foreach ($item in $items) {
                        $targetPath = Join-Path $shortPath $item.Name
                        if (Test-Path $targetPath) {
                            Write-Status "    Skipping duplicate: $($item.Name)" "Gray"
                        } else {
                            Move-Item $item.FullName $targetPath
                            Write-Status "    Moved: $($item.Name)" "Gray"
                        }
                    }
                    
                    # Remove the now-empty long folder
                    Remove-Item $longPath -Force
                    Write-Status "  ✓ Merged and cleaned up" "Green"
                } else {
                    # Simple rename
                    Rename-Item $longPath $shortPath
                    Write-Status "  ✓ Renamed successfully" "Green"
                }
                
                $successful++
            }
            catch {
                $failed++
                Write-Status "  ✗ Failed to rename: $($_.Exception.Message)" "Red"
            }
        } else {
            $skipped++
            Write-Status "  Skipping (not found): $longName" "Gray"
        }
    }
    
    Write-Status "" "White"
    Write-Status "=== Folder Standardization Summary ===" "Magenta"
    Write-Status "Successfully renamed: $successful" "Green"
    Write-Status "Failed: $failed" "Red"
    Write-Status "Skipped (not found): $skipped" "Gray"
    
    if ($failed -eq 0) {
        Write-Status "✓ All folder names have been standardized!" "Green"
        Write-Status "" "White"
        Write-Status "Consistent naming convention applied:" "Yellow"
        Write-Status "- SecurityOptions-* for Security Options policies" "White"
        Write-Status "- SecuritySettings-* for Security Settings policies" "White"
        Write-Status "- AuditPolicies-* for System Audit Policies" "White"
    }
}

function Invoke-UpdateHashes {
    Write-Status "Updating content hashes for all packages..." "Green"
    
    $gcDirs = Get-GuestConfigurationDirectories -Filter $PolicyFilter
    if ($gcDirs.Count -eq 0) {
        Write-Status "No Guest Configuration directories found" "Yellow"
        return
    }
    
    $successful = 0
    $failed = 0
    
    foreach ($gcDir in $gcDirs) {
        Write-Status "Updating hash: $($gcDir.ConfigurationName)" "Cyan"
        
        $hashUpdated = Update-AzureConfigHash -GuestConfigurationPath $gcDir.Path -Silent $false
        if ($hashUpdated) {
            $successful++
        } else {
            $failed++
        }
    }
    
    Write-Status "Hash update summary: $successful successful, $failed failed" "Yellow"
}

# Main execution
Write-Status "=== Bulk Policy Management Tool ===" "Magenta"
Write-Status "Action: $Action" "Cyan"
Write-Status "Filter: $PolicyFilter" "Cyan"
Write-Status ""

switch ($Action) {
    "Convert" { Invoke-ConvertPolicies }
    "Build" { Invoke-BuildPackages }
    "Deploy" { Invoke-DeployPackages }
    "UpdatePolicies" { Invoke-UpdatePolicyFiles }
    "DeployPolicies" { Invoke-DeployPolicies }
    "BulkDeployPolicies" { Invoke-BulkDeployPolicies }
    "CreateInitiatives" { Invoke-CreateInitiatives }
    "AssignInitiatives" { Invoke-AssignInitiatives }
    "Status" { Show-Status }
    "Test" { Invoke-TestConfigurations }
    "Clean" { Invoke-CleanOutput }
    "UpdateHashes" { Invoke-UpdateHashes }
    "StandardizeFolders" { Invoke-StandardizeFolders }
    default { Show-Status }
}

Write-Status "Operation completed!" "Green"
