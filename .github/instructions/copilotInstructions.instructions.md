---
applyTo: '**'
---

# Coding Standards and Domain Knowledge

## General Guidelines
- Always check documentation and existing code before suggesting changes
- Gather context first - Don't make assumptions
- Create a file azure.config and store the following variables:
  - $AzureSubscriptionId
  - $AzureResourceGroupName
  - $AzureLocation
- Always refer to the azure.config file for Azure variables

## Script and Fix Management
- Do not create separate fix scripts
- Use convert-policies.ps1 to convert policies
- When issues are found:
  1. Delete the output policies
  2. Fix the original conversion script
  3. Reconvert the policies using the updated script
- Always update the original script when making corrections

## Policy Management
- use Manage-Policies.ps1 to manage policies
- Make sure the following functions are available:
  1. deploy policies to Azure
  2. remove policies from Azure
  3. get policies from Azure
  4. remove policy assignments from Azure

- We are working with Azure Guest Configuration policies
- When fixing one policy, identify if there are others that need similar fixes
- When converting policies, ensure the output policy matches the original policy's parameters
- Always compare the original policy from the input folder to verify the output policy is correct
- Ensure only the parameters of the original policies exist in the output
 
## Testing Requirements
- Test all 29 policies after any changes
- Verify output matches original policy parameters
- Ensure no additional parameters are introduced during conversion