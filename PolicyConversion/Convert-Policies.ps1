# Convert Azure Policies from AuditIfNotExists to DeployIfNotExists with Guest Configuration
# This script automates the conversion of multiple policies to the Guest Configuration format

param(
    [Parameter(Mandatory = $false, HelpMessage = "Build all Guest Configuration packages")]
    [switch]$BuildAll,
    
    [Parameter(Mandatory = $false, HelpMessage = "Deploy all packages to Azure Storage")]
    [switch]$DeployAll,
    
    [Parameter(Mandatory = $false, HelpMessage = "Update all policy files with new hashes")]
    [switch]$UpdatePolicyFiles,
    
    [Parameter(Mandatory = $false, HelpMessage = "Deploy all policies to Azure")]
    [switch]$DeployPolicies,
    
    [Parameter(Mandatory = $false, HelpMessage = "Specific policy to process")]
    [string]$PolicyName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Force rebuild/overwrite")]
    [switch]$Force
)

# Set up paths
$scriptPath = $PSScriptRoot
$inputPath = Join-Path $scriptPath "Input"
$outputPath = Join-Path $scriptPath "Output"
$templatesPath = Join-Path $scriptPath "Templates"

# Configuration
$config = @{
    SubscriptionId = "e749c27d-1157-4753-929c-adfddb9c814c"
    StorageAccount = @{
        Name = "saserverhardeningdkleac"
        ResourceGroupName = "RG_ARC_Local_All_RestoreTest"
        ContainerName = "guestconfiguration"
    }
    Deployment = @{
        TargetResourceGroup = "RG_ARC_Local_All_RestoreTest"
        Location = "westeurope"
    }
}

# Function to convert policy name to configuration name
function ConvertTo-ConfigurationName {
    param([string]$PolicyName)
    
    # Remove common words and clean up
    $cleanName = $PolicyName -replace "Windows machines should meet requirements for", ""
    $cleanName = $cleanName -replace "the ", ""
    $cleanName = $cleanName -replace "'", ""
    $cleanName = $cleanName -replace "\s+", " "
    $cleanName = $cleanName.Trim()
    
    # Convert to PascalCase
    $words = $cleanName -split "[\s\-\(\)]" | Where-Object { $_ -ne "" }
    $configName = "AzureBaseline_" + (($words | ForEach-Object { 
        $word = $_.Trim()
        if ($word.Length -gt 0) {
            $word.Substring(0,1).ToUpper() + $word.Substring(1).ToLower()
        }
    }) -join "")
    
    return $configName
}

# Function to convert parameter values based on policy type
function Convert-ParameterValue {
    param(
        [string]$ParameterName,
        [string]$ParameterValue,
        [string]$PolicyType
    )
    
    # For SecurityPolicy resources, convert 0/1 to Enabled/Disabled
    if ($PolicyType -eq "SecurityPolicy") {
        switch ($ParameterValue) {
            "0" { return "Disabled" }
            "1" { return "Enabled" }
            default { return $ParameterValue }
        }
    }
    
    # For AuditPolicy resources, ensure proper audit flags
    if ($PolicyType -eq "AuditPolicy") {
        switch ($ParameterValue) {
            "No Auditing" { return "No Auditing" }
            "Success" { return "Success" }
            "Failure" { return "Failure" }
            "Success and Failure" { return "Success and Failure" }
            default { return $ParameterValue }
        }
    }
    
    return $ParameterValue
}

# Function to determine policy type based on policy name
function Get-PolicyType {
    param([string]$PolicyName)
    
    if ($PolicyName -like "*System Audit Policies*") {
        return "AuditPolicy"
    } elseif ($PolicyName -like "*Security Options*") {
        return "SecurityPolicy"
    } elseif ($PolicyName -like "*User Rights Assignment*") {
        return "UserRightsAssignment"
    } elseif ($PolicyName -like "*Administrative Templates*") {
        return "Registry"
    } elseif ($PolicyName -like "*Security Settings*") {
        return "SecurityPolicy"
    } elseif ($PolicyName -like "*Windows Firewall*") {
        return "Registry"
    } elseif ($PolicyName -like "*Windows Components*") {
        return "Registry"
    } else {
        return "Registry"  # Default to Registry for most policies
    }
}

