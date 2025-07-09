# Test Guest Configuration Locally
# This script tests the Guest Configuration on the local machine
# 
# Guest Configuration Assignment Types:
# - Audit: Report on the state of the machine, but don't make changes
# - ApplyAndMonitor: Applied once and monitored for changes (no auto-correction)
# - ApplyAndAutoCorrect: Applied and automatically corrected if drift occurs
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
# APPLYANDMONITOR:
#   - Behavior: Applies configuration once, then monitors for drift
#   - Use case: One-time configuration with ongoing monitoring
#   - Drift handling: Detected and reported, but not automatically corrected
#   - Remediation: Requires manual remediation trigger or re-assignment
#
# APPLYANDAUTOCORRECT:
#   - Behavior: Applies configuration and automatically corrects drift
#   - Use case: Continuous compliance enforcement
#   - Drift handling: Automatically corrected at next evaluation cycle
#   - Remediation: Automatic correction by Guest Configuration agent
#
# Note: This local test simulates the behavior but cannot fully replicate
# the Azure Guest Configuration agent's automated drift correction capabilities.

param(
    [Parameter(Mandatory = $false)]
    [string]$AuditDetailedFileShare = "No Auditing",
    
    [Parameter(Mandatory = $false)]
    [string]$AuditFileShare = "Success and Failure",
    
    [Parameter(Mandatory = $false)]
    [string]$AuditFileSystem = "Success and Failure",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Audit", "ApplyAndMonitor", "ApplyAndAutoCorrect")]
    [string]$AssignmentType = "ApplyAndMonitor"
)

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script must be run as Administrator to modify audit policies."
    exit 1
}

Write-Host "Testing AzureBaseline_SystemAuditPoliciesObjectAccess configuration..." -ForegroundColor Green
Write-Host "Assignment Type: $AssignmentType" -ForegroundColor Cyan
Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "  AuditDetailedFileShare: $AuditDetailedFileShare" -ForegroundColor White
Write-Host "  AuditFileShare: $AuditFileShare" -ForegroundColor White
Write-Host "  AuditFileSystem: $AuditFileSystem" -ForegroundColor White

Write-Host "`nGuest Configuration Assignment Types:" -ForegroundColor Magenta
Write-Host "  Audit: Report on state, but don't make changes" -ForegroundColor White
Write-Host "  ApplyAndMonitor: Apply once and monitor for changes" -ForegroundColor White
Write-Host "  ApplyAndAutoCorrect: Apply and auto-correct if drift occurs" -ForegroundColor White
Write-Host "  Current test mode: $AssignmentType" -ForegroundColor Yellow

# Import the configuration
. .\AzureBaseline_SystemAuditPoliciesObjectAccess.ps1

# Create temporary directory for output
$tempPath = Join-Path $env:TEMP "GCTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $tempPath -ItemType Directory -Force | Out-Null

try
{
    # Create the configuration
    Write-Host "`nCompiling configuration..." -ForegroundColor Green
    
    $configData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowPlainTextPassword = $true
            }
        )
    }
    
    AzureBaseline_SystemAuditPoliciesObjectAccess -OutputPath $tempPath -ConfigurationData $configData -AuditDetailedFileShare $AuditDetailedFileShare -AuditFileShare $AuditFileShare -AuditFileSystem $AuditFileSystem
    
    # Behavior based on assignment type
    switch ($AssignmentType) {
        "Audit" {
            Write-Host "AUDIT MODE: Testing compliance without applying changes..." -ForegroundColor Yellow
            # In audit mode, we only test compliance, don't apply
            $testResult = Test-DscConfiguration -Path $tempPath -Detailed
            Write-Host "Compliance check completed (no changes applied)" -ForegroundColor Green
        }
        "ApplyAndMonitor" {
            Write-Host "APPLY AND MONITOR MODE: Applying configuration once..." -ForegroundColor Yellow
            # Apply the configuration once
            Start-DscConfiguration -Path $tempPath -Wait -Verbose -Force
            Write-Host "Configuration applied. Monitoring for compliance..." -ForegroundColor Green
            # Test compliance after application
            $testResult = Test-DscConfiguration -Detailed
        }
        "ApplyAndAutoCorrect" {
            Write-Host "APPLY AND AUTO-CORRECT MODE: Applying configuration with monitoring..." -ForegroundColor Yellow
            # Apply the configuration
            Start-DscConfiguration -Path $tempPath -Wait -Verbose -Force
            Write-Host "Configuration applied. Auto-correction would be handled by Guest Configuration agent in production." -ForegroundColor Green
            # Test compliance after application
            $testResult = Test-DscConfiguration -Detailed
        }
    }
    
    if ($testResult.InDesiredState)
    {
        Write-Host "SUCCESS: Configuration is in desired state!" -ForegroundColor Green
        Write-Host "Assignment Type Impact:" -ForegroundColor Cyan
        switch ($AssignmentType) {
            "Audit" {
                Write-Host "  - Audit: Would report compliant status to Azure without changes" -ForegroundColor White
            }
            "ApplyAndMonitor" {
                Write-Host "  - ApplyAndMonitor: Configuration applied and would be monitored for drift" -ForegroundColor White
            }
            "ApplyAndAutoCorrect" {
                Write-Host "  - ApplyAndAutoCorrect: Configuration applied and would auto-correct if drift occurs" -ForegroundColor White
            }
        }
    }
    else
    {
        Write-Host "FAILED: Configuration is not in desired state!" -ForegroundColor Red
        Write-Host "Assignment Type Impact:" -ForegroundColor Cyan
        switch ($AssignmentType) {
            "Audit" {
                Write-Host "  - Audit: Would report non-compliant status to Azure (no remediation)" -ForegroundColor White
            }
            "ApplyAndMonitor" {
                Write-Host "  - ApplyAndMonitor: Would remain non-compliant until manual remediation" -ForegroundColor White
            }
            "ApplyAndAutoCorrect" {
                Write-Host "  - ApplyAndAutoCorrect: Would automatically attempt to correct the drift" -ForegroundColor White
            }
        }
        Write-Host "Resources not in desired state:" -ForegroundColor Yellow
        $testResult.ResourcesNotInDesiredState | ForEach-Object {
            Write-Host "  - $($_.ResourceId): $($_.InDesiredState)" -ForegroundColor Red
        }
    }
    
    # Show current audit policy settings
    Write-Host "`nCurrent audit policy settings:" -ForegroundColor Yellow
    try
    {
        $auditSettings = @(
            'Detailed File Share',
            'File Share', 
            'File System'
        )
        
        foreach ($setting in $auditSettings)
        {
            $result = & auditpol.exe /get /subcategory:"$setting" /r 2>$null
            if ($LASTEXITCODE -eq 0)
            {
                $csvData = $result | ConvertFrom-Csv
                $subcategoryData = $csvData | Where-Object { $_.'Subcategory' -like "*$setting*" }
                if ($subcategoryData)
                {
                    Write-Host "  $($setting): $($subcategoryData.'Inclusion Setting')" -ForegroundColor White
                }
            }
        }
    }
    catch
    {
        Write-Warning "Could not retrieve current audit policy settings: $($_.Exception.Message)"
    }
}
catch
{
    Write-Error "Failed to test configuration: $($_.Exception.Message)"
}
finally
{
    # Clean up
    if (Test-Path $tempPath)
    {
        Remove-Item $tempPath -Recurse -Force
    }
}

