# Deploy Azure Policies using Azure CLI
# This script uploads the policy definitions to Azure Policy

param(
    [Parameter(Mandatory = $false, HelpMessage = "Azure Subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Management Group ID (if deploying to management group)")]
    [string]$ManagementGroupId
)

# Check if Azure CLI is installed
try {
    az version | Out-Null
    Write-Host "✓ Azure CLI is available" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Login to Azure (if not already logged in)
Write-Host "Checking Azure login status..." -ForegroundColor Green
$loginStatus = az account show 2>$null
if (-not $loginStatus) {
    Write-Host "Please login to Azure..." -ForegroundColor Yellow
    az login
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting subscription to: $SubscriptionId" -ForegroundColor Green
    az account set --subscription $SubscriptionId
}

# Define policy files
$auditPolicyFile = "..\AuditIfNotExists - Windows machines should meet requirements for 'System Audit Policies - Object Access'.json"
$deployPolicyFile = "..\DeployIfNotExists - Windows machines should meet requirements for 'System Audit Policies - Object Access'.json"

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
$auditPolicyName = "GG-Audit-SystemAuditPolicies-ObjectAccess"

if ($ManagementGroupId) {
    $auditResult = az policy definition create `
        --name $auditPolicyName `
        --rules $auditPolicyFile `
        --management-group $ManagementGroupId `
        --output json 2>&1
} else {
    $auditResult = az policy definition create `
        --name $auditPolicyName `
        --rules $auditPolicyFile `
        --output json 2>&1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ AuditIfNotExists policy created successfully" -ForegroundColor Green
    $auditPolicy = $auditResult | ConvertFrom-Json
    Write-Host "Policy ID: $($auditPolicy.id)" -ForegroundColor Yellow
} else {
    Write-Error "Failed to create AuditIfNotExists policy: $auditResult"
    exit 1
}

# Deploy DeployIfNotExists Policy
Write-Host "Deploying DeployIfNotExists policy..." -ForegroundColor Cyan
$deployPolicyName = "GG-Deploy-SystemAuditPolicies-ObjectAccess"

if ($ManagementGroupId) {
    $deployResult = az policy definition create `
        --name $deployPolicyName `
        --rules $deployPolicyFile `
        --management-group $ManagementGroupId `
        --output json 2>&1
} else {
    $deployResult = az policy definition create `
        --name $deployPolicyName `
        --rules $deployPolicyFile `
        --output json 2>&1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ DeployIfNotExists policy created successfully" -ForegroundColor Green
    $deployPolicy = $deployResult | ConvertFrom-Json
    Write-Host "Policy ID: $($deployPolicy.id)" -ForegroundColor Yellow
} else {
    Write-Error "Failed to create DeployIfNotExists policy: $deployResult"
    exit 1
}

Write-Host "`n=== Policy Deployment Summary ===" -ForegroundColor Magenta
Write-Host "Both policies have been successfully created!" -ForegroundColor Green
Write-Host "AuditIfNotExists Policy ID: $($auditPolicy.id)" -ForegroundColor Yellow
Write-Host "DeployIfNotExists Policy ID: $($deployPolicy.id)" -ForegroundColor Yellow

Write-Host "`n=== Next Steps ===" -ForegroundColor Magenta
Write-Host "1. Assign the policies to your desired scope (subscription/resource group)" -ForegroundColor White
Write-Host "2. Configure policy parameters as needed" -ForegroundColor White
Write-Host "3. Monitor compliance in the Azure Policy portal" -ForegroundColor White

Write-Host "`nDeployment completed!" -ForegroundColor Green
