enum Ensure
{
    Absent
    Present
}

[DscResource()]
class AuditPolicySubcategory
{
    [DscProperty(Key)]
    [string] $Name

    [DscProperty(Mandatory)]
    [ValidateSet("No Auditing", "Success", "Failure", "Success and Failure")]
    [string] $AuditFlag

    [DscProperty()]
    [Ensure] $Ensure = [Ensure]::Present

    [AuditPolicySubcategory] Get()
    {
        $currentState = [AuditPolicySubcategory]::new()
        $currentState.Name = $this.Name
        $currentState.Ensure = [Ensure]::Present

        try
        {
            # Get current audit policy setting
            $auditpol = & auditpol.exe /get /subcategory:"$($this.Name)" /r
            if ($LASTEXITCODE -eq 0)
            {
                $csvData = $auditpol | ConvertFrom-Csv
                $subcategoryData = $csvData | Where-Object { $_.'Subcategory' -like "*$($this.Name)*" }
                
                if ($subcategoryData)
                {
                    $inclusionSetting = $subcategoryData.'Inclusion Setting'
                    switch ($inclusionSetting)
                    {
                        'Success' { $currentState.AuditFlag = 'Success' }
                        'Failure' { $currentState.AuditFlag = 'Failure' }
                        'Success and Failure' { $currentState.AuditFlag = 'Success and Failure' }
                        'No Auditing' { $currentState.AuditFlag = 'No Auditing' }
                        default { $currentState.AuditFlag = 'No Auditing' }
                    }
                }
                else
                {
                    $currentState.AuditFlag = 'No Auditing'
                }
            }
            else
            {
                $currentState.AuditFlag = 'No Auditing'
            }
        }
        catch
        {
            Write-Warning "Failed to get audit policy for subcategory '$($this.Name)': $($_.Exception.Message)"
            $currentState.AuditFlag = 'No Auditing'
        }

        return $currentState
    }

    [void] Set()
    {
        if ($this.Ensure -eq [Ensure]::Present)
        {
            try
            {
                # Set the audit policy based on the desired state
                if ($this.AuditFlag -eq 'Success and Failure')
                {
                    # Enable both success and failure
                    & auditpol.exe /set /subcategory:"$($this.Name)" /success:enable /failure:enable
                }
                elseif ($this.AuditFlag -eq 'Success')
                {
                    & auditpol.exe /set /subcategory:"$($this.Name)" /success:enable /failure:disable
                }
                elseif ($this.AuditFlag -eq 'Failure')
                {
                    & auditpol.exe /set /subcategory:"$($this.Name)" /success:disable /failure:enable
                }
                else
                {
                    & auditpol.exe /set /subcategory:"$($this.Name)" /success:disable /failure:disable
                }

                if ($LASTEXITCODE -ne 0)
                {
                    throw "Failed to set audit policy for subcategory '$($this.Name)'"
                }
            }
            catch
            {
                throw "Failed to set audit policy for subcategory '$($this.Name)': $($_.Exception.Message)"
            }
        }
    }

    [bool] Test()
    {
        $currentState = $this.Get()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return ($currentState.AuditFlag -eq $this.AuditFlag)
        }
        else
        {
            return ($currentState.AuditFlag -eq 'No Auditing')
        }
    }
}
