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

# Function to convert SecurityOption numeric values to text values
function ConvertTo-SecurityOptionValue {
    param(
        [string]$PropertyName,
        [string]$NumericValue
    )
    
    $mappings = @{
        'User_Account_Control_Admin_Approval_Mode_for_the_Built_in_Administrator_account' = @{
            '0' = 'Disabled'
            '1' = 'Enabled'
        }
        'User_Account_Control_Behavior_of_the_elevation_prompt_for_administrators_in_Admin_Approval_Mode' = @{
            '0' = 'Elevate without prompting'
            '1' = 'Prompt for credentials on the secure desktop'
            '2' = 'Prompt for consent on the secure desktop'
            '3' = 'Prompt for credentials'
            '4' = 'Prompt for consent'
            '5' = 'Prompt for consent for non-Windows binaries'
        }
        'User_Account_Control_Detect_application_installations_and_prompt_for_elevation' = @{
            '0' = 'Disabled'
            '1' = 'Enabled'
        }
        'User_Account_Control_Run_all_administrators_in_Admin_Approval_Mode' = @{
            '0' = 'Disabled'
            '1' = 'Enabled'
        }
        'Accounts_Guest_account_status' = @{
            '0' = 'Disabled'
            '1' = 'Enabled'
        }
        'Network_security_LAN_Manager_authentication_level' = @{
            '0' = 'Send LM & NTLM responses'
            '1' = 'Send LM & NTLM - use NTLMv2 session security if negotiated'
            '2' = 'Send NTLM response only'
            '3' = 'Send NTLMv2 response only'
            '4' = 'Send NTLMv2 response only. Refuse LM'
            '5' = 'Send NTLMv2 response only. Refuse LM & NTLM'
        }
        'Network_security_LDAP_client_signing_requirements' = @{
            '0' = 'None'
            '1' = 'Negotiate signing'
            '2' = 'Require signing'
        }
    }
    
    if ($mappings.ContainsKey($PropertyName) -and $mappings[$PropertyName].ContainsKey($NumericValue)) {
        return $mappings[$PropertyName][$NumericValue]
    }
    
    # If no mapping found, return original value
    return $NumericValue
}

# Load Azure configuration
$azureConfigFile = Join-Path $PSScriptRoot "..\azure.config"
if (Test-Path $azureConfigFile) {
    . $azureConfigFile
} else {
    Write-Warning "Azure configuration file not found. Using default values."
    $AzureSubscriptionId = "e749c27d-1157-4753-929c-adfddb9c814c"
    $AzureResourceGroupName = "RG_ARC_Local_All_RestoreTest" 
    $AzureLocation = "West Europe"
    $AzureStorageAccountName = "saserverhardeningdkleac"
    $AzureStorageContainerName = "guestconfiguration"
}