# Function to extract parameters from original policy
function Get-PolicyParameters {
    param([PSObject]$Policy)
    
    $parameters = @()
    if ($Policy.properties.parameters) {
        $allParams = @()
        foreach ($param in $Policy.properties.parameters.PSObject.Properties) {
            if ($param.Name -notmatch "^(IncludeArcMachines|effect|assignmentType)$") {
                $allParams += @{
                    Name = $param.Name
                    Type = $param.Value.type
                    DisplayName = $param.Value.metadata.displayName
                    Description = $param.Value.metadata.description
                    AllowedValues = $param.Value.allowedValues
                    DefaultValue = $param.Value.defaultValue
                }
            }
        }
        
        # Limit to 17 parameters (leaving room for 3 essential parameters: IncludeArcMachines, assignmentType, effect)
        if ($allParams.Count -gt 17) {
            Write-Host "  Policy has $($allParams.Count) parameters, limiting to 17 (Azure Policy max is 20)" -ForegroundColor Yellow
            $parameters = $allParams | Select-Object -First 17
        } else {
            $parameters = $allParams
        }
    }
    return $parameters
}

# Function to generate DSC configuration
function New-DSCConfiguration {
    param(
        [string]$ConfigurationName,
        [array]$Parameters
    )
    
    $template = Get-Content (Join-Path $templatesPath "DSC-Configuration.ps1.template") -Raw
    
    # Generate parameters with proper value transformation
    $parameterBlock = ""
    $policyType = Get-PolicyType -PolicyName $ConfigurationName
    
    foreach ($param in $Parameters) {
        $convertedValue = Convert-ParameterValue -ParameterName $param.Name -ParameterValue $param.DefaultValue -PolicyType $policyType
        $parameterBlock += "        [Parameter()]`r`n"
        $parameterBlock += "        [string]`$$($param.Name) = '$convertedValue',`r`n`r`n"
    }
    $parameterBlock = $parameterBlock.TrimEnd(",`r`n")
    
    # Generate DSC resources (placeholder - will need customization per policy type)
    $dscResources = ""
    foreach ($param in $Parameters) {
        $dscResources += "        # TODO: Add appropriate DSC resource for $($param.Name)`r`n"
        $dscResources += "        # Example:`r`n"
        $dscResources += "        # Registry '$($param.Name)'`r`n"
        $dscResources += "        # {`r`n"
        $dscResources += "        #     Key = 'HKEY_LOCAL_MACHINE\Software\Example'`r`n"
        $dscResources += "        #     ValueName = '$($param.Name)'`r`n"
        $dscResources += "        #     ValueData = `$$($param.Name)`r`n"
        $dscResources += "        #     ValueType = 'String'`r`n"
        $dscResources += "        #     Ensure = 'Present'`r`n"
        $dscResources += "        # }`r`n`r`n"
    }
    
    # Replace placeholders
    $content = $template -replace "{CONFIGURATION_NAME}", $ConfigurationName
    $content = $content -replace "{PARAMETERS}", $parameterBlock
    $content = $content -replace "{DSC_MODULE_NAME}", "PSDesiredStateConfiguration"
    $content = $content -replace "{DSC_RESOURCES}", $dscResources
    
    return $content
}

