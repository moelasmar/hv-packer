Write-Host "Checking if Hyper-V is enabled."
$hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online
# Check if Hyper-V is enabled
if($hyperv.State -eq "Enabled") {
    Write-Host "Hyper-V is enabled."
}else {
    Write-Host "Hyper-V is disabled."
    Write-Host "Enabling Hyper-V feature now"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All /NoRestart
    Start-Sleep 30
    Write-Host "Hyper-V is enabled now reboot the system and re-run the script to continue the installation."
}
exit 0