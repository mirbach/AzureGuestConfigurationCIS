Configuration AzureBaseline_SystemAuditPoliciesObjectAccess
{
    param
    (
        [Parameter()]
        [string]$AuditDetailedFileShare = 'No Auditing',

        [Parameter()]
        [string]$AuditFileShare = 'No Auditing',

        [Parameter()]
        [string]$AuditFileSystem = 'No Auditing'
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Script 'ConfigureDetailedFileShareAuditing'
        {
            GetScript = {
                try {
                    $auditResult = & auditpol.exe /get /subcategory:"Detailed File Share" /r 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $csvData = $auditResult | ConvertFrom-Csv
                        $currentSetting = ($csvData | Where-Object { $_.'Subcategory' -like "*Detailed File Share*" }).'Inclusion Setting'
                        return @{ Result = $currentSetting }
                    }
                }
                catch {
                    return @{ Result = 'No Auditing' }
                }
                return @{ Result = 'No Auditing' }
            }
            
            SetScript = {
                $targetSetting = $using:AuditDetailedFileShare
                if ($targetSetting -eq 'Success and Failure') {
                    & auditpol.exe /set /subcategory:"Detailed File Share" /success:enable /failure:enable
                } elseif ($targetSetting -eq 'Success') {
                    & auditpol.exe /set /subcategory:"Detailed File Share" /success:enable /failure:disable
                } elseif ($targetSetting -eq 'Failure') {
                    & auditpol.exe /set /subcategory:"Detailed File Share" /success:disable /failure:enable
                } else {
                    & auditpol.exe /set /subcategory:"Detailed File Share" /success:disable /failure:disable
                }
            }
            
            TestScript = {
                $targetSetting = $using:AuditDetailedFileShare
                try {
                    $auditResult = & auditpol.exe /get /subcategory:"Detailed File Share" /r 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $csvData = $auditResult | ConvertFrom-Csv
                        $currentSetting = ($csvData | Where-Object { $_.'Subcategory' -like "*Detailed File Share*" }).'Inclusion Setting'
                        return ($currentSetting -eq $targetSetting)
                    }
                }
                catch {
                    return $false
                }
                return $false
            }
        }

        Script 'ConfigureFileShareAuditing'
        {
            GetScript = {
                try {
                    $auditResult = & auditpol.exe /get /subcategory:"File Share" /r 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $csvData = $auditResult | ConvertFrom-Csv
                        $currentSetting = ($csvData | Where-Object { $_.'Subcategory' -like "*File Share*" }).'Inclusion Setting'
                        return @{ Result = $currentSetting }
                    }
                }
                catch {
                    return @{ Result = 'No Auditing' }
                }
                return @{ Result = 'No Auditing' }
            }
            
            SetScript = {
                $targetSetting = $using:AuditFileShare
                if ($targetSetting -eq 'Success and Failure') {
                    & auditpol.exe /set /subcategory:"File Share" /success:enable /failure:enable
                } elseif ($targetSetting -eq 'Success') {
                    & auditpol.exe /set /subcategory:"File Share" /success:enable /failure:disable
                } elseif ($targetSetting -eq 'Failure') {
                    & auditpol.exe /set /subcategory:"File Share" /success:disable /failure:enable
                } else {
                    & auditpol.exe /set /subcategory:"File Share" /success:disable /failure:disable
                }
            }
            
            TestScript = {
                $targetSetting = $using:AuditFileShare
                try {
                    $auditResult = & auditpol.exe /get /subcategory:"File Share" /r 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $csvData = $auditResult | ConvertFrom-Csv
                        $currentSetting = ($csvData | Where-Object { $_.'Subcategory' -like "*File Share*" }).'Inclusion Setting'
                        return ($currentSetting -eq $targetSetting)
                    }
                }
                catch {
                    return $false
                }
                return $false
            }
        }

        Script 'ConfigureFileSystemAuditing'
        {
            GetScript = {
                try {
                    $auditResult = & auditpol.exe /get /subcategory:"File System" /r 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $csvData = $auditResult | ConvertFrom-Csv
                        $currentSetting = ($csvData | Where-Object { $_.'Subcategory' -like "*File System*" }).'Inclusion Setting'
                        return @{ Result = $currentSetting }
                    }
                }
                catch {
                    return @{ Result = 'No Auditing' }
                }
                return @{ Result = 'No Auditing' }
            }
            
            SetScript = {
                $targetSetting = $using:AuditFileSystem
                if ($targetSetting -eq 'Success and Failure') {
                    & auditpol.exe /set /subcategory:"File System" /success:enable /failure:enable
                } elseif ($targetSetting -eq 'Success') {
                    & auditpol.exe /set /subcategory:"File System" /success:enable /failure:disable
                } elseif ($targetSetting -eq 'Failure') {
                    & auditpol.exe /set /subcategory:"File System" /success:disable /failure:enable
                } else {
                    & auditpol.exe /set /subcategory:"File System" /success:disable /failure:disable
                }
            }
            
            TestScript = {
                $targetSetting = $using:AuditFileSystem
                try {
                    $auditResult = & auditpol.exe /get /subcategory:"File System" /r 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $csvData = $auditResult | ConvertFrom-Csv
                        $currentSetting = ($csvData | Where-Object { $_.'Subcategory' -like "*File System*" }).'Inclusion Setting'
                        return ($currentSetting -eq $targetSetting)
                    }
                }
                catch {
                    return $false
                }
                return $false
            }
        }
    }
}