# Function to generate DeployIfNotExists policy
function New-DeployIfNotExistsPolicy {
    param(
        [PSObject]$OriginalPolicy,
        [string]$ConfigurationName,
        [array]$Parameters,
        [string]$PolicyName
    )
    
    $template = Get-Content (Join-Path $templatesPath "DeployIfNotExists.json.template") -Raw
    
    # Generate display name
    $displayName = $OriginalPolicy.properties.displayName -replace "\[AuditIfNotExists\]", "[DeployIfNotExists]"
    if ($displayName -notmatch "\[DeployIfNotExists\]") {
        $displayName = "[GG Serverhardening] [DeployIfNotExists] " + $displayName
    }
    
    # Generate description
    $description = $OriginalPolicy.properties.description -replace "audit", "configure"
    $description = $description -replace "compliance", "Guest Configuration assignment"
    $description = "Deploys Guest Configuration assignment to Windows machines to configure " + $description
    
    # Generate policy parameters
    $policyParameters = ""
    foreach ($param in $Parameters) {
        $policyParameters += "      `"$($param.Name)`": {`r`n"
        $policyParameters += "        `"type`": `"$($param.Type)`",`r`n"
        $policyParameters += "        `"metadata`": {`r`n"
        $policyParameters += "          `"displayName`": `"$($param.DisplayName)`",`r`n"
        $policyParameters += "          `"description`": `"$($param.Description)`"`r`n"
        $policyParameters += "        },`r`n"
        if ($param.AllowedValues) {
            $allowedValues = ($param.AllowedValues | ForEach-Object { "`"$_`"" }) -join ", "
            $policyParameters += "        `"allowedValues`": [$allowedValues],`r`n"
        }
        # Properly escape the default value for JSON
        if ($param.DefaultValue -ne $null) {
            $escapedDefaultValue = $param.DefaultValue -replace '\\', '\\\\' -replace '"', '\"' -replace "`r", '' -replace "`n", ''
            $policyParameters += "        `"defaultValue`": `"$escapedDefaultValue`"`r`n"
        } else {
            $policyParameters += "        `"defaultValue`": `"`"`r`n"
        }
        $policyParameters += "      },`r`n"
    }
    $policyParameters = $policyParameters.TrimEnd(",`r`n")
    
    # Generate configuration parameters
    $configurationParameters = ""
    foreach ($param in $Parameters) {
        $dscMapping = Get-DSCParameterMapping -ParameterName $param.Name -PolicyName $PolicyName -InputPolicy $OriginalPolicy
        $configurationParameters += "          `"$($param.Name)`": `"$dscMapping`",`r`n"
    }
    $configurationParameters = $configurationParameters.TrimEnd(",`r`n")
    
    # Generate other template sections
    $parameterHashConcat = ($Parameters | ForEach-Object { 
        $dscMapping = Get-DSCParameterMapping -ParameterName $_.Name -PolicyName $PolicyName -InputPolicy $OriginalPolicy
        "'$dscMapping', '=', parameters('$($_.Name)')" 
    }) -join ", ',', "
    
    $deploymentParameters = ""
    $templateParameters = ""
    $configurationParameterArray = ""
    
    foreach ($param in $Parameters) {
        $deploymentParameters += "                `"$($param.Name)`": {`r`n"
        $deploymentParameters += "                  `"value`": `"[parameters('$($param.Name)')]`"`r`n"
        $deploymentParameters += "                },`r`n"
        
        $templateParameters += "                  `"$($param.Name)`": {`r`n"
        $templateParameters += "                    `"type`": `"string`"`r`n"
        $templateParameters += "                  },`r`n"
        
        $configurationParameterArray += "                          {`r`n"
        $dscMapping = Get-DSCParameterMapping -ParameterName $param.Name -PolicyName $PolicyName -InputPolicy $OriginalPolicy
        $configurationParameterArray += "                            `"name`": `"$dscMapping`",`r`n"
        $configurationParameterArray += "                            `"value`": `"[parameters('$($param.Name)')]`"`r`n"
        $configurationParameterArray += "                          },`r`n"
    }
    
    $deploymentParameters = $deploymentParameters.TrimEnd(",`r`n")
    $templateParameters = $templateParameters.TrimEnd(",`r`n")
    $configurationParameterArray = $configurationParameterArray.TrimEnd(",`r`n")
    
    # Handle comma placement for deployment parameters
    # Only need a comma after configurationName if there are deployment parameters
    if ($Parameters.Count -gt 0) {
        $deploymentParametersComma = ","
        # When there are deployment parameters, add a newline before the first parameter
        if ($deploymentParameters -and -not $deploymentParameters.StartsWith("`r`n")) {
            $deploymentParameters = "`r`n" + $deploymentParameters
        }
        # Add comma after the last deployment parameter since assignmentType follows
        $deploymentParameters = $deploymentParameters + ",`r`n"
    } else {
        $deploymentParametersComma = ","
    }
    
    # Handle comma placement for template parameters
    # Always need a comma before assignmentType
    if ($Parameters.Count -gt 0) {
        # When there are template parameters, add a newline before the first parameter and comma after
        if ($templateParameters -and -not $templateParameters.StartsWith("`r`n")) {
            $templateParameters = "`r`n" + $templateParameters
        }
        # Add comma after template parameters since assignmentType follows
        $templateParameters = $templateParameters + ",`r`n"
    } else {
        # When there are no template parameters, we still need the existing comma
        $templateParameters = ""
    }
    
    # Handle comma placement for parameters
    # Always need a comma after IncludeArcMachines since assignmentType follows
    $policyParametersComma = ","
    
    # When there are parameters, add a newline before the first parameter
    if ($Parameters.Count -gt 0) {
        if ($policyParameters -and -not $policyParameters.StartsWith("`r`n")) {
            $policyParameters = "`r`n" + $policyParameters
        }
        # Add comma after the last user parameter since assignmentType follows
        $policyParameters = $policyParameters + ",`r`n"
    }
    
    # Replace placeholders
    $content = $template -replace "{DISPLAY_NAME}", $displayName
    $content = $content -replace "{DESCRIPTION}", $description
    $content = $content -replace "{CONFIGURATION_NAME}", $ConfigurationName
    $content = $content -replace "{CONFIGURATION_PARAMETERS}", $configurationParameters
    $content = $content -replace "{CONTENT_URI}", "https://saserverhardeningdkleac.blob.core.windows.net/guestconfiguration/$ConfigurationName.zip"
    $content = $content -replace "{CONTENT_HASH}", "PLACEHOLDER_HASH"
    $content = $content -replace "{POLICY_PARAMETERS_COMMA}", $policyParametersComma
    $content = $content -replace "{POLICY_PARAMETERS}", $policyParameters
    $content = $content -replace "{PARAMETER_HASH_CONCAT}", $parameterHashConcat
    $content = $content -replace "{DEPLOYMENT_PARAMETERS}", $deploymentParameters
    $content = $content -replace "{TEMPLATE_PARAMETERS}", $templateParameters
    $content = $content -replace "{CONFIGURATION_PARAMETER_ARRAY}", $configurationParameterArray
    $content = $content -replace "{DEPLOYMENT_PARAMETERS_COMMA}", $deploymentParametersComma
    
    return $content
}

# Function to create supporting files
function New-SupportingFiles {
    param(
        [string]$OutputDir,
        [string]$ConfigurationName
    )
    
    # Copy and customize supporting files from the working example
    $sourceDir = Join-Path $scriptPath "..\GuestConfiguration\AzureBaseline_SystemAuditPoliciesObjectAccess"
    $targetDir = Join-Path $OutputDir "GuestConfiguration\$ConfigurationName"
    
    # Create directory structure
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetDir "Output") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetDir "Modules") -Force | Out-Null
    
    # Copy template files
    $filesToCopy = @(
        "Build-And-Deploy-Package.ps1",
        "Deploy-GuestConfigurationPackage.ps1",
        "Test-Configuration.ps1",
        "Update-PolicyFiles.ps1",
        "Fix-GuestConfigurationPackage.ps1",
        "Setup-Prerequisites.ps1",
        "README.md"
    )
    
    foreach ($file in $filesToCopy) {
        $sourceFile = Join-Path $sourceDir $file
        $targetFile = Join-Path $targetDir $file
        if (Test-Path $sourceFile) {
            Copy-Item $sourceFile $targetFile -Force
            
            # Update configuration name in files
            $content = Get-Content $targetFile -Raw
            $content = $content -replace "AzureBaseline_SystemAuditPoliciesObjectAccess", $ConfigurationName
            Set-Content $targetFile $content
        }
    }
    
    # Create azure-config.json
    $azureConfig = @{
        Location = $config.Deployment.Location
        SubscriptionId = $config.SubscriptionId
        CreatedDate = (Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
        StorageAccount = $config.StorageAccount
        Deployment = $config.Deployment
        Policy = @{
            AuditPolicyName = "GG-Audit-" + ($ConfigurationName -replace "AzureBaseline_", "")
            DeployPolicyName = "GG-Deploy-" + ($ConfigurationName -replace "AzureBaseline_", "")
        }
        Package = @{
            Name = $ConfigurationName
            Version = "1.0.0.0"
            CurrentContentHash = "PLACEHOLDER_HASH"
        }
    }
    
    $azureConfig | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $targetDir "azure-config.json")
    
    # Copy basic DSC modules (will need customization per policy)
    Copy-Item (Join-Path $sourceDir "Modules") (Join-Path $targetDir "Modules") -Recurse -Force
}

