# Update Policy Files with Package URI and ContentHash
# This script updates the Azure Policy JSON files with the actual package URI and ContentHash after deployment
# Works with custom [GG Serverhardening] policies (prefix is in display name, not filename)

param(
    [Parameter(Mandatory = $true, HelpMessage = "The URI of the uploaded Guest Configuration package")]
    [string]$PackageUri,
    
    [Parameter(Mandatory = $true, HelpMessage = "The SHA256 hash of the Guest Configuration package")]
    [string]$ContentHash,
    
    [Parameter(Mandatory = $false, HelpMessage = "Path to the policy files directory")]
    [string]$PolicyPath = "..\..\"
)

$auditPolicyFile = Get-ChildItem -Path $PolicyPath -Filter "*AuditIfNotExists*Windows machines should meet requirements*" | Select-Object -First 1
$deployPolicyFile = Get-ChildItem -Path $PolicyPath -Filter "*DeployIfNotExists*Windows machines should meet requirements*" | Select-Object -First 1

Write-Host "Updating policy files with package URI and ContentHash..." -ForegroundColor Green
Write-Host "Package URI: $PackageUri" -ForegroundColor Yellow
Write-Host "Content Hash: $ContentHash" -ForegroundColor Yellow

# Update AuditIfNotExists policy
if ($auditPolicyFile) {
    Write-Host "Updating AuditIfNotExists policy file..." -ForegroundColor Cyan
    $content = Get-Content $auditPolicyFile.FullName -Raw | ConvertFrom-Json
    
    # Update the contentUri and contentHash in the metadata.guestConfiguration section (for AuditIfNotExists policies)
    if ($content.properties.metadata.PSObject.Properties['guestConfiguration']) {
        $content.properties.metadata.guestConfiguration | Add-Member -Name "contentUri" -Value $PackageUri -MemberType NoteProperty -Force
        $content.properties.metadata.guestConfiguration | Add-Member -Name "contentHash" -Value $ContentHash -MemberType NoteProperty -Force
        
        $content | ConvertTo-Json -Depth 20 | Set-Content $auditPolicyFile.FullName -Encoding UTF8
        Write-Host "✓ AuditIfNotExists policy updated" -ForegroundColor Green
    } else {
        Write-Warning "Could not find guestConfiguration section in AuditIfNotExists policy"
    }
} else {
    Write-Warning "AuditIfNotExists policy file not found"
}

# Update DeployIfNotExists policy
if ($deployPolicyFile) {
    Write-Host "Updating DeployIfNotExists policy file..." -ForegroundColor Cyan
    $content = Get-Content $deployPolicyFile.FullName -Raw | ConvertFrom-Json
    
    # Update the contentUri and contentHash in the deployment template resources (for DeployIfNotExists policies)
    if ($content.properties.policyRule.then.details.PSObject.Properties['deployment']) {
        # Update contentUri and contentHash in all guestConfiguration sections in the deployment template
        foreach ($resource in $content.properties.policyRule.then.details.deployment.properties.template.resources) {
            if ($resource.properties.PSObject.Properties['guestConfiguration']) {
                $resource.properties.guestConfiguration | Add-Member -Name "contentUri" -Value $PackageUri -MemberType NoteProperty -Force
                $resource.properties.guestConfiguration | Add-Member -Name "contentHash" -Value $ContentHash -MemberType NoteProperty -Force
            }
        }
        
        $content | ConvertTo-Json -Depth 20 | Set-Content $deployPolicyFile.FullName -Encoding UTF8
        Write-Host "✓ DeployIfNotExists policy updated" -ForegroundColor Green
    } else {
        Write-Warning "Could not find deployment section in DeployIfNotExists policy"
    }
} else {
    Write-Warning "DeployIfNotExists policy file not found"
}

Write-Host "`nPolicy files updated successfully!" -ForegroundColor Green
Write-Host "You can now import these policy definitions into Azure." -ForegroundColor Cyan
