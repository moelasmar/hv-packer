function Switch-DockerLinux
{
    Remove-SmbShare -Name C -ErrorAction SilentlyContinue -Force
    $deUsername = 'DockerExchange'
    $dePsw = "ABC" + [guid]::NewGuid().ToString() + "!"
    $secDePsw = ConvertTo-SecureString $dePsw -AsPlainText -Force
    Get-LocalUser -Name $deUsername | Set-LocalUser -Password $secDePsw
    & $env:ProgramFiles\Docker\Docker\DockerCli.exe -Start --testftw!928374kasljf039 >$null 2>&1
    & $env:ProgramFiles\Docker\Docker\DockerCli.exe -Mount=C -Username="$env:computername\$deUsername" -Password="$dePsw" --testftw!928374kasljf039 >$null 2>&1
    Disable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Direction Inbound
}

Write-Host "Completing the configuration of Docker for Desktop..."

$ErrorActionPreference = "Stop"

# start Docker
& "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

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

if (-not $finished) {
    Throw "Docker has not started"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


Write-Host "Setting experimental mode"
$configPath = "$env:programdata\docker\config\daemon.json"
if (Test-Path $configPath) {
  $daemonConfig = Get-Content $configPath | ConvertFrom-Json
  $daemonConfig | Add-Member NoteProperty "experimental" $true -force
  $daemonConfig | ConvertTo-Json -Depth 20 | Set-Content -Path $configPath
} else {
  New-Item "$env:programdata\docker\config" -ItemType Directory -Force | Out-Null
  Set-Content -Path $configPath -Value '{ "experimental": true }'
}

Write-Host "Switching Docker to Linux mode..."
Switch-DockerLinux
Start-Sleep -s 20
docker version

docker pull busybox
docker run --rm -v 'C:\:/user-profile' busybox ls /user-profile

docker pull alpine
docker run --rm alpine echo hello_world

Write-Host "Disable SMB share for disk C:"
Remove-SmbShare -Name C -ErrorAction SilentlyContinue -Force

# enable Docker auto run
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Docker Desktop" `
    -Value 2

# enable Docker auto run
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "Docker Desktop" `
    -Value "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

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

Write-Host "Docker CE installed and configured"