# Function to generate Test-Configuration.ps1 with proper parameter blocks
function New-TestConfiguration {
    param(
        [string]$ConfigurationName,
        [array]$Parameters,
        [string]$PolicyName
    )
    
    $template = Get-Content (Join-Path $templatesPath "Test-Configuration.ps1.template") -Raw
    
    # Generate policy parameters for the param block
    $policyParameters = ""
    $parameterDisplay = ""
    $configParameters = ""
    $powershellParameters = ""
    $exampleUsage = ""
    
    foreach ($param in $Parameters) {
        $policyParameters += ",`n`n    [Parameter(Mandatory = `$false)]`n"
        $policyParameters += "    [string]`$$($param.Name) = '$($param.DefaultValue)'"
        
        $parameterDisplay += "`nWrite-Host `"  $($param.Name): `$$($param.Name)`" -ForegroundColor Yellow"
        $configParameters += "`n        '$($param.Name)' = `$$($param.Name)"
        $powershellParameters += "`n    '$($param.Name)' = '0'"
        $exampleUsage += "`n  Test with custom parameter:`n    .\\Test-Configuration.ps1 -$($param.Name) 'CustomValue' -AssignmentType 'ApplyAndMonitor'"
    }
    
    # Clean up policy name for display
    $cleanPolicyName = $PolicyName -replace "Windows machines should meet requirements for ", ""
    $cleanPolicyName = $cleanPolicyName -replace "'", ""
    
    # Replace placeholders
    $content = $template -replace "\{CONFIGURATION_NAME\}", $ConfigurationName
    $content = $content -replace "\{POLICY_PARAMETERS\}", $policyParameters
    $content = $content -replace "\{PARAMETER_DISPLAY\}", $parameterDisplay
    $content = $content -replace "\{CONFIG_PARAMETERS\}", $configParameters
    $content = $content -replace "\{POWERSHELL_PARAMETERS\}", $powershellParameters
    $content = $content -replace "\{POLICY_NAME\}", ($ConfigurationName -replace "AzureBaseline_", "")
    $content = $content -replace "\{EXAMPLE_USAGE\}", $exampleUsage
    
    return $content
}

