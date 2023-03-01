Write-Host "Completing the configuration of Docker for Desktop..."

$ErrorActionPreference = "Stop"

# start Docker
& "C:\Docker\Docker Desktop.exe"

# wait while  Docker Desktop is started

$i = 0
$finished = $false

Write-Host "Waiting for Docker to start..."

while ($i -lt (300)) {
  $i +=1

  $dockerSvc = (Get-Service com.docker.service -ErrorAction SilentlyContinue)
  if ((Get-Process 'Docker Desktop' -ErrorAction SilentlyContinue) -and $dockerSvc -and $dockerSvc.status -eq 'Running') {
    $finished = $true
    Write-Host "Docker started!"
    break
  }
  Write-Host "Retrying in 5 seconds..."
  sleep 5;
}

sleep 20;

if (-not $finished) {
    Throw "Docker has not started"
}


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-SmbShare -Name C -ErrorAction SilentlyContinue -Force
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Docker Desktop" -Value "C:\Docker\Docker Desktop.exe"
Write-Host "Disabling automatic updates and usage statistics"
$settingsPath = "$env:appdata\Docker\settings.json"
if (Test-Path $settingsPath) {
	$dockerSettings = Get-Content $settingsPath | ConvertFrom-Json
	$dockerSettings | Add-Member NoteProperty "checkForUpdates" $false -force
	$dockerSettings | Add-Member NoteProperty "analyticsEnabled" $false -force
	$dockerSettings | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath
} else {
	Write-Warning "$settingsPath was not found!"
}