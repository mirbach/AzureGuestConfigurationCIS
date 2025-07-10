# AuditPolicyDsc Module
# This module provides DSC resources for managing Windows audit policies

# Import all DSC resources
$dscResourcesPath = Join-Path -Path $PSScriptRoot -ChildPath 'DSCResources'
if (Test-Path -Path $dscResourcesPath)
{
    Get-ChildItem -Path $dscResourcesPath -Directory | ForEach-Object {
        $resourceModulePath = Join-Path -Path $_.FullName -ChildPath "$($_.Name).psm1"
        if (Test-Path -Path $resourceModulePath)
        {
            Import-Module -Name $resourceModulePath -Force
        }
    }
}