# Function to map policy parameter names to DSC resource parameter names
function Get-DSCParameterMapping {
    param(
        [string]$ParameterName,
        [string]$PolicyName,
        [object]$InputPolicy
    )
    
    # First, try to get the exact mapping from the input policy's configurationParameter
    if ($InputPolicy.properties.metadata.guestConfiguration.configurationParameter) {
        foreach ($property in $InputPolicy.properties.metadata.guestConfiguration.configurationParameter.PSObject.Properties) {
            if ($property.Name -eq $ParameterName) {
                Write-Host "  Found exact mapping for $ParameterName -> $($property.Value)" -ForegroundColor Green
                return $property.Value
            }
        }
    }
    
    # Fallback to algorithmic mapping (for completeness, but should not be needed)
    Write-Warning "No exact mapping found for parameter $ParameterName in policy $PolicyName, using fallback"
    
    # Security Options mapping
    if ($PolicyName -like "*Security Options*") {
        # Convert parameter name to Security Option property name
        $propertyName = $ParameterName
        
        # Handle specific mappings for Security Options
        $mappings = @{
            'ShutdownAllowSystemToBeShutDownWithoutHavingToLogOn' = 'Shutdown_Allow_system_to_be_shut_down_without_having_to_log_on'
            'ShutdownClearVirtualMemoryPagefile' = 'Shutdown_Clear_virtual_memory_pagefile'
            # Add more mappings as needed based on existing DSC configurations
        }
        
        if ($mappings.ContainsKey($ParameterName)) {
            return "SecurityOption;$($mappings[$ParameterName])"
        } else {
            # Fallback: convert camelCase to snake_case for Security Options
            $snakeCase = $ParameterName -creplace '([A-Z])', '_$1'
            $snakeCase = $snakeCase.TrimStart('_').ToLower()
            return "SecurityOption;$snakeCase"
        }
    }
    
    # Audit Policies mapping
    if ($PolicyName -like "*Audit Policies*") {
        # Convert to AuditPolicy resource parameter
        $auditProperty = $ParameterName -replace '^Audit', ''
        return "AuditPolicy;$auditProperty"
    }
    
    # User Rights Assignment mapping
    if ($PolicyName -like "*User Rights*") {
        return "UserRightsAssignment;$ParameterName"
    }
    
    # Registry-based policies (Administrative Templates, Windows Components, etc.)
    if ($PolicyName -like "*Administrative Templates*" -or $PolicyName -like "*Windows Components*" -or $PolicyName -like "*Windows Firewall*") {
        return "Registry;$ParameterName"
    }
    
    # Security Settings mapping
    if ($PolicyName -like "*Security Settings*") {
        return "SecurityPolicy;$ParameterName"
    }
    
    # Default fallback
    return "Registry;$ParameterName"
}

