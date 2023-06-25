$wsl = Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online

if($wsl.State -eq "Enabled") {

    Write-Host "WSL is enabled."

    if ([Environment]::Is64BitOperatingSystem)
    {
        Write-Host "System is x64. Need to update Linux kernel..."
        if (-not (Test-Path wsl_update_x64.msi))
        {
            Write-Host "Downloading Linux kernel update package..."
            Invoke-WebRequest -OutFile wsl_update_x64.msi https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
        }
        Write-Host "Installing Linux kernel update package..."
        Start-Process msiexec.exe -Wait -ArgumentList '/I wsl_update_x64.msi /quiet'
        Write-Host "Linux kernel update package installed."
    }

    Write-Host "WSL is enabled. Setting it to WSL2"
    wsl --set-default-version 2
}
else {
    Write-Host "WSL is disabled."
    Write-Host "Enabling WSL2 feature now"

    & cmd /c 'dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart'
    & cmd /c 'dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart'
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform /NoRestart
    Start-Sleep 30
    Write-Host "WSL is enabled now reboot the system and re-run the script to continue the installation."
}

exit 0