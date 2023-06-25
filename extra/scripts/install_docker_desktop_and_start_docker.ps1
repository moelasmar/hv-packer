Function GenerateFolder($path) {
    $global:foldPath = $null
    foreach($foldername in $path.split("\")) {
        $global:foldPath += ($foldername+"\")
        if (!(Test-Path $global:foldPath)){
            New-Item -ItemType Directory -Path $global:foldPath
            # Write-Host "$global:foldPath Folder Created Successfully"
        }
    }
}


GenerateFolder "~/AppData/Roaming/Docker/"

if (-not (Test-Path DockerInstaller.exe))
{
    Write-Host "Installing Docker."

    Write-Host "Downloading the Docker exe"
    Invoke-WebRequest -Uri https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe -OutFile DockerInstaller.exe -UseBasicParsing
    Write-Host "Download Completed"

    start-process .\DockerInstaller.exe "install --quiet" -Wait -NoNewWindow
    cd "C:\Program Files\Docker\Docker\"
    Write-Host "Installing Docker..."
    $ProgressPreference = 'SilentlyContinue'
    & '.\Docker Desktop.exe'
    $env:Path += ";C:\Program Files\Docker\Docker\Resources\bin"
    $env:Path += ";C:\Program Files\Docker\Docker\Resources"
    Write-Host "Docker Installed successfully"
    Write-Host "You must reboot the sytem to continue. After reboot re-run the script."
}else
{
    Write-Host "Starting docker..."
    $ErrorActionPreference = 'SilentlyContinue';
    do
    {
        $var1 = docker ps 2> $null
    } while (-Not$var1)
    $ErrorActionPreference = 'Stop';
    $env:Path += ";C:\Program Files\Docker\Docker\Resources\bin"
    $env:Path += ";C:\Program Files\Docker\Docker\Resources"
    Write-Host "Docker Started successfully"
}
exit 0