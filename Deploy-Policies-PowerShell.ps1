# Deploy Azure Policies using Azure PowerShell
# This script uploads the policy definitions to Azure Policy

param(
    [Parameter(Mandatory = $false, HelpMessage = "Azure Subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Management Group ID (if deploying to management group)")]
    [string]$ManagementGroupId
)

# Import required modules
$requiredModules = @('Az.Accounts', 'Az.Resources')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Force -Scope CurrentUser
    }
    Import-Module $module
}

try {
    # Connect to Azure
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
    
    # Set subscription if provided
    if ($SubscriptionId) {
        Write-Host "Setting subscription to: $SubscriptionId" -ForegroundColor Green
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    
    # Define policy files
    $auditPolicyFile = ".\AuditIfNotExists - Windows machines should meet requirements for 'System Audit Policies - Object Access'.json"
    $deployPolicyFile = ".\DeployIfNotExists - Windows machines should meet requirements for 'System Audit Policies - Object Access'.json"
    
    # Check if files exist
    if (-not (Test-Path $auditPolicyFile)) {
        Write-Error "AuditIfNotExists policy file not found: $auditPolicyFile"
        exit 1
    }
    
    if (-not (Test-Path $deployPolicyFile)) {
        Write-Error "DeployIfNotExists policy file not found: $deployPolicyFile"
        exit 1
    }
    
    Write-Host "Deploying policy definitions..." -ForegroundColor Green
    
    # Deploy AuditIfNotExists Policy
    Write-Host "Deploying AuditIfNotExists policy..." -ForegroundColor Cyan
    $auditPolicyContent = Get-Content $auditPolicyFile -Raw | ConvertFrom-Json
    $auditPolicyName = "GG-Audit-SystemAuditPolicies-ObjectAccess"
    
    # Remove version property if it exists (Azure Policy manages this automatically)
    if ($auditPolicyContent.properties.PSObject.Properties['version']) {
        $auditPolicyContent.properties.PSObject.Properties.Remove('version')
    }
    
    $auditPolicyParams = @{
        Name = $auditPolicyName
        DisplayName = $auditPolicyContent.properties.displayName
        Description = $auditPolicyContent.properties.description
        Policy = ($auditPolicyContent | ConvertTo-Json -Depth 20)
        Metadata = ($auditPolicyContent.properties.metadata | ConvertTo-Json -Depth 10)
        Parameter = ($auditPolicyContent.properties.parameters | ConvertTo-Json -Depth 10)
    }
    
    if ($ManagementGroupId) {
        $auditPolicyParams.ManagementGroupName = $ManagementGroupId
    }
    
    try {
        # Check if policy already exists
        $existingPolicy = Get-AzPolicyDefinition -Name $auditPolicyName -ErrorAction SilentlyContinue
        if ($existingPolicy) {
            Write-Host "Policy already exists, updating..." -ForegroundColor Yellow
            $auditPolicy = Set-AzPolicyDefinition @auditPolicyParams
            Write-Host "✓ AuditIfNotExists policy updated successfully" -ForegroundColor Green
        } else {
            $auditPolicy = New-AzPolicyDefinition @auditPolicyParams
            Write-Host "✓ AuditIfNotExists policy created successfully" -ForegroundColor Green
        }
        Write-Host "Policy ID: $($auditPolicy.Id)" -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to create/update AuditIfNotExists policy: $($_.Exception.Message)"
        exit 1
    }
    
    # Deploy DeployIfNotExists Policy
    Write-Host "Deploying DeployIfNotExists policy..." -ForegroundColor Cyan
    $deployPolicyContent = Get-Content $deployPolicyFile -Raw | ConvertFrom-Json
    $deployPolicyName = "GG-Deploy-SystemAuditPolicies-ObjectAccess"
    
    # Remove version property if it exists (Azure Policy manages this automatically)
    if ($deployPolicyContent.properties.PSObject.Properties['version']) {
        $deployPolicyContent.properties.PSObject.Properties.Remove('version')
    }
    
    $deployPolicyParams = @{
        Name = $deployPolicyName
        DisplayName = $deployPolicyContent.properties.displayName
        Description = $deployPolicyContent.properties.description
        Policy = ($deployPolicyContent | ConvertTo-Json -Depth 20)
        Metadata = ($deployPolicyContent.properties.metadata | ConvertTo-Json -Depth 10)
        Parameter = ($deployPolicyContent.properties.parameters | ConvertTo-Json -Depth 10)
    }
    
    if ($ManagementGroupId) {
        $deployPolicyParams.ManagementGroupName = $ManagementGroupId
    }
    
    try {
        # Check if policy already exists
        $existingPolicy = Get-AzPolicyDefinition -Name $deployPolicyName -ErrorAction SilentlyContinue
        if ($existingPolicy) {
            Write-Host "Policy already exists, updating..." -ForegroundColor Yellow
            $deployPolicy = Set-AzPolicyDefinition @deployPolicyParams
            Write-Host "✓ DeployIfNotExists policy updated successfully" -ForegroundColor Green
        } else {
            $deployPolicy = New-AzPolicyDefinition @deployPolicyParams
            Write-Host "✓ DeployIfNotExists policy created successfully" -ForegroundColor Green
        }
        Write-Host "Policy ID: $($deployPolicy.Id)" -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to create/update DeployIfNotExists policy: $($_.Exception.Message)"
        exit 1
    }
    
    Write-Host "`n=== Policy Deployment Summary ===" -ForegroundColor Magenta
    Write-Host "Both policies have been successfully created!" -ForegroundColor Green
    Write-Host "AuditIfNotExists Policy ID: $($auditPolicy.Id)" -ForegroundColor Yellow
    Write-Host "DeployIfNotExists Policy ID: $($deployPolicy.Id)" -ForegroundColor Yellow
    
    Write-Host "`n=== Next Steps ===" -ForegroundColor Magenta
    Write-Host "1. Assign the policies to your desired scope (subscription/resource group)" -ForegroundColor White
    Write-Host "2. Configure policy parameters as needed" -ForegroundColor White
    Write-Host "3. Monitor compliance in the Azure Policy portal" -ForegroundColor White
    
} catch {
    Write-Error "Failed to deploy policies: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nDeployment completed!" -ForegroundColor Green
