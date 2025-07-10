Configuration AzureBaseline_SecurityOptions_UserAccountControl
{
    param
    (
        [Parameter()]
        [string]$UACAdminApprovalModeForTheBuiltinAdministratorAccount = 'Enabled',

        [Parameter()]
        [string]$UACBehaviorOfTheElevationPromptForAdministratorsInAdminApprovalMode = 'Prompt for consent on the secure desktop',

        [Parameter()]
        [string]$UACDetectApplicationInstallationsAndPromptForElevation = 'Enabled',

        [Parameter()]
        [string]$UACRunAllAdministratorsInAdminApprovalMode = 'Enabled'

    )

    Import-DscResource -ModuleName 'SecurityPolicyDsc'

    Node localhost
    {
        SecurityOption 'UACAdminApprovalModeForTheBuiltinAdministratorAccount'
        {
            Name = 'UACAdminApprovalModeForTheBuiltinAdministratorAccount'
            User_Account_Control_Admin_Approval_Mode_for_the_Built_in_Administrator_account = $UACAdminApprovalModeForTheBuiltinAdministratorAccount
        }
        SecurityOption 'UACBehaviorOfTheElevationPromptForAdministratorsInAdminApprovalMode'
        {
            Name = 'UACBehaviorOfTheElevationPromptForAdministratorsInAdminApprovalMode'
            User_Account_Control_Behavior_of_the_elevation_prompt_for_administrators_in_Admin_Approval_Mode = $UACBehaviorOfTheElevationPromptForAdministratorsInAdminApprovalMode
        }
        SecurityOption 'UACDetectApplicationInstallationsAndPromptForElevation'
        {
            Name = 'UACDetectApplicationInstallationsAndPromptForElevation'
            User_Account_Control_Detect_application_installations_and_prompt_for_elevation = $UACDetectApplicationInstallationsAndPromptForElevation
        }
        SecurityOption 'UACRunAllAdministratorsInAdminApprovalMode'
        {
            Name = 'UACRunAllAdministratorsInAdminApprovalMode'
            User_Account_Control_Run_all_administrators_in_Admin_Approval_Mode = $UACRunAllAdministratorsInAdminApprovalMode
        }
    }
}


