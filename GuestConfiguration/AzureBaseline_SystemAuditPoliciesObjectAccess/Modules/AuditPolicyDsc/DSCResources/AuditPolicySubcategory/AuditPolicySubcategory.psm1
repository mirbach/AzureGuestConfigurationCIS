function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("No Auditing", "Success", "Failure", "Success and Failure")]
        [System.String]
        $AuditFlag,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $returnValue = @{
        Name = $Name
        AuditFlag = "No Auditing"
        Ensure = "Present"
    }

    try
    {
        # Get current audit policy setting
        $auditpol = & auditpol.exe /get /subcategory:"$Name" /r
        if ($LASTEXITCODE -eq 0)
        {
            $csvData = $auditpol | ConvertFrom-Csv
            $subcategoryData = $csvData | Where-Object { $_.'Subcategory' -like "*$Name*" }
            
            if ($subcategoryData)
            {
                $inclusionSetting = $subcategoryData.'Inclusion Setting'
                switch ($inclusionSetting)
                {
                    'Success' { $returnValue.AuditFlag = 'Success' }
                    'Failure' { $returnValue.AuditFlag = 'Failure' }
                    'Success and Failure' { $returnValue.AuditFlag = 'Success and Failure' }
                    'No Auditing' { $returnValue.AuditFlag = 'No Auditing' }
                    default { $returnValue.AuditFlag = 'No Auditing' }
                }
            }
            else
            {
                $returnValue.AuditFlag = 'No Auditing'
            }
        }
        else
        {
            $returnValue.AuditFlag = 'No Auditing'
        }
    }
    catch
    {
        Write-Warning "Failed to get audit policy for subcategory '$Name': $($_.Exception.Message)"
        $returnValue.AuditFlag = 'No Auditing'
    }

    return $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("No Auditing", "Success", "Failure", "Success and Failure")]
        [System.String]
        $AuditFlag,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    if ($Ensure -eq "Present")
    {
        try
        {
            # Set the audit policy based on the desired state
            if ($AuditFlag -eq 'Success and Failure')
            {
                # Enable both success and failure
                & auditpol.exe /set /subcategory:"$Name" /success:enable /failure:enable
            }
            elseif ($AuditFlag -eq 'Success')
            {
                & auditpol.exe /set /subcategory:"$Name" /success:enable /failure:disable
            }
            elseif ($AuditFlag -eq 'Failure')
            {
                & auditpol.exe /set /subcategory:"$Name" /success:disable /failure:enable
            }
            else
            {
                & auditpol.exe /set /subcategory:"$Name" /success:disable /failure:disable
            }

            if ($LASTEXITCODE -ne 0)
            {
                throw "Failed to set audit policy for subcategory '$Name'"
            }
        }
        catch
        {
            throw "Failed to set audit policy for subcategory '$Name': $($_.Exception.Message)"
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("No Auditing", "Success", "Failure", "Success and Failure")]
        [System.String]
        $AuditFlag,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $currentState = Get-TargetResource -Name $Name -AuditFlag $AuditFlag -Ensure $Ensure
    
    if ($Ensure -eq "Present")
    {
        return ($currentState.AuditFlag -eq $AuditFlag)
    }
    else
    {
        return ($currentState.AuditFlag -eq 'No Auditing')
    }
}

Export-ModuleMember -Function Get-TargetResource, Set-TargetResource, Test-TargetResource
