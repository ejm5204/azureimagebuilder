# Software install Script
#
# Applications to install:
#
# DoD Teams: https://dod.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true
# O365 OPP
# FSlogix
# WVD Agents
# 
# If the customer tenant is on the GCCH or DoD clouds, the customer should
# set the intial endpoint in the registry by adding the CloudType value to
# HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Office\16.0\Teams key in
# the registry. The type for CloudType is DWORD and values are (0 = Unset)
# , 1 = Commercial, 2 = GCC, 3 = GCCH, 4 = DOD). Setting the endpoint with
# the registry keys restricts Teams to connecting to the correct cloud
# endpoint for pre-sign-in connectivity with Teams.


#region Set logging 
$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_softwareinstall.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}
#endregion

#region DoD Teams
try {
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\Teams_windows_x64.msi', '/quiet'
    & "C:\Program Files (x86)\Teams Installer\Teams.exe"
    if (Test-Path "C:\Program Files (x86)\Teams Installer\Teams.exe") {
        Write-Log "DoD Teams has been installed"
    }
    else {
        write-log "Error locating the DoD Teams executable"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing DoD Teams: $ErrorMessage"
}

Get-Item -Path 'HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Office\16.0\Teams' | New-Item -Name 'CloudType' -Value "" -Force
#endregion

 #region O365 OPP

try {
  & c:/ODT/ODT_tool.exe /quiet /extract:c:/ODT
  Start-Process -filepath "setup.exe" -WorkingDirectory "c:\ODT" -ArgumentList '/download', 'c:/ODT/installOfficeProPlus64.xml' -Wait -ErrorAction Stop
  Start-Process -filepath "setup.exe" -WorkingDirectory "c:\ODT" -ArgumentList '/configure', 'c:/ODT/installOfficeProPlus64.xml' -Wait -ErrorAction SilentlyContinue
  #Start-Process -filepath "setup.exe" -WorkingDirectory "c:\ODT" -ArgumentList '/configure', 'c:/ODT/installCustom.xml' -Wait -ErrorAction SilentlyContinue
  if (Test-Path "C:\Program Files\Microsoft Office") {
      Write-Log "Office has been installed"
  }
  else {
      write-log "Error with Office executable"
  }
}
catch {
  $ErrorMessage = $_.Exception.message
  $fullErrorMessage = $_.Exception
  write-log "Error installing Office: $ErrorMessage"
  write-log "Full error message: $fullErrorMessage"
}
#endregion #>

#region fslogix install
try {
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\FSLogix_Apps_2.9.7654.46150.zip\x64\Release\FSLogixAppsSetup.exe', '/quiet'
    if (Test-Path "C:\Program Files\FSLogix\Apps\frx.exe") {
        Write-Log "FSLogix has been installed"
    }
    else {
        Write-Log "Error installing FSLogix"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Log "Error installing FSLogix: $ErrorMessage"
}
#endregion

<# #region regedit for FSLogix
New-ItemProperty -Path "HKLM:\Software\FSLogix\Profiles" -Name "VHDLocations" -Value "\\ejm5204azfiles.file.core.windows.net\ejm5204azfiles\profiles"
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -Name "RegistrationToken" -Value "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk3NkE4Q0I1MTQwNjkyM0E4MkU4QUQ3MUYzQjE4NzEyN0Y2OTRDOTkiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjAyYmRkMDhmLTk4ODktNDM4My04NjBkLWJjM2I1ODE4ZjU4YiIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiNDVlMTIxZWEtYWEwYy00MzA5LTgzMjItNjdiYjhiZjc0YTE0IiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIm5iZiI6MTYyNjcxNjY0OSwiZXhwIjoxNjI3OTI2MjQ2LCJpc3MiOiJSREluZnJhVG9rZW5NYW5hZ2VyIiwiYXVkIjoiUkRtaSJ9.h6gDrtBcuQdI9WYy5N9iMnfUEf536pgkP1iYUsO81GTL7f3AA6SW9BJbDCzSmjtzjHdpJynKrTzx8OgT-I0tn4oMi8X5xCJBKIbECqca1umq8fPn5bu3Y7cwNeECpzuNXepjy6_DQ1yB0hjgJxQPhyLkYl-iN2Bfc_vnfdJMGART-pBgJy7cgYHjc3ojJQD53Bcr5nSMpO2VsWFYIlXt7LtfqSof_MqU8wl1QAeuL3R6WqH1aX4ScwIbkvL6crAxPWum8DDKSh_w7QdcIh-57g3jrE3uN8XhkF-B0pNsz7THL8mehqD1qFlCShMK6Pf9Lhp3voZm4i2HGVf_H3mcfg"
#endregion

#region install and registration for WVD agents
Set-AzContext "Dev"
$resourceGroupName = "AVD"
$Hostpool = "AVD_HostPool"
$SubscriptionID = "c6973119-11cd-4828-ad30-5d84a7e7be7e"

$hostPoolRegKey = (New-AzWvdRegistrationInfo -SubscriptionId $SubscriptionID -ResourceGroupName $resourceGroupName -HostPoolName $Hostpool -ExpirationTime (Get-Date).AddDays(14) -ErrorAction SilentlyContinue).Token
Set-AzContext "AIRS"
Get-AzWvdRegistrationInfo -SubscriptionId $SubscriptionID -ResourceGroupName $resourceGroupName -HostPoolName $Hostpool #>

<# try {
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\rdpbits\Microsoft.RDInfra.RDAgent.Installer-x64-1.0.2990.1500.msi', '/quiet', "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk3NkE4Q0I1MTQwNjkyM0E4MkU4QUQ3MUYzQjE4NzEyN0Y2OTRDOTkiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjY0MzQwZDc5LTE3NWUtNDA0OS04ZmMwLTllOTJlMzVkN2M1NyIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiNDVlMTIxZWEtYWEwYy00MzA5LTgzMjItNjdiYjhiZjc0YTE0IiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIm5iZiI6MTYyNjc5ODYxMSwiZXhwIjoxNjI4MDA4MjA4LCJpc3MiOiJSREluZnJhVG9rZW5NYW5hZ2VyIiwiYXVkIjoiUkRtaSJ9.AOKhXBhqWXt5g6xVE9Bs29iGg4zdNPHKwvsYKJCxCfkW0BoknZHvCjSGs9pgoVh0p8vWnfwIJ2SnIwHaHBQMfSErLO3AGN-NtLSg-Rr46P6f1pNF-HkJk1gvjGs9XAhAic9OhG6Q8JEMJm2-HRFlIXN5WaOQSGvIyj5T490kWWIQ5T2L3z9qqe_iNTnwcuB8a5L5evDOjythfKINqm4os_P3H3rll0T0K8ey1X7dZWC-vgorAjt4DNxy1wt6HsTuwEkkZtgoPuiYsmuV7lgaz3pOn8ottaYzFVOL11MR2oI26hhovx7uirZ8AX1d9vaUhNLJieWFB_kvEs_uxijxjA" | Wait-Process
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\rdpbits\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi', '/quiet', "/qn", "/norestart", "/passive" | Wait-Process
    Write-Log "Agents have been run, check filepaths to confirm."
    Write-Log "New image update #3"
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Log "Error with WVD agents: $ErrorMessage"
} #>

#endregion

#region Sysprep Fix
# Fix for first login delays due to Windows Module Installer
try {
    ((Get-Content -path C:\DeprovisioningScript.ps1 -Raw) -replace 'Sysprep.exe /oobe /generalize /quiet /quit', 'Sysprep.exe /oobe /generalize /quit /mode:vm' ) | Set-Content -Path C:\DeprovisioningScript.ps1
    write-log "Sysprep Mode:VM fix applied"
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error updating script: $ErrorMessage"
}
#endregion
