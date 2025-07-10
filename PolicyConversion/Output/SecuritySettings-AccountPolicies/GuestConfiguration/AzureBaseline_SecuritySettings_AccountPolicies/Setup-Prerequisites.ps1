# Setup Prerequisites for Guest Configuration
# This script helps create the required Azure resources for Guest Configuration deployment

param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure Subscription ID")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Resource Group name (will be created if it doesn't exist)")]
    [string]$ResourceGroupName = "RG_ARC_Local_All_RestoreTest",
    
    [Parameter(Mandatory = $false, HelpMessage = "Azure region for resources")]
    [string]$Location = "West Europe",
    
    [Parameter(Mandatory = $false, HelpMessage = "Storage Account name (must be globally unique)")]
    [string]$StorageAccountName = "SAServerHardening",
    
    [Parameter(Mandatory = $false, HelpMessage = "Install required PowerShell modules")]
    [switch]$InstallModules
)

# Generate unique storage account name if not provided
if ([string]::IsNullOrEmpty($StorageAccountName))
{
    $randomSuffix = -join ((1..8) | ForEach-Object { [char]((97..122) + (48..57) | Get-Random) })
    $StorageAccountName = "stguestconfig$randomSuffix"
}

# Validate storage account name meets Azure requirements
if ($StorageAccountName -cmatch '[A-Z]' -or $StorageAccountName -match '[^a-z0-9]' -or $StorageAccountName.Length -lt 3 -or $StorageAccountName.Length -gt 24)
{
    Write-Warning "Storage account name '$StorageAccountName' doesn't meet Azure requirements."
    Write-Host "Azure storage account names must:" -ForegroundColor Yellow
    Write-Host "- Be 3-24 characters long" -ForegroundColor Yellow
    Write-Host "- Contain only lowercase letters and numbers" -ForegroundColor Yellow
    Write-Host "- Be globally unique" -ForegroundColor Yellow
    
    # Generate a compliant name
    $cleanName = $StorageAccountName.ToLower() -replace '[^a-z0-9]', ''
    if ($cleanName.Length -gt 24) { $cleanName = $cleanName.Substring(0, 24) }
    if ($cleanName.Length -lt 3) { $cleanName = "stguestconfig" }
    
    $randomSuffix = -join ((1..6) | ForEach-Object { [char]((97..122) + (48..57) | Get-Random) })
    $StorageAccountName = "$cleanName$randomSuffix"
    if ($StorageAccountName.Length -gt 24) { $StorageAccountName = $StorageAccountName.Substring(0, 24) }
    
    Write-Host "Using compliant name: $StorageAccountName" -ForegroundColor Green
}

Write-Host "=== Guest Configuration Prerequisites Setup ===" -ForegroundColor Magenta
Write-Host "Subscription ID: $SubscriptionId" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor White

# Install required modules if requested
if ($InstallModules)
{
    Write-Host "`nInstalling required PowerShell modules..." -ForegroundColor Green
    $requiredModules = @('Az.Accounts', 'Az.Storage', 'Az.Resources', 'GuestConfiguration')
    foreach ($module in $requiredModules)
    {
        if (-not (Get-Module -ListAvailable -Name $module))
        {
            Write-Host "Installing $module..." -ForegroundColor Yellow
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
        }
        else
        {
            Write-Host "✓ $module already installed" -ForegroundColor Green
        }
    }
}

try
{
    # Import required modules
    Write-Host "`nImporting Azure modules..." -ForegroundColor Green
    Import-Module Az.Accounts, Az.Storage, Az.Resources -ErrorAction Stop
    
    # Connect to Azure
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    $context = Connect-AzAccount -SubscriptionId $SubscriptionId
    if (-not $context)
    {
        throw "Failed to connect to Azure. Please check your credentials."
    }
    Write-Host "✓ Connected to Azure subscription: $($context.Context.Subscription.Name)" -ForegroundColor Green
    
    # Create or verify resource group
    Write-Host "`nChecking resource group..." -ForegroundColor Green
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup)
    {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "✓ Resource group created" -ForegroundColor Green
    }
    else
    {
        Write-Host "✓ Resource group exists: $ResourceGroupName" -ForegroundColor Green
    }
    
    # Check if storage account already exists
    Write-Host "`nChecking storage account..." -ForegroundColor Green
    $existingStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    
    if ($existingStorageAccount)
    {
        Write-Host "✓ Storage account already exists: $StorageAccountName" -ForegroundColor Green
        $storageAccount = $existingStorageAccount
    }
    else
    {
        Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Yellow
        Write-Host "This may take a few minutes..." -ForegroundColor Gray
        
        # Validate storage account name
        $nameAvailability = Get-AzStorageAccountNameAvailability -Name $StorageAccountName
        if (-not $nameAvailability.NameAvailable)
        {
            throw "Storage account name '$StorageAccountName' is not available: $($nameAvailability.Reason)"
        }
        
        $storageAccount = New-AzStorageAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName "Standard_LRS" `
            -Kind "StorageV2" `
            -AllowBlobPublicAccess $true `
            -EnableHttpsTrafficOnly $true
            
        Write-Host "✓ Storage account created successfully" -ForegroundColor Green
    }
    
    # Verify blob public access is enabled
    if (-not $storageAccount.AllowBlobPublicAccess)
    {
        Write-Host "Enabling blob public access..." -ForegroundColor Yellow
        Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -AllowBlobPublicAccess $true
        Write-Host "✓ Blob public access enabled" -ForegroundColor Green
    }
    
    Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
    Write-Host "✓ All prerequisites are configured!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Run Build-GuestConfigurationPackage.ps1 to create the package" -ForegroundColor White
    Write-Host "2. Run Deploy-GuestConfigurationPackage.ps1 with these parameters:" -ForegroundColor White
    Write-Host "   -SubscriptionId '$SubscriptionId'" -ForegroundColor Gray
    Write-Host "   -ResourceGroupName '$ResourceGroupName'" -ForegroundColor Gray
    Write-Host "   -StorageAccountName '$StorageAccountName'" -ForegroundColor Gray
    
    # Save configuration for later use
    $configFile = ".\azure-config.json"
    $config = @{
        SubscriptionId = $SubscriptionId
        ResourceGroupName = $ResourceGroupName
        StorageAccountName = $StorageAccountName
        Location = $Location
        CreatedDate = (Get-Date).ToString()
    }
    $config | ConvertTo-Json | Out-File -FilePath $configFile -Encoding UTF8
    Write-Host "`nConfiguration saved to: $configFile" -ForegroundColor Yellow
}
catch
{
    Write-Error "Setup failed: $($_.Exception.Message)"
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "- Ensure you have Contributor permissions on the subscription" -ForegroundColor White
    Write-Host "- Check that the storage account name is globally unique" -ForegroundColor White
    Write-Host "- Verify the Azure region supports Guest Configuration" -ForegroundColor White
    exit 1
}

Write-Host "`nSetup completed successfully!" -ForegroundColor Green

