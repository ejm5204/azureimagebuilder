# Software install Script
#
# Applications to install:
#
# Enterprise Chrome
# DoD Teams: https://dod.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true
# O365 OPP
# 
# See comments on creating a custom setting to disable auto update message
# https://community.notepad-plus-plus.org/post/38160


#region Set logging 
$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_softwareinstall.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}
#endregion

#region sasToken variable test
$sasToken = (New-AzStorageBlobSASToken -Container "ejm5204azfiles" -Blob "install_office.zip" -FullUri -Permission r -StartTime (Get-Date) -ExpiryTime (Get-Date).AddHours(4))
$sasToken | Out-File -FilePath c:\sasLog.txt


<#

c:/temp/azcopy.exe copy 'https://ejm5204azfiles.blob.core.windows.net/softwareresources/Chrome.zip?sp=r&st=2021-05-25T12:06:44Z&se=2021-06-01T20:06:44Z&spr=https&sv=2020-02-10&sr=b&sig=B%2Fb%2FUKTOtHoE8v2iy1gih6Dmnb8NES5ZabdofqFCS5o%3D' c:/temp/software.zip
c:/temp/azcopy.exe copy 'https://ejm5204azfiles.blob.core.windows.net/softwareresources/DoD_Teams.zip?sp=r&st=2021-05-25T12:06:58Z&se=2021-06-01T20:06:58Z&spr=https&sv=2020-02-10&sr=b&sig=gJNk6Cw470x4ZBfMDc9USX%2FQEWdWa2Tj9gfcs71jjVM%3D' c:/temp/teamssoftware.zip
c:/temp/azcopy.exe copy 'https://ejm5204azfiles.blob.core.windows.net/softwareresources/ODT_tool.zip?sp=r&st=2021-05-25T12:07:16Z&se=2021-06-01T20:07:16Z&spr=https&sv=2020-02-10&sr=b&sig=%2FiUWI6tW%2F1Xy%2F%2BwmlflDQ%2FSkAYTq1tN2LLm2hobtFsA%3D' c:/temp/ODT_tool.zip
c:/temp/azcopy.exe copy '' c:/temp/Secure-Host-Baseline.zip
Expand-Archive 'c:/temp/software.zip' c:/temp/
Expand-Archive 'c:temp/teamssoftware.zip' c:/temp
Expand-Archive 'c:/temp/ODT_tool.zip' c:/temp

Following line may need to be fixed for file directory consistency (see line 39)
Expand-Archive 'c:/temp/Secure-Host-Baseline.zip' c:/temp/Secure-Host-Baseline

Unblock-File c:/temp/Secure-Host-Baseline

#>

#endregion

#region Chrome Enterprise
try {
    Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\ChromeSetup.msi', '/quiet'
    if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
        Write-Log "Chrome has been installed"
    }
    else {
        write-log "Error locating the Google Chrome executable"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing Chrome: $ErrorMessage"
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
#endregion

#region O365 OPP
try {
  & c:/ODT/ODT_tool.exe /quiet /extract:c:/ODT
  Start-Process -filepath c:/ODT/setup.exe -Wait -ErrorAction SilentlyContinue -ArgumentList '/download', 'c:/ODT/installOfficeProPlus64.xml'
  Start-Process -filepath c:/ODT/setup.exe -Wait -ErrorAction SilentlyContinue -ArgumentList '/configure', 'c:/ODT/installOfficeProPlus64.xml'
  if (Test-Path "C:\Program Files\Microsoft Office") {
      Write-Log "Office has been installed"
  }
  else {
      write-log "Error with Office executable"
  }
}
catch {
  $ErrorMessage = $_.Exception.message
  write-log "Error installing Office: $ErrorMessage"
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

#region Regedit for DoD Teams
# If the customer tenant is on the GCCH or DoD clouds, the customer should
# set the intial endpoint in the registry by adding the CloudType value to
# HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Office\16.0\Teams key in
# the registry. The type for CloudType is DWORD and values are (0 = Unset)
# , 1 = Commercial, 2 = GCC, 3 = GCCH, 4 = DOD). Setting the endpoint with
# the registry keys restricts Teams to connecting to the correct cloud
# endpoint for pre-sign-in connectivity with Teams.
#endregion

