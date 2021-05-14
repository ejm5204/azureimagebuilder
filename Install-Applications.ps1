# Software install Script
#
# Applications to install:
#
# DoD Teams
# https://dod.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true
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

#region DoD_Teams
try {
    #Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'c:\temp\ChromeSetup.exe', '/quiet'
    msiexec /i 'c:\temp\Teams_windows_x64.exe' /quiet
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