Write-Host "`nTest completed!" -ForegroundColor Green

Write-Host "`nHow to Set Assignment Types in Azure:" -ForegroundColor Magenta
Write-Host "Assignment types are set when creating policy assignments, not in the policy definition itself." -ForegroundColor White
Write-Host "Note: The assignmentType parameter is available in the DeployIfNotExists policy only." -ForegroundColor Yellow
Write-Host "`nAzure Portal:" -ForegroundColor Cyan
Write-Host "  1. Go to Azure Policy > Assignments" -ForegroundColor White
Write-Host "  2. Click 'Assign Policy'" -ForegroundColor White
Write-Host "  3. Select your DeployIfNotExists policy definition" -ForegroundColor White
Write-Host "  4. In 'Parameters' tab, set 'Assignment Type' to:" -ForegroundColor White
Write-Host "     - Audit (default)" -ForegroundColor Gray
Write-Host "     - ApplyAndMonitor" -ForegroundColor Gray
Write-Host "     - ApplyAndAutoCorrect" -ForegroundColor Gray

Write-Host "`nAzure PowerShell:" -ForegroundColor Cyan
Write-Host "  # Create assignment with ApplyAndAutoCorrect" -ForegroundColor White
Write-Host "  `$params = @{" -ForegroundColor Gray
Write-Host "    'assignmentType' = 'ApplyAndAutoCorrect'" -ForegroundColor Gray
Write-Host "    'AuditFileSystem' = 'Success and Failure'" -ForegroundColor Gray
Write-Host "  }" -ForegroundColor Gray
Write-Host "  New-AzPolicyAssignment -Name 'audit-policy' \" -ForegroundColor Gray
Write-Host "    -PolicyDefinition (Get-AzPolicyDefinition -Name 'GG-Deploy-SystemAuditPolicies-ObjectAccess') \" -ForegroundColor Gray
Write-Host "    -Scope '/subscriptions/your-sub-id' \" -ForegroundColor Gray
Write-Host "    -PolicyParameterObject `$params" -ForegroundColor Gray

Write-Host "`nAzure CLI:" -ForegroundColor Cyan
Write-Host "  az policy assignment create \" -ForegroundColor Gray
Write-Host "    --name 'audit-policy' \" -ForegroundColor Gray
Write-Host "    --policy 'GG-Deploy-SystemAuditPolicies-ObjectAccess' \" -ForegroundColor Gray
Write-Host "    --scope '/subscriptions/your-sub-id' \" -ForegroundColor Gray
Write-Host "    --params '{\"assignmentType\":{\"value\":\"ApplyAndAutoCorrect\"}}'" -ForegroundColor Gray

Write-Host "`nLocal Testing Examples:" -ForegroundColor Magenta
Write-Host "  Test in Audit mode:" -ForegroundColor White
Write-Host "    .\Test-Configuration.ps1 -AssignmentType Audit" -ForegroundColor Gray
Write-Host "  Test in ApplyAndMonitor mode:" -ForegroundColor White
Write-Host "    .\Test-Configuration.ps1 -AssignmentType ApplyAndMonitor" -ForegroundColor Gray
Write-Host "  Test in ApplyAndAutoCorrect mode:" -ForegroundColor White
Write-Host "    .\Test-Configuration.ps1 -AssignmentType ApplyAndAutoCorrect" -ForegroundColor Gray
Write-Host "  Test with custom parameters:" -ForegroundColor White
Write-Host "    .\Test-Configuration.ps1 -AuditFileSystem 'Success' -AssignmentType ApplyAndMonitor" -ForegroundColor Gray