# Main conversion function
function Convert-Policy {
    param(
        [string]$PolicyFile,
        [string]$PolicyName
    )
    
    Write-Host "Converting policy: $PolicyName" -ForegroundColor Green
    
    # Load original policy
    $originalPolicy = Get-Content $PolicyFile | ConvertFrom-Json
    
    # Extract information
    $configurationName = ConvertTo-ConfigurationName $originalPolicy.properties.displayName
    $parameters = Get-PolicyParameters $originalPolicy
    
    Write-Host "  Configuration name: $configurationName" -ForegroundColor Cyan
    Write-Host "  Found $($parameters.Count) parameters" -ForegroundColor Cyan
    
    # Create output directory
    $policyOutputDir = Join-Path $outputPath $PolicyName
    New-Item -ItemType Directory -Path $policyOutputDir -Force | Out-Null
    
    # Generate AuditIfNotExists policy (copy original with naming convention)
    $auditPolicy = $originalPolicy
    $auditPolicy.properties.displayName = $auditPolicy.properties.displayName -replace "Windows machines should meet requirements for", ""
    $auditPolicy.properties.displayName = "[GG Serverhardening] [AuditIfNotExists] Windows machines should meet requirements for" + $auditPolicy.properties.displayName
    $auditPolicy | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $policyOutputDir "AuditIfNotExists - $PolicyName.json")
    
    # Generate DeployIfNotExists policy
    $deployPolicy = New-DeployIfNotExistsPolicy -OriginalPolicy $originalPolicy -ConfigurationName $configurationName -Parameters $parameters -PolicyName $policyName
    $deployPolicy | Set-Content (Join-Path $policyOutputDir "DeployIfNotExists - $PolicyName.json")
    
    # Generate DSC configuration
    $dscConfiguration = New-DSCConfiguration -ConfigurationName $configurationName -Parameters $parameters
    $gcDir = Join-Path $policyOutputDir "GuestConfiguration\$configurationName"
    New-Item -ItemType Directory -Path $gcDir -Force | Out-Null
    $dscConfiguration | Set-Content (Join-Path $gcDir "$configurationName.ps1")
    
    # Generate Test-Configuration script
    $testConfiguration = New-TestConfiguration -ConfigurationName $configurationName -Parameters $parameters -PolicyName $PolicyName
    $testConfiguration | Set-Content (Join-Path $gcDir "Test-Configuration.ps1")
    
    # Create supporting files
    New-SupportingFiles -OutputDir $policyOutputDir -ConfigurationName $configurationName
    
    Write-Host "  ✓ Policy converted successfully" -ForegroundColor Green
    Write-Host "  ✓ Generated files in: $policyOutputDir" -ForegroundColor Green
    Write-Host "  ⚠ Manual customization required for DSC resources" -ForegroundColor Yellow
    Write-Host ""
}

