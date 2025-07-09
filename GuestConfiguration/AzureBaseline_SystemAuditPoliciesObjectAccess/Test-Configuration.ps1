# Test Guest Configuration Locally
# This script tests the Guest Configuration on the local machine

param(
    [Parameter(Mandatory = $false)]
    [string]$AuditDetailedFileShare = "No Auditing",
    
    [Parameter(Mandatory = $false)]
    [string]$AuditFileShare = "Success and Failure",
    
    [Parameter(Mandatory = $false)]
    [string]$AuditFileSystem = "Success and Failure"
)

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script must be run as Administrator to modify audit policies."
    exit 1
}

Write-Host "Testing AzureBaseline_SystemAuditPoliciesObjectAccess configuration..." -ForegroundColor Green
Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "  AuditDetailedFileShare: $AuditDetailedFileShare" -ForegroundColor White
Write-Host "  AuditFileShare: $AuditFileShare" -ForegroundColor White
Write-Host "  AuditFileSystem: $AuditFileSystem" -ForegroundColor White

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
    
    # Apply the configuration
    Write-Host "Applying configuration..." -ForegroundColor Green
    Start-DscConfiguration -Path $tempPath -Wait -Verbose -Force
    
    # Test compliance
    Write-Host "`nTesting compliance..." -ForegroundColor Green
    $testResult = Test-DscConfiguration -Detailed
    
    if ($testResult.InDesiredState)
    {
        Write-Host "SUCCESS: Configuration is in desired state!" -ForegroundColor Green
    }
    else
    {
        Write-Host "FAILED: Configuration is not in desired state!" -ForegroundColor Red
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
