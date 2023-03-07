Write-Host "Installing Docker Desktop 2.2.0.5"

Write-Host "Downloading..."
$exePath = "C:\Docker-Desktop-Installer.exe"
(New-Object Net.WebClient).DownloadFile('https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath install --quiet
Remove-Item $exePath

Write-Host "Docker Desktop installed" -ForegroundColor Green

Write-Host "Creating DockerExchange user..."
net user DockerExchange /add

Write-Host "Finished the installation of Docker for Desktop"