# Configuration
$config = @{
    SubscriptionId = $AzureSubscriptionId
    StorageAccount = @{
        Name = $AzureStorageAccountName
        ResourceGroupName = $AzureResourceGroupName
        ContainerName = $AzureStorageContainerName
    }
    Deployment = @{
        TargetResourceGroup = $AzureResourceGroupName
        Location = $AzureLocation
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

# Function to convert policy name to short folder name
function ConvertTo-ShortFolderName {
    param([string]$PolicyName)
    
    # Create short folder name mapping
    $shortNames = @{
        "Windows machines should meet requirements for 'Administrative Templates - Control Panel'" = "GG-AdminTemplates-ControlPanel"
        "Windows machines should meet requirements for 'Administrative Templates - MSS (Legacy)'" = "GG-AdminTemplates-MSS"
        "Windows machines should meet requirements for 'Administrative Templates - Network'" = "GG-AdminTemplates-Network"
        "Windows machines should meet requirements for 'Administrative Templates - System'" = "GG-AdminTemplates-System"
        "Windows machines should meet requirements for 'Security Options - Accounts'" = "GG-SecurityOptions-Accounts"
        "Windows machines should meet requirements for 'Security Options - Audit'" = "GG-SecurityOptions-Audit"
        "Windows machines should meet requirements for 'Security Options - Devices'" = "GG-SecurityOptions-Devices"
        "Windows machines should meet requirements for 'Security Options - Interactive Logon'" = "GG-SecurityOptions-InteractiveLogon"
        "Windows machines should meet requirements for 'Security Options - Microsoft Network Client'" = "GG-SecurityOptions-NetworkClient"
        "Windows machines should meet requirements for 'Security Options - Microsoft Network Server'" = "GG-SecurityOptions-NetworkServer"
        "Windows machines should meet requirements for 'Security Options - Network Access'" = "GG-SecurityOptions-NetworkAccess"
        "Windows machines should meet requirements for 'Security Options - Network Security'" = "GG-SecurityOptions-NetworkSecurity"
        "Windows machines should meet requirements for 'Security Options - Recovery console'" = "GG-SecurityOptions-RecoveryConsole"
        "Windows machines should meet requirements for 'Security Options - Shutdown'" = "GG-SecurityOptions-Shutdown"
        "Windows machines should meet requirements for 'Security Options - System objects'" = "GG-SecurityOptions-SystemObjects"
        "Windows machines should meet requirements for 'Security Options - System settings'" = "GG-SecurityOptions-SystemSettings"
        "Windows machines should meet requirements for 'Security Options - User Account Control'" = "GG-SecurityOptions-UAC"
        "Windows machines should meet requirements for 'Security Settings - Account Policies'" = "GG-SecuritySettings-AccountPolicies"
        "Windows machines should meet requirements for 'System Audit Policies - Account Logon'" = "GG-AuditPolicies-AccountLogon"
        "Windows machines should meet requirements for 'System Audit Policies - Account Management'" = "GG-AuditPolicies-AccountMgmt"
        "Windows machines should meet requirements for 'System Audit Policies - Detailed Tracking'" = "GG-AuditPolicies-DetailedTracking"
        "Windows machines should meet requirements for 'System Audit Policies - Logon-Logoff'" = "GG-AuditPolicies-LogonLogoff"
        "Windows machines should meet requirements for 'System Audit Policies - Object Access'" = "GG-AuditPolicies-ObjectAccess"
        "Windows machines should meet requirements for 'System Audit Policies - Policy Change'" = "GG-AuditPolicies-PolicyChange"
        "Windows machines should meet requirements for 'System Audit Policies - Privilege Use'" = "GG-AuditPolicies-PrivilegeUse"
        "Windows machines should meet requirements for 'System Audit Policies - System'" = "GG-AuditPolicies-System"
        "Windows machines should meet requirements for 'User Rights Assignment'" = "GG-UserRightsAssignment"
        "Windows machines should meet requirements for 'Windows Components'" = "GG-WindowsComponents"
        "Windows machines should meet requirements for 'Windows Firewall Properties'" = "GG-WindowsFirewall"
    }
    
    if ($shortNames.ContainsKey($PolicyName)) {
        return $shortNames[$PolicyName]
    } else {
        # Fallback for any unmapped names
        $fallback = $PolicyName -replace "Windows machines should meet requirements for ", "GG-"
        $fallback = $fallback -replace "'", ""
        $fallback = $fallback -replace "\s+", "-"
        $fallback = $fallback -replace "[^\w\-]", ""
        return $fallback
    }
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
    
    # For AuditPolicy resources, fix audit flags for AuditPolicyDsc module
    if ($PolicyType -eq "AuditPolicy") {
        switch ($ParameterValue) {
            "No Auditing" { return "None" }
            "Success" { return "Success" }
            "Failure" { return "Failure" }
            "Success and Failure" { return "Success, Failure" }
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
        [array]$Parameters,
        [string]$PolicyName
    )
    
    $template = Get-Content (Join-Path $templatesPath "DSC-Configuration.ps1.template") -Raw
    
    # Generate parameters with original values (let DSC resources handle conversion)
    $parameterBlock = ""
    $policyType = Get-PolicyType -PolicyName $PolicyName
    
    foreach ($param in $Parameters) {
        # Don't convert the default value - keep it as original for DSC resources to handle
        $defaultValue = $param.DefaultValue
        $parameterBlock += "        [Parameter()]`r`n"
        $parameterBlock += "        [string]`$$($param.Name) = '$defaultValue',`r`n`r`n"
    }
    $parameterBlock = $parameterBlock.TrimEnd(",`r`n")
    
    # Generate DSC resources based on policy type
    $dscResources = ""
    $dscModules = @()
    
    foreach ($param in $Parameters) {
        # Skip empty or null parameter names
        if (-not $param.Name -or $param.Name.Trim() -eq "") {
            continue
        }
        
        if ($PolicyName -like "*System Audit Policies*") {
            # Use AuditPolicyDsc module for audit policies
            if ($dscModules -notcontains "AuditPolicyDsc") { $dscModules += "AuditPolicyDsc" }
            # Get the actual subcategory name from the original policy mapping
            $subcategoryName = $param.DisplayName -replace 'Audit ', ''
            
            # For "Success and Failure", we need to create two separate resources
            # as AuditPolicySubcategory only supports { Success | Failure } individually
            $dscResources += "        # Handle '$($param.DisplayName)' parameter`r`n"
            $dscResources += "        if (`$$($param.Name) -eq 'Success and Failure') {`r`n"
            $dscResources += "            AuditPolicySubcategory '$($param.Name)_Success'`r`n"
            $dscResources += "            {`r`n"
            $dscResources += "                Name = '$subcategoryName'`r`n"
            $dscResources += "                AuditFlag = 'Success'`r`n"
            $dscResources += "                Ensure = 'Present'`r`n"
            $dscResources += "            }`r`n"
            $dscResources += "            AuditPolicySubcategory '$($param.Name)_Failure'`r`n"
            $dscResources += "            {`r`n"
            $dscResources += "                Name = '$subcategoryName'`r`n"
            $dscResources += "                AuditFlag = 'Failure'`r`n"
            $dscResources += "                Ensure = 'Present'`r`n"
            $dscResources += "            }`r`n"
            $dscResources += "        } elseif (`$$($param.Name) -eq 'No Auditing') {`r`n"
            $dscResources += "            AuditPolicySubcategory '$($param.Name)_Success'`r`n"
            $dscResources += "            {`r`n"
            $dscResources += "                Name = '$subcategoryName'`r`n"
            $dscResources += "                AuditFlag = 'Success'`r`n"
            $dscResources += "                Ensure = 'Absent'`r`n"
            $dscResources += "            }`r`n"
            $dscResources += "            AuditPolicySubcategory '$($param.Name)_Failure'`r`n"
            $dscResources += "            {`r`n"
            $dscResources += "                Name = '$subcategoryName'`r`n"
            $dscResources += "                AuditFlag = 'Failure'`r`n"
            $dscResources += "                Ensure = 'Absent'`r`n"
            $dscResources += "            }`r`n"
            $dscResources += "        } else {`r`n"
            $dscResources += "            AuditPolicySubcategory '$($param.Name)'`r`n"
            $dscResources += "            {`r`n"
            $dscResources += "                Name = '$subcategoryName'`r`n"
            $dscResources += "                AuditFlag = `$$($param.Name)`r`n"
            $dscResources += "                Ensure = 'Present'`r`n"
            $dscResources += "            }`r`n"
            $dscResources += "        }`r`n`r`n"
        } elseif ($PolicyName -like "*Security Options*" -or $PolicyName -like "*Security Settings*") {
            # Use SecurityPolicyDsc module for security options and settings
            if ($dscModules -notcontains "SecurityPolicyDsc") { $dscModules += "SecurityPolicyDsc" }
            
            # For Security Settings, we need to use different DSC resources
            if ($PolicyName -like "*Security Settings*") {
                $dscResources += "        AccountPolicy '$($param.Name)'`r`n"
                $dscResources += "        {`r`n"
                $dscResources += "            Name = '$($param.Name)'`r`n"
                # Map to proper AccountPolicy properties based on display name
                $policyProperty = $param.DisplayName
                if ($policyProperty -like "*password history*") { $policyProperty = "Enforce_password_history" }
                elseif ($policyProperty -like "*Maximum password age*") { $policyProperty = "Maximum_password_age" }
                elseif ($policyProperty -like "*Minimum password age*") { $policyProperty = "Minimum_password_age" }
                elseif ($policyProperty -like "*Minimum password length*") { $policyProperty = "Minimum_password_length" }
                elseif ($policyProperty -like "*complexity*") { $policyProperty = "Password_must_meet_complexity_requirements" }
                
                # Handle value conversion for AccountPolicy
                if ($policyProperty -eq "Password_must_meet_complexity_requirements") {
                    $dscResources += "            $policyProperty = switch (`$$($param.Name)) {`r`n"
                    $dscResources += "                'Enabled' { `$true }`r`n"
                    $dscResources += "                'Disabled' { `$false }`r`n"
                    $dscResources += "                'True' { `$true }`r`n"
                    $dscResources += "                'False' { `$false }`r`n"
                    $dscResources += "                '1' { `$true }`r`n"
                    $dscResources += "                '0' { `$false }`r`n"
                    $dscResources += "                default { [bool]`$$($param.Name) }`r`n"
                    $dscResources += "            }`r`n"
                } elseif ($policyProperty -like "*age*" -or $policyProperty -like "*history*" -or $policyProperty -like "*length*") {
                    # These should be numeric values
                    $dscResources += "            $policyProperty = [uint32]`$$($param.Name)`r`n"
                } else {
                    $dscResources += "            $policyProperty = `$$($param.Name)`r`n"
                }
                $dscResources += "        }`r`n`r`n"
            } else {
                # For Security Options, use SecurityOption resource with correct property names
                $dscResources += "        SecurityOption '$($param.Name)'`r`n"
                $dscResources += "        {`r`n"
                $dscResources += "            Name = '$($param.Name)'`r`n"
                # Map parameter name to correct SecurityOption property name
                $propertyName = $null
                switch ($param.Name) {
                    'AccountsAdministratorAccountStatus' { $propertyName = 'Accounts_Administrator_account_status' }
                    'AccountsGuestAccountStatus' { $propertyName = 'Accounts_Guest_account_status' }
                    'AccountsLimitLocalAccountUseOfBlankPasswords' { $propertyName = 'Accounts_Limit_local_account_use_of_blank_passwords_to_console_logon_only' }
                    'AccountsRenameAdministratorAccount' { $propertyName = 'Accounts_Rename_administrator_account' }
                    'AccountsRenameGuestAccount' { $propertyName = 'Accounts_Rename_guest_account' }
                    'InteractiveLogonDoNotDisplayLastUserName' { $propertyName = 'Interactive_logon_Do_not_display_last_user_name' }
                    'InteractiveLogonDoNotRequireCtrlAltDel' { $propertyName = 'Interactive_logon_Do_not_require_CTRL_ALT_DEL' }
                    'InteractiveLogonMachineInactivityLimit' { $propertyName = 'Interactive_logon_Machine_inactivity_limit' }
                    'InteractiveLogonMessageTextForUsersAttemptingToLogOn' { $propertyName = 'Interactive_logon_Message_text_for_users_attempting_to_log_on' }
                    'InteractiveLogonMessageTitleForUsersAttemptingToLogOn' { $propertyName = 'Interactive_logon_Message_title_for_users_attempting_to_log_on' }
                    'InteractiveLogonSmartCardRemovalBehavior' { $propertyName = 'Interactive_logon_Smart_card_removal_behavior' }
                    'MicrosoftNetworkClientDigitallySignCommunicationsAlways' { $propertyName = 'Microsoft_network_client_Digitally_sign_communications_always' }
                    'MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees' { $propertyName = 'Microsoft_network_client_Digitally_sign_communications_if_server_agrees' }
                    'MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers' { $propertyName = 'Microsoft_network_client_Send_unencrypted_password_to_third_party_SMB_servers' }
                    'MicrosoftNetworkServerAmountOfIdleTimeRequired' { $propertyName = 'Microsoft_network_server_Amount_of_idle_time_required_before_suspending_session' }
                    'MicrosoftNetworkServerDigitallySignCommunicationsAlways' { $propertyName = 'Microsoft_network_server_Digitally_sign_communications_always' }
                    'MicrosoftNetworkServerDigitallySignCommunicationsIfClientAgrees' { $propertyName = 'Microsoft_network_server_Digitally_sign_communications_if_client_agrees' }
                    'MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire' { $propertyName = 'Microsoft_network_server_Disconnect_clients_when_logon_hours_expire' }
                    'NetworkAccessDoNotAllowAnonymousEnumerationOfSAMAccounts' { $propertyName = 'Network_access_Do_not_allow_anonymous_enumeration_of_SAM_accounts' }
                    'NetworkAccessDoNotAllowAnonymousEnumerationOfSAMAccountsAndShares' { $propertyName = 'Network_access_Do_not_allow_anonymous_enumeration_of_SAM_accounts_and_shares' }
                    'NetworkAccessLetEveryonePermissionsApplyToAnonymousUsers' { $propertyName = 'Network_access_Let_Everyone_permissions_apply_to_anonymous_users' }
                    'NetworkAccessRestrictAnonymousAccessToNamedPipesAndShares' { $propertyName = 'Network_access_Restrict_anonymous_access_to_Named_Pipes_and_Shares' }
                    'NetworkAccessRestrictClientsAllowedToMakeRemoteCallsToSAM' { $propertyName = 'Network_access_Restrict_clients_allowed_to_make_remote_calls_to_SAM' }
                    'NetworkSecurityAllowLocalSystemNullSessionFallback' { $propertyName = 'Network_security_Allow_LocalSystem_NULL_session_fallback' }
                    'NetworkSecurityAllowLocalSystemToUseComputerIdentityForNTLM' { $propertyName = 'Network_security_Allow_Local_System_to_use_computer_identity_for_NTLM' }
                    'NetworkSecurityDoNotStoreLANManagerHashValueOnNextPasswordChange' { $propertyName = 'Network_security_Do_not_store_LAN_Manager_hash_value_on_next_password_change' }
                    'NetworkSecurityForceLogoffWhenLogonHoursExpire' { $propertyName = 'Network_security_Force_logoff_when_logon_hours_expire' }
                    'NetworkSecurityLANManagerAuthenticationLevel' { $propertyName = 'Network_security_LAN_Manager_authentication_level' }
                    'NetworkSecurityLDAPClientSigningRequirements' { $propertyName = 'Network_security_LDAP_client_signing_requirements' }
                    'NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCClients' { $propertyName = 'Network_security_Minimum_session_security_for_NTLM_SSP_based_including_secure_RPC_clients' }
                    'NetworkSecurityMinimumSessionSecurityForNTLMSSPBasedIncludingSecureRPCServers' { $propertyName = 'Network_security_Minimum_session_security_for_NTLM_SSP_based_including_secure_RPC_servers' }
                    'RecoveryConsoleAllowAutomaticAdministrativeLogon' { $propertyName = 'Recovery_console_Allow_automatic_administrative_logon' }
                    'RecoveryConsoleAllowFloppyCopyAndAccessToAllDrivesAndFolders' { $propertyName = 'Recovery_console_Allow_floppy_copy_and_access_to_all_drives_and_folders' }
                    'ShutdownAllowSystemToBeShutDownWithoutHavingToLogOn' { $propertyName = 'Shutdown_Allow_system_to_be_shut_down_without_having_to_log_on' }
                    'ShutdownClearVirtualMemoryPagefile' { $propertyName = 'Shutdown_Clear_virtual_memory_pagefile' }
                    'SystemObjectsRequireCaseInsensitivityForNonWindowsSubsystems' { $propertyName = 'System_objects_Require_case_insensitivity_for_non_Windows_subsystems' }
                    'SystemObjectsStrengthenDefaultPermissionsOfInternalSystemObjects' { $propertyName = 'System_objects_Strengthen_default_permissions_of_internal_system_objects_eg_Symbolic_Links' }
                    'SystemSettingsOptionalSubsystems' { $propertyName = 'System_settings_Optional_subsystems' }
                    'SystemSettingsUseCertificateRulesOnWindowsExecutablesForSoftwareRestrictionPolicies' { $propertyName = 'System_settings_Use_Certificate_Rules_on_Windows_Executables_for_Software_Restriction_Policies' }
                    'UACAdminApprovalModeForTheBuiltinAdministratorAccount' { $propertyName = 'User_Account_Control_Admin_Approval_Mode_for_the_Built_in_Administrator_account' }
                    'UACBehaviorOfTheElevationPromptForAdministratorsInAdminApprovalMode' { $propertyName = 'User_Account_Control_Behavior_of_the_elevation_prompt_for_administrators_in_Admin_Approval_Mode' }
                    'UACDetectApplicationInstallationsAndPromptForElevation' { $propertyName = 'User_Account_Control_Detect_application_installations_and_prompt_for_elevation' }
                    'UACRunAllAdministratorsInAdminApprovalMode' { $propertyName = 'User_Account_Control_Run_all_administrators_in_Admin_Approval_Mode' }
                    default { 
                        Write-Warning "Unknown SecurityOption parameter: $($param.Name)"
                        $propertyName = $param.Name
                    }
                }
                # Add value conversion logic for SecurityOption parameters
                $dscResources += "            $propertyName = switch (`$$($param.Name)) {`r`n"
                
                # Add specific value mappings based on property name
                switch ($propertyName) {
                    'User_Account_Control_Admin_Approval_Mode_for_the_Built_in_Administrator_account' {
                        $dscResources += "                '0' { 'Disabled' }`r`n"
                        $dscResources += "                '1' { 'Enabled' }`r`n"
                        $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                        $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                    }
                    'User_Account_Control_Behavior_of_the_elevation_prompt_for_administrators_in_Admin_Approval_Mode' {
                        $dscResources += "                '0' { 'Elevate without prompting' }`r`n"
                        $dscResources += "                '1' { 'Prompt for credentials on the secure desktop' }`r`n"
                        $dscResources += "                '2' { 'Prompt for consent on the secure desktop' }`r`n"
                        $dscResources += "                '3' { 'Prompt for credentials' }`r`n"
                        $dscResources += "                '4' { 'Prompt for consent' }`r`n"
                        $dscResources += "                '5' { 'Prompt for consent for non-Windows binaries' }`r`n"
                    }
                    'User_Account_Control_Detect_application_installations_and_prompt_for_elevation' {
                        $dscResources += "                '0' { 'Disabled' }`r`n"
                        $dscResources += "                '1' { 'Enabled' }`r`n"
                        $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                        $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                    }
                    'User_Account_Control_Run_all_administrators_in_Admin_Approval_Mode' {
                        $dscResources += "                '0' { 'Disabled' }`r`n"
                        $dscResources += "                '1' { 'Enabled' }`r`n"
                        $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                        $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                    }
                    'Accounts_Guest_account_status' {
                        $dscResources += "                '0' { 'Disabled' }`r`n"
                        $dscResources += "                '1' { 'Enabled' }`r`n"
                        $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                        $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                    }
                    'Accounts_Administrator_account_status' {
                        $dscResources += "                '0' { 'Disabled' }`r`n"
                        $dscResources += "                '1' { 'Enabled' }`r`n"
                        $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                        $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                    }
                    'Network_security_LAN_Manager_authentication_level' {
                        $dscResources += "                '0' { 'Send LM & NTLM responses' }`r`n"
                        $dscResources += "                '1' { 'Send LM & NTLM - use NTLMv2 session security if negotiated' }`r`n"
                        $dscResources += "                '2' { 'Send NTLM response only' }`r`n"
                        $dscResources += "                '3' { 'Send NTLMv2 response only' }`r`n"
                        $dscResources += "                '4' { 'Send NTLMv2 response only. Refuse LM' }`r`n"
                        $dscResources += "                '5' { 'Send NTLMv2 response only. Refuse LM & NTLM' }`r`n"
                    }
                    'Network_security_LDAP_client_signing_requirements' {
                        $dscResources += "                '0' { 'None' }`r`n"
                        $dscResources += "                '1' { 'Negotiate signing' }`r`n"
                        $dscResources += "                '2' { 'Require signing' }`r`n"
                    }
                    default {
                        # For other SecurityOption parameters, try default mappings
                        if ($propertyName -match '_account_status$') {
                            $dscResources += "                '0' { 'Disabled' }`r`n"
                            $dscResources += "                '1' { 'Enabled' }`r`n"
                            $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                            $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                        } elseif ($propertyName -match 'User_Account_Control') {
                            $dscResources += "                '0' { 'Disabled' }`r`n"
                            $dscResources += "                '1' { 'Enabled' }`r`n"
                            $dscResources += "                'Disabled' { 'Disabled' }`r`n"
                            $dscResources += "                'Enabled' { 'Enabled' }`r`n"
                        } else {
                            $dscResources += "                default { `$$($param.Name) }`r`n"
                        }
                    }
                }
                
                $dscResources += "                default { `$$($param.Name) }`r`n"
                $dscResources += "            }`r`n"
                $dscResources += "        }`r`n`r`n"
            }
        } elseif ($PolicyName -like "*User Rights Assignment*") {
            # Use SecurityPolicyDsc module for user rights assignment
            if ($dscModules -notcontains "SecurityPolicyDsc") { $dscModules += "SecurityPolicyDsc" }
            $dscResources += "        UserRightsAssignment '$($param.Name)'`r`n"
            $dscResources += "        {`r`n"
            # Map parameter name to correct UserRightsAssignment policy name
            $policyName = $null
            switch ($param.Name) {
                'UsersOrGroupsThatMayAccessThisComputerFromTheNetwork' { $policyName = 'Access_this_computer_from_the_network' }
                'UsersOrGroupsThatMayActAsPartOfTheOperatingSystem' { $policyName = 'Act_as_part_of_the_operating_system' }
                'UsersOrGroupsThatMayLogOnAsABatchJob' { $policyName = 'Log_on_as_a_batch_job' }
                'UsersOrGroupsThatMayLogOnAsAService' { $policyName = 'Log_on_as_a_service' }
                'UsersOrGroupsThatMayLogOnLocally' { $policyName = 'Allow_log_on_locally' }
                'UsersOrGroupsThatMayLogOnThroughRemoteDesktopServices' { $policyName = 'Allow_log_on_through_Remote_Desktop_Services' }
                'UsersOrGroupsThatMayManageAuditingAndSecurityLog' { $policyName = 'Manage_auditing_and_security_log' }
                'UsersOrGroupsThatMayShutDownTheSystem' { $policyName = 'Shut_down_the_system' }
                'UsersOrGroupsThatMayTakeOwnershipOfFilesOrOtherObjects' { $policyName = 'Take_ownership_of_files_or_other_objects' }
                'UsersOrGroupsThatAreDeniedAccessToThisComputerFromTheNetwork' { $policyName = 'Deny_access_to_this_computer_from_the_network' }
                'UsersOrGroupsThatAreDeniedLogOnAsABatchJob' { $policyName = 'Deny_log_on_as_a_batch_job' }
                'UsersOrGroupsThatAreDeniedLogOnAsAService' { $policyName = 'Deny_log_on_as_a_service' }
                'UsersOrGroupsThatAreDeniedLogOnLocally' { $policyName = 'Deny_log_on_locally' }
                'UsersOrGroupsThatAreDeniedLogOnThroughRemoteDesktopServices' { $policyName = 'Deny_log_on_through_Remote_Desktop_Services' }
                default { 
                    Write-Warning "Unknown UserRightsAssignment parameter: $($param.Name)"
                    $policyName = $param.Name -replace ' ', '_'
                }
            }
            $dscResources += "            Policy = '$policyName'`r`n"
            $dscResources += "            Identity = `$$($param.Name)`r`n"
            $dscResources += "        }`r`n`r`n"
        } else {
            # For Administrative Templates, Windows Components, Windows Firewall - use Registry from PSDscResources
            if ($dscModules -notcontains "PSDscResources") { $dscModules += "PSDscResources" }
            $dscResources += "        Registry '$($param.Name)'`r`n"
            $dscResources += "        {`r`n"
            $dscResources += "            # TODO: Configure registry key for $($param.DisplayName)`r`n"
            $dscResources += "            Key = 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows\\Example'`r`n"
            $dscResources += "            ValueName = '$($param.Name)'`r`n"
            $dscResources += "            ValueData = `$$($param.Name)`r`n"
            $dscResources += "            ValueType = 'String'`r`n"
            $dscResources += "            Ensure = 'Present'`r`n"
            $dscResources += "        }`r`n`r`n"
        }
    }
    
    # Generate DSC imports
    $dscImports = ""
    foreach ($module in ($dscModules | Sort-Object -Unique)) {
        $dscImports += "    Import-DscResource -ModuleName $module`r`n"
    }
    
    # Replace placeholders
    $content = $template -replace "{CONFIGURATION_NAME}", $ConfigurationName
    $content = $content -replace "{PARAMETERS}", $parameterBlock
    $content = $content -replace "{DSC_IMPORTS}", $dscImports
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
        if ($param.Name -and $param.Name.Trim() -ne "") {
            $dscMapping = Get-DSCParameterMapping -ParameterName $param.Name -PolicyName $PolicyName -InputPolicy $OriginalPolicy
            $configurationParameters += "          `"$($param.Name)`": `"$dscMapping`",`r`n"
        }
    }
    $configurationParameters = $configurationParameters.TrimEnd(",`r`n")
    
    # Generate other template sections
    $parameterHashConcat = ($Parameters | Where-Object { $_.Name -and $_.Name.Trim() -ne "" } | ForEach-Object { 
        $dscMapping = Get-DSCParameterMapping -ParameterName $_.Name -PolicyName $PolicyName -InputPolicy $OriginalPolicy
        "'$dscMapping', '=', parameters('$($_.Name)')" 
    }) -join ", ',', "
    
    $deploymentParameters = ""
    $templateParameters = ""
    $configurationParameterArray = ""
    
    foreach ($param in $Parameters) {
        if ($param.Name -and $param.Name.Trim() -ne "") {
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
    $content = $content -replace "{CONTENT_URI}", "https://$($config.StorageAccount.Name).blob.core.windows.net/$($config.StorageAccount.ContainerName)/$ConfigurationName.zip"
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
    
    # Create directory structure
    $targetDir = Join-Path $OutputDir "GuestConfiguration\$ConfigurationName"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetDir "Output") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetDir "Modules") -Force | Out-Null
    
    # Create basic supporting files
    $filesToCreate = @{
        "Build-And-Deploy-Package.ps1" = @'
# Build and Deploy Guest Configuration Package
param(
    [switch]$Force,
    [switch]$Deploy,
    [switch]$UpdatePolicyFiles
)

$configName = "{CONFIGURATION_NAME}"
Write-Host "Building package for: $configName" -ForegroundColor Green

try {
    # Import required modules
    Import-Module GuestConfiguration -Force
    
    # Compile configuration
    . ".\$configName.ps1"
    & $configName
    
    # Create package
    $packageParams = @{
        Name = $configName
        Configuration = ".\$configName\localhost.mof"
        Path = ".\Output"
        Type = 'AuditAndSet'
        Force = $Force
    }
    
    $package = New-GuestConfigurationPackage @packageParams
    Write-Host "Package created: $($package.Path)" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to build package: $($_.Exception.Message)"
}
'@
        
        "Test-Configuration.ps1" = @'
# Test Guest Configuration Package
param(
    [string]$AssignmentType = "ApplyAndMonitor"
)

$configName = "{CONFIGURATION_NAME}"
Write-Host "Testing configuration: $configName" -ForegroundColor Green

try {
    $packagePath = ".\Output\$configName.zip"
    if (Test-Path $packagePath) {
        $testResult = Test-GuestConfigurationPackage -Path $packagePath
        Write-Host "Test result: $testResult" -ForegroundColor Cyan
    } else {
        Write-Warning "Package not found: $packagePath"
    }
} catch {
    Write-Error "Failed to test package: $($_.Exception.Message)"
}
'@
        
        "README.md" = @'
# {CONFIGURATION_NAME}

Guest Configuration package for Windows security policy compliance.

## Building the Package

```powershell
.\Build-And-Deploy-Package.ps1 -Force
```

## Testing the Package

```powershell
.\Test-Configuration.ps1
```

## Configuration Details

This package configures Windows security settings according to CIS benchmarks.
'@
    }
    
    # Create files with configuration name replacement
    foreach ($fileName in $filesToCreate.Keys) {
        $content = $filesToCreate[$fileName] -replace "{CONFIGURATION_NAME}", $ConfigurationName
        $filePath = Join-Path $targetDir $fileName
        Set-Content -Path $filePath -Value $content
    }
    
    # Create azure-config.json
    $azureConfig = @{
        Location = $AzureLocation
        SubscriptionId = $AzureSubscriptionId
        CreatedDate = (Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
        StorageAccount = @{
            Name = $AzureStorageAccountName
            ResourceGroupName = $AzureResourceGroupName
            ContainerName = $AzureStorageContainerName
        }
        Package = @{
            Name = $ConfigurationName
            Version = "1.0.0.0"
            CurrentContentHash = "PLACEHOLDER_HASH"
        }
    }
    
    $azureConfig | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $targetDir "azure-config.json")
    
    Write-Host "  ✓ Supporting files created" -ForegroundColor Green
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
    
    # Manual mappings for known parameter patterns
    $mappings = @{
        # User Rights Assignment - use exact values from original policies
        'UsersOrGroupsThatMayAccessThisComputerFromTheNetwork' = 'Access this computer from the network;ExpectedValue'
        'UsersOrGroupsThatMayLogOnLocally' = 'Allow log on locally;ExpectedValue'
        'UsersOrGroupsThatMayLogOnThroughRemoteDesktopServices' = 'Allow log on through Remote Desktop Services;ExpectedValue'
        'UsersAndGroupsThatAreDeniedAccessToThisComputerFromTheNetwork' = 'Deny access to this computer from the network;ExpectedValue'
        'UsersOrGroupsThatMayManageAuditingAndSecurityLog' = 'Manage auditing and security log;ExpectedValue'
        'UsersOrGroupsThatMayBackUpFilesAndDirectories' = 'Back up files and directories;ExpectedValue'
        'UsersOrGroupsThatMayChangeTheSystemTime' = 'Change the system time;ExpectedValue'
        'UsersOrGroupsThatMayChangeTheTimeZone' = 'Change the time zone;ExpectedValue'
        'UsersOrGroupsThatMayCreateATokenObject' = 'Create a token object;ExpectedValue'
        'UsersAndGroupsThatAreDeniedLoggingOnAsABatchJob' = 'Deny log on as a batch job;ExpectedValue'
        'UsersAndGroupsThatAreDeniedLoggingOnAsAService' = 'Deny log on as a service;ExpectedValue'
        'UsersAndGroupsThatAreDeniedLocalLogon' = 'Deny log on locally;ExpectedValue'
        'UsersAndGroupsThatAreDeniedLogOnThroughRemoteDesktopServices' = 'Deny log on through Remote Desktop Services;ExpectedValue'
        'UserAndGroupsThatMayForceShutdownFromARemoteSystem' = 'Force shutdown from a remote system;ExpectedValue'
        'UsersAndGroupsThatMayRestoreFilesAndDirectories' = 'Restore files and directories;ExpectedValue'
        'UsersAndGroupsThatMayShutDownTheSystem' = 'Shut down the system;ExpectedValue'
        'UsersOrGroupsThatMayTakeOwnershipOfFilesOrOtherObjects' = 'Take ownership of files or other objects;ExpectedValue'
        
        # Security Options - use exact values from original policies  
        'DevicesAllowedToFormatAndEjectRemovableMedia' = 'Devices: Allowed to format and eject removable media;ExpectedValue'
        
        # Audit Policies - use exact values from original policies
        'AuditCredentialValidation' = 'Audit Credential Validation;ExpectedValue'
    }
    
    if ($mappings.ContainsKey($ParameterName)) {
        Write-Host "  Found manual mapping for $ParameterName -> $($mappings[$ParameterName])" -ForegroundColor Yellow
        return $mappings[$ParameterName]
    }
    
    # Fallback to algorithmic mapping (for completeness, but should not be needed)
    Write-Warning "No exact mapping found for parameter $ParameterName in policy $PolicyName, using fallback"
    
    # Security Options mapping
    if ($PolicyName -like "*Security Options*") {
        return "SecurityOption;$ParameterName"
    }
    
    # Audit Policies mapping
    if ($PolicyName -like "*Audit Policies*") {
        return "AuditPolicy;$ParameterName"
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
    $shortFolderName = ConvertTo-ShortFolderName $PolicyName
    $parameters = Get-PolicyParameters $originalPolicy
    
    Write-Host "  Configuration name: $configurationName" -ForegroundColor Cyan
    Write-Host "  Short folder name: $shortFolderName" -ForegroundColor Cyan
    Write-Host "  Found $($parameters.Count) parameters" -ForegroundColor Cyan
    
    # Create output directory
    $policyOutputDir = Join-Path $outputPath $shortFolderName
    New-Item -ItemType Directory -Path $policyOutputDir -Force | Out-Null
    
    # Generate AuditIfNotExists policy (copy original with naming convention)
    $auditPolicy = $originalPolicy
    $auditPolicy.properties.displayName = $auditPolicy.properties.displayName -replace "Windows machines should meet requirements for", ""
    $auditPolicy.properties.displayName = "[GG Serverhardening] [AuditIfNotExists] Windows machines should meet requirements for" + $auditPolicy.properties.displayName
    $auditPolicy | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $policyOutputDir "AuditIfNotExists - $shortFolderName.json")
    
    # Generate DeployIfNotExists policy
    $deployPolicy = New-DeployIfNotExistsPolicy -OriginalPolicy $originalPolicy -ConfigurationName $configurationName -Parameters $parameters -PolicyName $policyName
    $deployPolicy | Set-Content (Join-Path $policyOutputDir "DeployIfNotExists - $shortFolderName.json")
    
    # Generate DSC configuration
    $dscConfiguration = New-DSCConfiguration -ConfigurationName $configurationName -Parameters $parameters -PolicyName $PolicyName
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
