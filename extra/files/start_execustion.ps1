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

function Write-Log
{
    Param
    (
        $text
    )

    "$(get-date -format "yyyy-MM-dd HH:mm:ss"): $($text)" | out-file "c:\sam_cli\log.txt" -Append
}

md C:\sam_cli
Write-Log -text "Starting Docker Desktop..."
&"$env:ProgramFiles\\Docker\\Docker\\Docker Desktop.exe"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


Write-Log -text "Setting experimental mode"
$configPath = "$env:programdata\docker\config\daemon.json"
if (Test-Path $configPath) {
    $daemonConfig = Get-Content $configPath | ConvertFrom-Json
    $daemonConfig | Add-Member NoteProperty "experimental" $true -force
    $daemonConfig | ConvertTo-Json -Depth 20 | Set-Content -Path $configPath
} else {
    New-Item "$env:programdata\docker\config" -ItemType Directory -Force | Out-Null
    Set-Content -Path $configPath -Value '{ "experimental": true }'
}

Write-Log -text "Switching Docker to Linux mode..."
Switch-DockerLinux

while($true) {
    $metadataPath = "C:\metadata.json"
    if(Test-Path $metadataPath) {
        $jsonContent = Get-Content $metadataPath -Raw | ConvertFrom-Json
        Write-Log -text "Metadata content: $jsonContent"
        $env:AWS_ACCESS_KEY_ID = $jsonContent.aws_access_key_id
        $env:AWS_SECRET_ACCESS_KEY = $jsonContent.aws_secret_access_key
        $env:AWS_SESSION_TOKEN = $jsonContent.aws_session_token
        $env:AWS_DEFAULT_REGION = "us-west-2"
        $env:NODE_TYPE = "Executor"
        $env:NODE_ID = $jsonContent.node_id
        Remove-Item $metadataPath -Force
        break
    } else {
        Write-Log "Metadata is not ready yet, waiting ..."
        sleep 5;
    }
}

git config --global core.autocrlf false
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
git config --system core.longpaths true

pip install git-remote-codecommit
cd C:\
if(Test-Path "C:\sam_cli_testing_scripts") {
    Remove-Item "C:\sam_cli_testing_scripts" -Recurse -Force
}
git clone codecommit::us-west-2://sam_cli_testing_scripts
cd C:\sam_cli_testing_scripts
C:\Python37\python -m virtualenv thevenv
thevenv\Scripts\pip install -r requirements.txt

# download aws-sam-cli
if (Test-Path "C:\sam_environment") {
    Remove-Item "C:\sam_environment" -Recurse -Force
}
Write-Log -text "VM ${env:NODE_ID}: creating virtual environment..."
md C:\sam_environment
cd C:\sam_environment
C:\Python37\python -m virtualenv sam_venv
Write-Log -text "VM ${env:NODE_ID}: Cloning aws-sam-cli ..."
git clone https://github.com/moelasmar/aws-sam-cli.git
$env:AWS_DEFAULT_REGION = "us-east-1"
$env:CI = 1
$env:BY_CANARY = 1
$env:SAM_CLI_DEV = 1
$env:AWS_S3 = "AWS_S3_TESTING"
$env:AWS_ECR = "AWS_ECR_TESTING"
cd aws-sam-cli
Write-Log -text "VM ${env:NODE_ID}: installing aws-sam-cli ..."
..\sam_venv\Scripts\pip install -e ".[dev]"

# Wait Docker to start before start testing
$i = 0
$finished = $false
Write-Log -text "Waiting for Docker to start..."
while ($i -lt (30)) {
    $i +=1
    $dockerSvc = (Get-Service com.docker.service -ErrorAction SilentlyContinue)
    if ((Get-Process "Docker Desktop" -ErrorAction SilentlyContinue) -and $dockerSvc -and $dockerSvc.status -eq "Running") {
        $finished = $true
        Write-Log -text "Docker started!"
        break
    }
    Write-Log -text "Retrying in 5 seconds..."
    sleep 5;
}
if (-not $finished) {
    Write-Log -text "Failed to start Docker"
    Throw "Docker has not started"
}
Write-Log -text "Wait for docker deamon to start ..."
$i = 0
$finished = $false
while ($i -lt (30)) {
    $i +=1
    sleep 5;
    docker ps
    if ($LASTEXITCODE -eq 0 ) {
        $finished = $true
        Write-Log -text "Docker started"
        break
    }
}

if (-not $finished) {
    Write-Log -text "Failed to start Docker Deamon"
    Throw "Docker Deamon has not started"
}

Write-Log -text "Login to Docker"
$login_output = (aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws)
Write-Log -text $login_output

Write-Log -text "Start Testing"
cd C:\sam_cli_testing_scripts
thevenv\Scripts\python TestingExecution.py 2>&1 >> C:\\sam_cli\\sep.txt