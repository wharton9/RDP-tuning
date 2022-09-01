
#Requires -RunAsAdministrator

  #This script is copied from microsoft VDOT opensource project, and modify it for RDP tuning
  # Tuning RDP performance via modifying RDP registry values 
  #   
  # Date:1st Sept. 2022
  # Wharton Wang
  #

 <#
- DEPENDENCIES    1. On the target machine, run PowerShell elevated (as administrator)
                  2. Within PowerShell, set exectuion policy to enable the running of scripts.
                     Ex. Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
                  3. This PowerShell script
                  4. The Json configuration file which named PolicyRegSettings.
- REFERENCES:
https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
  #>
        $LocalPolicyFilePath = ".\PolicyRegSettings.json"
	$EventSources="LGPO"
    If (-not([System.Diagnostics.EventLog]::Exists("Virtual Desktop Optimization")))
    {
        New-EventLog -Source $EventSources -LogName 'Virtual Desktop Optimization'
    }
        If (Test-Path $LocalPolicyFilePath)
        {
            Write-EventLog -EventId 80 -Message "Local Group Policy Items" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
            Write-Host "[RDP Tuning] Local Group Policy Items" -ForegroundColor Cyan
            $PolicyRegSettings = Get-Content $LocalPolicyFilePath | ConvertFrom-Json
            If ($PolicyRegSettings.Count -gt 0)
            {
                Write-EventLog -EventId 80 -Message "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                Write-Verbose "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)"
                Foreach ($Key in $PolicyRegSettings)
                {
                    If ($Key.VDIState -eq 'Enabled')
                    {
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue) 
                        { 
                            Write-EventLog -EventId 80 -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                            Write-Verbose "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
			    # after getting the json values and edit the registry values
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force 
                        }
                        Else 
                        { 
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-EventLog -EventId 80 -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                                Write-Verbose "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
				# if the registry values does not exist,then create new one
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
                            Else
                            {
                                Write-EventLog -EventId 80 -Message "Creating Key and Path" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                                Write-Verbose "Creating Key and Path"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
            
                        }
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 80 -Message "No LGPO Settings Found!" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Warning
                Write-Warning "No LGPO Settings found"
            }
        }
        Else 
        {
                Write-EventLog -EventId 80 -Message "Json Config File not found" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Warning
                Write-Warning "Json Config File not found"
            
        }    
    
   Write-Host "[RDP Tuning] Editing Local Group Policies Executed.Please check above info. or system events if any error occured." -ForegroundColor Cyan
    #end