# Bulk operations
function Invoke-BulkOperation {
    param(
        [string]$Operation
    )
    
    $policyDirs = Get-ChildItem $outputPath -Directory
    
    foreach ($policyDir in $policyDirs) {
        $gcDirs = Get-ChildItem (Join-Path $policyDir.FullName "GuestConfiguration") -Directory -ErrorAction SilentlyContinue
        
        foreach ($gcDir in $gcDirs) {
            $buildScript = Join-Path $gcDir.FullName "Build-And-Deploy-Package.ps1"
            
            if (Test-Path $buildScript) {
                Write-Host "Processing: $($gcDir.Name)" -ForegroundColor Green
                
                switch ($Operation) {
                    "Build" {
                        & $buildScript -Force
                    }
                    "Deploy" {
                        & $buildScript -Deploy -UpdatePolicyFiles
                    }
                    "UpdatePolicyFiles" {
                        & $buildScript -UpdatePolicyFiles
                    }
                }
            }
        }
    }
}

# Main execution
Write-Host "=== Azure Policy Conversion Tool ===" -ForegroundColor Magenta
Write-Host "Input directory: $inputPath" -ForegroundColor Gray
Write-Host "Output directory: $outputPath" -ForegroundColor Gray
Write-Host ""

# Execute bulk operations
if ($BuildAll) {
    Write-Host "Building all Guest Configuration packages..." -ForegroundColor Yellow
    Invoke-BulkOperation "Build"
    exit
}

if ($DeployAll) {
    Write-Host "Deploying all packages to Azure Storage..." -ForegroundColor Yellow
    Invoke-BulkOperation "Deploy"
    exit
}

if ($UpdatePolicyFiles) {
    Write-Host "Updating all policy files..." -ForegroundColor Yellow
    Invoke-BulkOperation "UpdatePolicyFiles"
    exit
}

if ($DeployPolicies) {
    Write-Host "Deploying all policies to Azure..." -ForegroundColor Yellow
    & (Join-Path $scriptPath "..\Deploy-Policies-PowerShell.ps1")
    exit
}

# Process individual policy or all policies
if ($PolicyName) {
    $policyFile = Join-Path $inputPath "$PolicyName.json"
    if (Test-Path $policyFile) {
        Convert-Policy -PolicyFile $policyFile -PolicyName $PolicyName
    } else {
        Write-Error "Policy file not found: $policyFile"
    }
} else {
    # Process all policies in input directory
    $policyFiles = Get-ChildItem $inputPath -Filter "*.json"
    
    if ($policyFiles.Count -eq 0) {
        Write-Warning "No policy files found in $inputPath"
        Write-Host "Please place your AuditIfNotExists policy JSON files in the Input directory and run again."
        return
    }
    
    Write-Host "Found $($policyFiles.Count) policy files to convert..." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($policyFile in $policyFiles) {
        $policyName = $policyFile.BaseName
        Convert-Policy -PolicyFile $policyFile.FullName -PolicyName $policyName
    }
    
    Write-Host "=== Conversion Summary ===" -ForegroundColor Green
    Write-Host "✓ Converted $($policyFiles.Count) policies" -ForegroundColor Green
    Write-Host "✓ Generated Guest Configuration packages" -ForegroundColor Green
    Write-Host "⚠ Manual customization required:" -ForegroundColor Yellow
    Write-Host "  - Review and customize DSC resources in each configuration" -ForegroundColor Yellow
    Write-Host "  - Update DSC module references as needed" -ForegroundColor Yellow
    Write-Host "  - Test configurations locally before deployment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Customize DSC resources for each policy type" -ForegroundColor Gray
    Write-Host "  2. Run: .\Convert-Policies.ps1 -BuildAll" -ForegroundColor Gray
    Write-Host "  3. Run: .\Convert-Policies.ps1 -DeployAll" -ForegroundColor Gray
    Write-Host "  4. Run: .\Convert-Policies.ps1 -DeployPolicies" -ForegroundColor Gray
}
