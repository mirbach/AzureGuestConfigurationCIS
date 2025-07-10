# Test Guest Configuration Locally
# This script tests the Guest Configuration on the local machine
# 
# Guest Configuration Assignment Types:
# - Audit: Report on the state of the machine, but don't make changes
# - Apply and Monitor: Applied once and monitored for changes (no auto-correction)
# - Apply and Autocorrect: Applied and automatically corrected if drift occurs
#
# Policy Types:
# - AuditIfNotExists: Checks if Guest Configuration assignment exists and is compliant
# - DeployIfNotExists: Deploys Guest Configuration assignment with specified assignmentType
#
# Assignment Type Details:
# 
# AUDIT:
#   - Behavior: Only checks compliance, reports status to Azure
#   - Use case: Compliance reporting without system changes
#   - Drift handling: No automatic correction, only reporting
#   - Remediation: Manual intervention required
#
# APPLY AND MONITOR:
#   - Behavior: Applies configuration once, then monitors for drift
#   - Use case: One-time configuration with ongoing monitoring
#   - Drift handling: Detected and reported, but not automatically corrected
#   - Remediation: Requires manual remediation trigger or re-assignment
#
# APPLY AND AUTOCORRECT:
#   - Behavior: Applies configuration and automatically corrects drift
#   - Use case: Continuous compliance enforcement
#   - Drift handling: Automatically corrected at next evaluation cycle
#   - Remediation: Automatic correction by Guest Configuration agent
#
# Note: This local test simulates the behavior but cannot fully replicate
# the Azure Guest Configuration agent's automated drift correction capabilities.

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Audit", "ApplyAndMonitor", "ApplyAndAutoCorrect")]
    [string]$AssignmentType = "Audit"
)

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script must be run as Administrator to modify audit policies."
    exit 1
}

Write-Host "Testing AzureBaseline_AdministrativeTemplates_System configuration..." -ForegroundColor Green
Write-Host "Assignment Type: $AssignmentType" -ForegroundColor Yellow

# Display parameters
Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "Guest Configuration Assignment Types:" -ForegroundColor Yellow
Write-Host "  Audit: Report on state, but don't make changes" -ForegroundColor Cyan
Write-Host "  ApplyAndMonitor: Apply once and monitor for changes" -ForegroundColor Cyan
Write-Host "  ApplyAndAutoCorrect: Apply and auto-correct if drift occurs" -ForegroundColor Cyan
Write-Host "  Current test mode: $AssignmentType" -ForegroundColor Green

try {
    # Load the configuration
    . ".\AzureBaseline_AdministrativeTemplates_System.ps1"
    
    # Create parameters hashtable
    $configParams = @{    }
    
    Write-Host "Compiling configuration..." -ForegroundColor Yellow
    
    # Compile the configuration
    AzureBaseline_AdministrativeTemplates_System @configParams -OutputPath ".\TestOutput" -WarningAction SilentlyContinue | Out-Null
    
    Write-Host "Test completed!" -ForegroundColor Green
    
    # Clean up
    Remove-Item ".\TestOutput" -Recurse -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Error "Configuration test failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "How to Set Assignment Types in Azure:" -ForegroundColor Yellow
Write-Host "Assignment types are set when creating policy assignments, not in the policy definition itself." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: The assignmentType parameter is available in the DeployIfNotExists policy only." -ForegroundColor Yellow
Write-Host ""
Write-Host "Azure Portal:" -ForegroundColor Green
Write-Host "  1. Go to Azure Policy > Assignments" -ForegroundColor Cyan
Write-Host "  2. Click 'Assign Policy'" -ForegroundColor Cyan
Write-Host "  3. Select your DeployIfNotExists policy definition" -ForegroundColor Cyan
Write-Host "  4. In 'Parameters' tab, set 'Assignment Type' to:" -ForegroundColor Cyan
Write-Host "     - Audit (default)" -ForegroundColor Yellow
Write-Host "     - ApplyAndMonitor" -ForegroundColor Yellow
Write-Host "     - ApplyAndAutoCorrect" -ForegroundColor Yellow
Write-Host ""
Write-Host "Azure PowerShell:" -ForegroundColor Green
Write-Host "  # Create assignment with ApplyAndAutoCorrect" -ForegroundColor Cyan
Write-Host "  $params = @{" -ForegroundColor Cyan
Write-Host "    'assignmentType' = 'ApplyAndAutoCorrect'" -ForegroundColor Cyan
Write-Host "  }" -ForegroundColor Cyan
  New-AzPolicyAssignment -Name 'audit-policy' \
    -PolicyDefinition (Get-AzPolicyDefinition -Name 'GG-Deploy-AdministrativeTemplates_System') \
    -Scope '/subscriptions/your-sub-id' \
    -PolicyParameterObject $params

Write-Host ""
Write-Host "Azure CLI:" -ForegroundColor Green
Write-Host "  az policy assignment create \" -ForegroundColor Cyan
Write-Host "    --name 'audit-policy' \" -ForegroundColor Cyan
Write-Host "    --policy 'GG-Deploy-AdministrativeTemplates_System' \" -ForegroundColor Cyan
Write-Host "    --scope '/subscriptions/your-sub-id' \" -ForegroundColor Cyan
Write-Host "    --params '{ assignmentType:{value:ApplyAndAutoCorrect}}'" -ForegroundColor Cyan

Write-Host ""
Write-Host "Local Testing Examples:" -ForegroundColor Green
Write-Host "  Test in Audit mode:" -ForegroundColor Cyan
Write-Host "    .\Test-Configuration.ps1 -AssignmentType Audit" -ForegroundColor Yellow
Write-Host "  Test in ApplyAndMonitor mode:" -ForegroundColor Cyan
Write-Host "    .\Test-Configuration.ps1 -AssignmentType 'ApplyAndMonitor'" -ForegroundColor Yellow
Write-Host "  Test in ApplyAndAutoCorrect mode:" -ForegroundColor Cyan
Write-Host "    .\Test-Configuration.ps1 -AssignmentType 'ApplyAndAutoCorrect'" -ForegroundColor Yellow


