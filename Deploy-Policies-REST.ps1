# Deploy Azure Policies using REST API
# This script uploads the policy definitions to Azure Policy using REST API calls

param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure Subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Management Group ID (if deploying to management group)")]
    [string]$ManagementGroupId
)

# Function to get access token
function Get-AzureAccessToken {
    try {
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if (-not $context) {
            Connect-AzAccount
            $context = Get-AzContext
        }
        
        $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, $null, $null, "https://management.azure.com/").AccessToken
        return $token
    } catch {
        Write-Error "Failed to get access token: $($_.Exception.Message)"
        return $null
    }
}

# Function to deploy policy via REST API
function Deploy-PolicyViaREST {
    param(
        [string]$PolicyFile,
        [string]$PolicyName,
        [string]$AccessToken,
        [string]$SubscriptionId,
        [string]$ManagementGroupId
    )
    
    $policyContent = Get-Content $PolicyFile -Raw | ConvertFrom-Json
    
    # Prepare the request body
    $requestBody = @{
        properties = $policyContent.properties
    } | ConvertTo-Json -Depth 20
    
    # Determine the URL based on scope
    if ($ManagementGroupId) {
        $url = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$ManagementGroupId/providers/Microsoft.Authorization/policyDefinitions/$PolicyName" + "?api-version=2021-06-01"
    } else {
        $url = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policyDefinitions/$PolicyName" + "?api-version=2021-06-01"
    }
    
    # Prepare headers
    $headers = @{
        'Authorization' = "Bearer $AccessToken"
        'Content-Type' = 'application/json'
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method PUT -Body $requestBody -Headers $headers
        return $response
    } catch {
        Write-Error "Failed to deploy policy $PolicyName : $($_.Exception.Message)"
        return $null
    }
}

try {
    # Import required modules
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Install-Module -Name Az.Accounts -Force -Scope CurrentUser
    }
    Import-Module Az.Accounts
    
    # Get access token
    Write-Host "Getting Azure access token..." -ForegroundColor Green
    $accessToken = Get-AzureAccessToken
    if (-not $accessToken) {
        Write-Error "Failed to get access token"
        exit 1
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
    
    Write-Host "Deploying policy definitions via REST API..." -ForegroundColor Green
    
    # Deploy AuditIfNotExists Policy
    Write-Host "Deploying AuditIfNotExists policy..." -ForegroundColor Cyan
    $auditPolicyName = "GG-Audit-SystemAuditPolicies-ObjectAccess"
    $auditResult = Deploy-PolicyViaREST -PolicyFile $auditPolicyFile -PolicyName $auditPolicyName -AccessToken $accessToken -SubscriptionId $SubscriptionId -ManagementGroupId $ManagementGroupId
    
    if ($auditResult) {
        Write-Host "✓ AuditIfNotExists policy created successfully" -ForegroundColor Green
        Write-Host "Policy ID: $($auditResult.id)" -ForegroundColor Yellow
    } else {
        Write-Error "Failed to create AuditIfNotExists policy"
        exit 1
    }
    
    # Deploy DeployIfNotExists Policy
    Write-Host "Deploying DeployIfNotExists policy..." -ForegroundColor Cyan
    $deployPolicyName = "GG-Deploy-SystemAuditPolicies-ObjectAccess"
    $deployResult = Deploy-PolicyViaREST -PolicyFile $deployPolicyFile -PolicyName $deployPolicyName -AccessToken $accessToken -SubscriptionId $SubscriptionId -ManagementGroupId $ManagementGroupId
    
    if ($deployResult) {
        Write-Host "✓ DeployIfNotExists policy created successfully" -ForegroundColor Green
        Write-Host "Policy ID: $($deployResult.id)" -ForegroundColor Yellow
    } else {
        Write-Error "Failed to create DeployIfNotExists policy"
        exit 1
    }
    
    Write-Host "`n=== Policy Deployment Summary ===" -ForegroundColor Magenta
    Write-Host "Both policies have been successfully created!" -ForegroundColor Green
    Write-Host "AuditIfNotExists Policy ID: $($auditResult.id)" -ForegroundColor Yellow
    Write-Host "DeployIfNotExists Policy ID: $($deployResult.id)" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to deploy policies: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nDeployment completed!" -ForegroundColor Green
