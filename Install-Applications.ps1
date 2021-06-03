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

<# #region O365 OPP

try {
  & c:/ODT/ODT_tool.exe /quiet /extract:c:/ODT
  #Start-Process -filepath "setup.exe" -WorkingDirectory "c:\ODT" -ArgumentList '/download', 'c:/ODT/installOfficeProPlus64.xml' -Wait -ErrorAction Stop
  #Start-Process -filepath "setup.exe" -WorkingDirectory "c:\ODT" -ArgumentList '/configure', 'c:/ODT/installOfficeProPlus64.xml' -Wait -ErrorAction SilentlyContinue
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

#region regedit for FSLogix
New-ItemProperty -Path "HKLM:\Software\FSLogix\Profiles" -Name "VHDLocations" -Value "\\ejm5204azfiles.file.core.windows.net\ejm5204azfiles\profiles"
#endregion

#region install and registration for WVD agents
$resourceGroupName = "AIRS_WVD_Logical_Components"
$Hostpool = "AIRS_WVD_HostPool"
$SubsciptionID = "c6973119-11cd-4828-ad30-5d84a7e7be7e"
    
$GetToken = New-AzWvdRegistrationInfo -SubscriptionId $SubsciptionID -ResourceGroupName $resourceGroupName -HostPoolName $Hostpool -ExpirationTime (Get-Date).AddDays(14) -ErrorAction SilentlyContinue
$token = $GetToken.Token

try {
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\rdpbits\Microsoft.RDInfra.RDAgent.Installer-x64-1.0.2990.1500.msi', '/quiet'
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\rdpbits\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64 (7).msi', '/quiet'
    #New-ItemProperty -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -Name "IsRegistered" -Value $token -Force **this needs to be a reg key change**
    Write-Log "Agents have been run, check filepaths to confirm."
    Write-Log "Token: $token" #variable is not passed into log
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Log "Error with WVD agents: $ErrorMessage"
}

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
