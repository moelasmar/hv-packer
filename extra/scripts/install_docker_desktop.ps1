Write-Host "Downloading The Docker for Desktop ..."

Start-BitsTransfer -Source "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -Destination "C:\Docker-Desktop-Installer.exe"

Write-Host "Installing The Docker for Desktop ..."

Start-Process "C:\Docker-Desktop-Installer.exe" -Wait -NoNewWindow "install --quiet --accept-license --no-windows-containers --backend=wsl-2 --installation-dir=C:\Docker"

Write-Host "Update WSL ..."

wsl --update