# Azure Policy Initiative Management Functions
# These functions create and assign policy initiatives

function Invoke-CreateInitiatives {
    Write-Status "Creating Azure Policy Initiatives..." "Green"
    
    # Connect to Azure first
    if (-not (Connect-ToAzure)) {
        Write-Status "Failed to connect to Azure. Aborting initiative creation." "Red"
        return
    }
    
    # Get all policy directories to build the initiative definitions
    $policyDirs = Get-PolicyDirectories -Filter $PolicyFilter
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
        $cleanFolderName = $folderName -replace '[^a-zA-Z0-9]', ''
        
        # Check if policies exist before adding to initiative
        $auditPolicyName = "GG-Audit-$cleanFolderName"
        $deployPolicyName = "GG-Deploy-$cleanFolderName"
        
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
        
        # Check if initiative already exists
        $existingAuditInitiative = Get-AzPolicySetDefinition -Name $auditInitiativeName -ErrorAction SilentlyContinue
        if ($existingAuditInitiative) {
            Write-Status "  Audit initiative exists, updating..." "Gray"
            $auditResult = Set-AzPolicySetDefinition @auditInitiativeParams
            Write-Status "  ✓ Audit initiative updated successfully" "Green"
        } else {
            $auditResult = New-AzPolicySetDefinition @auditInitiativeParams
            Write-Status "  ✓ Audit initiative created successfully" "Green"
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
        
        # Check if initiative already exists
        $existingDeployInitiative = Get-AzPolicySetDefinition -Name $deployInitiativeName -ErrorAction SilentlyContinue
        if ($existingDeployInitiative) {
            Write-Status "  Deploy initiative exists, updating..." "Gray"
            $deployResult = Set-AzPolicySetDefinition @deployInitiativeParams
            Write-Status "  ✓ Deploy initiative updated successfully" "Green"
        } else {
            $deployResult = New-AzPolicySetDefinition @deployInitiativeParams
            Write-Status "  ✓ Deploy initiative created successfully" "Green"
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
        [string]$TargetScope = "/subscriptions/$($config.SubscriptionId)",
        [string]$InitiativeFilter = "*"
    )
    
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
                $initiativeDefinition = Get-AzPolicySetDefinition -Name $initiative.Name -ErrorAction SilentlyContinue
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
                $existingAssignment = Get-AzPolicyAssignment -Name $assignmentName -Scope $TargetScope -ErrorAction SilentlyContinue
                
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
