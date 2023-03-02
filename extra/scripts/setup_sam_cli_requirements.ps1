function Start-ProcessWithOutput {
    param(
        $command,
        [switch]$ignoreExitCode,
        [switch]$ignoreStdOut
    )
    $fileName = $command
    $arguments = $null

    if ($command.startsWith('"')) {
        $idx = $command.indexOf('"', 1)
        $fileName = $command.substring(1, $idx - 1)
        if ($idx -lt ($command.length - 2)) {
            $arguments = $command.substring($idx + 2)
        }
    }
    else {
        $idx = $command.indexOf(' ')
        if ($idx -ne -1) {
            $fileName = $command.substring(0, $idx)
            $arguments = $command.substring($idx + 1)
        }
    }

    # find tool in path
    if (-not (Test-Path $fileName)) {
        foreach ($pathPart in $($env:PATH).Split(';')) {
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.bat")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.cmd")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.exe")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, $fileName)
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $fileName
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.Arguments = $arguments
    $psi.WorkingDirectory = (pwd).Path
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    # Adding event handers for stdout and stderr.
    $outScripBlock = {
        if (![String]::IsNullOrEmpty($EventArgs.Data)) {
            Write-Host "$($EventArgs.Data)"
        }
    }
    $errScripBlock = {
        if (![String]::IsNullOrEmpty($EventArgs.Data)) {
            Write-Host "$($EventArgs.Data)" -ForegroundColor Red
        }
    }

    if ($ignoreStdOut -eq $false) {
        $stdOutEvent = Register-ObjectEvent -InputObject $process -Action $outScripBlock -EventName 'OutputDataReceived'
    }
    $stdErrEvent = Register-ObjectEvent -InputObject $process -Action $errScripBlock -EventName 'ErrorDataReceived'

    try {
        $process.Start() | Out-Null

        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        [Void]$process.WaitForExit()

        # Unregistering events to retrieve process output.
        if ($ignoreStdOut -eq $false) {
            Unregister-Event -SourceIdentifier $stdOutEvent.Name
        }
        Unregister-Event -SourceIdentifier $stdErrEvent.Name

        if ($ignoreExitCode -eq $false -and $process.ExitCode -ne 0) {
            exit $process.ExitCode
        }
    }
    catch {
        Write-Host "Error running '$($psi.FileName) $($psi.Arguments)' command: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

### runtimes

############## Python

function DisplayDiskInfo() {
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName,
    @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
    @{ Name = "Size (GB)" ; Expression = { "{0:N1}" -f ( $_.Size / 1gb) } },
    @{ Name = "FreeSpace (GB)" ; Expression = { "{0:N1}" -f ( $_.Freespace / 1gb ) } },
    @{ Name = "PercentFree" ; Expression = { "{0:P1}" -f ( $_.FreeSpace / $_.Size ) } } |
    Format-Table -AutoSize | Out-String
}

function GetProductVersion ($partialName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
    | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
    | Where-Object { $_.DisplayName -and $_.DisplayName.contains($partialName) } `
    | Sort-Object -Property DisplayName `
    | Select-Object -Property DisplayName, DisplayVersion `
    | Format-Table -AutoSize | Out-String
}

function Start-ProcessWithOutput {
    param(
        $command,
        [switch]$ignoreExitCode,
        [switch]$ignoreStdOut
    )
    $fileName = $command
    $arguments = $null

    if ($command.startsWith('"')) {
        $idx = $command.indexOf('"', 1)
        $fileName = $command.substring(1, $idx - 1)
        if ($idx -lt ($command.length - 2)) {
            $arguments = $command.substring($idx + 2)
        }
    }
    else {
        $idx = $command.indexOf(' ')
        if ($idx -ne -1) {
            $fileName = $command.substring(0, $idx)
            $arguments = $command.substring($idx + 1)
        }
    }

    # find tool in path
    if (-not (Test-Path $fileName)) {
        foreach ($pathPart in $($env:PATH).Split(';')) {
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.bat")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.cmd")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.exe")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, $fileName)
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $fileName
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.Arguments = $arguments
    $psi.WorkingDirectory = (pwd).Path
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    # Adding event handers for stdout and stderr.
    $outScripBlock = {
        if (![String]::IsNullOrEmpty($EventArgs.Data)) {
            Write-Host "$($EventArgs.Data)"
        }
    }
    $errScripBlock = {
        if (![String]::IsNullOrEmpty($EventArgs.Data)) {
            Write-Host "$($EventArgs.Data)" -ForegroundColor Red
        }
    }

    if ($ignoreStdOut -eq $false) {
        $stdOutEvent = Register-ObjectEvent -InputObject $process -Action $outScripBlock -EventName 'OutputDataReceived'
    }
    $stdErrEvent = Register-ObjectEvent -InputObject $process -Action $errScripBlock -EventName 'ErrorDataReceived'

    try {
        $process.Start() | Out-Null

        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        [Void]$process.WaitForExit()

        # Unregistering events to retrieve process output.
        if ($ignoreStdOut -eq $false) {
            Unregister-Event -SourceIdentifier $stdOutEvent.Name
        }
        Unregister-Event -SourceIdentifier $stdErrEvent.Name

        if ($ignoreExitCode -eq $false -and $process.ExitCode -ne 0) {
            exit $process.ExitCode
        }
    }
    catch {
        Write-Host "Error running '$($psi.FileName) $($psi.Arguments)' command: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

$pipVersion = "22.3.1"

function UpdatePythonPath($pythonPath) {
    $env:path = ($env:path -split ';' | Where-Object { -not $_.contains('\Python') }) -join ';'
    $env:path = "$pythonPath;$env:path"
}

function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64userItems = @(Get-ChildItem "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + $x64userItems + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
    | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
    | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
    | Select UninstallString).UninstallString
}

function UninstallPython($pythonName) {
    $uninstallCommand = (GetUninstallString $pythonName)
    if ($uninstallCommand) {
        Write-Host "Uninstalling $pythonName..." -NoNewline
        if ($uninstallCommand.contains('/modify')) {
            $uninstallCommand = $uninstallCommand.replace('/modify', '')
            Start-ProcessWithOutput "$uninstallCommand /quiet /uninstall"
        }
        elseif ($uninstallCommand.contains('/uninstall')) {
            Start-ProcessWithOutput "$uninstallCommand /quiet"
        }
        else {
            $uninstallCommand = $uninstallCommand.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
            Start-ProcessWithOutput "msiexec.exe $uninstallCommand /quiet"
        }
        Write-Host "done"
    }
}

function UpdatePip($pythonPath) {
    Write-Host "Installing virtualenv for $pythonPath..." -ForegroundColor Cyan
    UpdatePythonPath "$pythonPath;$pythonPath\scripts"
    Start-ProcessWithOutput "python -m pip install --upgrade pip==$pipVersion" -IgnoreExitCode
    Start-ProcessWithOutput "pip --version" -IgnoreExitCode
    Start-ProcessWithOutput "pip install virtualenv" -IgnoreExitCode
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading get-pip.py v2.6..." -ForegroundColor Cyan
$pipPath26 = "$env:TEMP\get-pip-26.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/pip/2.6/get-pip.py', $pipPath26)

Write-Host "Downloading get-pip.py v3.3..." -ForegroundColor Cyan
$pipPath33 = "$env:TEMP\get-pip-33.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/pip/3.3/get-pip.py', $pipPath33)

Write-Host "Downloading get-pip.py v3.4..." -ForegroundColor Cyan
$pipPath34 = "$env:TEMP\get-pip-34.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/pip/3.4/get-pip.py', $pipPath34)

function InstallPythonMSI($version, $platform, $targetPath) {
    $urlPlatform = ""
    if ($platform -eq 'x64') {
        $urlPlatform = ".amd64"
    }

    Write-Host "Installing Python $version $platform to $($targetPath)..." -ForegroundColor Cyan

    $downloadUrl = "https://www.python.org/ftp/python/$version/python-$version$urlPlatform.msi"
    Write-Host "Downloading $($downloadUrl)..."
    $msiPath = "$env:TEMP\python-$version.msi"
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $msiPath)

    Write-Host "Installing..."
    cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR="$targetPath"
    Remove-Item $msiPath

    Start-ProcessWithOutput "$targetPath\python.exe --version"

    Write-Host "Installed Python $version" -ForegroundColor Green
}

function InstallPythonEXE($version, $platform, $targetPath) {
    $urlPlatform = ""
    if ($platform -eq 'x64') {
        $urlPlatform = "-amd64"
    }

    Write-Host "Installing Python $version $platform to $($targetPath)..." -ForegroundColor Cyan

    $downloadUrl = "https://www.python.org/ftp/python/$version/python-$version$urlPlatform.exe"
    Write-Host "Downloading $($downloadUrl)..."
    $exePath = "$env:TEMP\python-$version.exe"
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $exePath)

    Write-Host "Installing..."
    cmd /c start /wait $exePath /quiet TargetDir="$targetPath" Shortcuts=0 Include_launcher=1 InstallLauncherAllUsers=1 Include_debug=1
    Remove-Item $exePath

    Start-ProcessWithOutput "$targetPath\python.exe --version"

    Write-Host "Installed Python $version" -ForegroundColor Green
}

# Python 3.7.9 x64
$python37_x64 = (GetUninstallString 'Python 3.7.9 (64-bit)')
if ($python37_x64) {
    Write-Host 'Python 3.7.9 x64 already installed'
}
else {

    UninstallPython "Python 3.7.0 (64-bit)"
    UninstallPython "Python 3.7.5 (64-bit)"
    UninstallPython "Python 3.7.7 (64-bit)"
    UninstallPython "Python 3.7.8 (64-bit)"

    InstallPythonEXE "3.7.9" "x64" "$env:SystemDrive\Python37-x64"
}


# Python 3.7.9
$python37 = (GetUninstallString 'Python 3.7.9 (32-bit)')
if ($python37) {
    Write-Host 'Python 3.7.9 already installed'
}
else {
    UninstallPython "Python 3.7.0 (32-bit)"
    UninstallPython "Python 3.7.5 (32-bit)"
    UninstallPython "Python 3.7.7 (32-bit)"
    UninstallPython "Python 3.7.8 (32-bit)"

    InstallPythonEXE "3.7.9" "x86" "$env:SystemDrive\Python37"
}

UpdatePip "$env:SystemDrive\Python37"
UpdatePip "$env:SystemDrive\Python37-x64"

# Python 3.8.10 x64
$python38_x64 = (GetUninstallString 'Python 3.8.10 (64-bit)')
if ($python38_x64) {
    Write-Host 'Python 3.8.10 x64 already installed'
}
else {
    InstallPythonEXE "3.8.10" "x64" "$env:SystemDrive\Python38-x64"
}

# Python 3.8.10
$python38 = (GetUninstallString 'Python 3.8.10 (32-bit)')
if ($python38) {
    Write-Host 'Python 3.8.10 already installed'
}
else {
    InstallPythonEXE "3.8.10" "x86" "$env:SystemDrive\Python38"
}

UpdatePip "$env:SystemDrive\Python38"
UpdatePip "$env:SystemDrive\Python38-x64"

# Python 3.9.13 x64
$python39_x64 = (GetUninstallString 'Python 3.9.13 (64-bit)')
if ($python39_x64) {
    Write-Host 'Python 3.9.13 x64 already installed'
    UninstallPython "Python 3.9.13 (64-bit)"
}

InstallPythonEXE "3.9.13" "x64" "$env:SystemDrive\Python39-x64"

# Python 3.9.13
$python39 = (GetUninstallString 'Python 3.9.13 (32-bit)')
if ($python39) {
    Write-Host 'Python 3.9.13 already installed'
    UninstallPython "Python 3.9.13 (32-bit)"
}

InstallPythonEXE "3.9.13" "x86" "$env:SystemDrive\Python39"

UpdatePip "$env:SystemDrive\Python39"
UpdatePip "$env:SystemDrive\Python39-x64"

# Python 3.10.10
$python310 = (GetUninstallString 'Python 3.10.10 (32-bit)')
if ($python310) {
    Write-Host 'Python 3.10.10 already installed'
}
else {
    InstallPythonEXE "3.10.10" "x86" "$env:SystemDrive\Python310"
}

# Python 3.10.10 x64
$python310_x64 = (GetUninstallString 'Python 3.10.10 (64-bit)')
if ($python310_x64) {
    Write-Host 'Python 3.10.10 x64 already installed'
}
else {
    InstallPythonEXE "3.10.10" "x64" "$env:SystemDrive\Python310-x64"
}

UpdatePip "$env:SystemDrive\Python310"
UpdatePip "$env:SystemDrive\Python310-x64"


# restore .py file mapping
# https://github.com/appveyor/ci/issues/575
cmd /c ftype Python.File="C:\Windows\py.exe" "`"%1`"" %*

# check default python
Write-Host "Default Python installed:" -ForegroundColor Cyan
$r = (cmd /c python.exe --version 2>&1)
$r.Exception

# py.exe
Write-Host "Py.exe installed:" -ForegroundColor Cyan
$r = (py.exe --version)
$r

function CheckPython($path) {
    if (Test-Path "$path\python.exe") {
        Start-ProcessWithOutput "$path\python.exe --version"
    }
    else {
        throw "python.exe is missing in $path"
    }

    if (Test-Path "$path\Scripts\pip.exe") {
        Start-ProcessWithOutput "$path\Scripts\pip.exe --version"
        Start-ProcessWithOutput "$path\Scripts\virtualenv.exe --version"
    }
    else {
        Write-Host "pip.exe is missing in $path" -ForegroundColor Red
    }
}

CheckPython 'C:\Python37'
CheckPython 'C:\Python37-x64'
CheckPython 'C:\Python38'
CheckPython 'C:\Python38-x64'
CheckPython 'C:\Python39'
CheckPython 'C:\Python39-x64'
CheckPython 'C:\Python310'
CheckPython 'C:\Python310-x64'

##############

choco install git -y --force
$env:Path += ";C:\Program Files\Git\bin"

git config --global core.autocrlf false
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
git config --system core.longpaths true
git --version

choco install make -y --force
$env:Path += ";C:\ProgramData\chocolatey\lib\make\tools\install\bin"

choco install nodejs-lts --version=18.14.1 --force -y

# Install Java 11
choco install OpenJDK --version 11.0.2.01 --force -y
$env:Path += ";C:\Program Files\OpenJDK\jdk-11.0.2\bin"
[Environment]::SetEnvironmentVariable("JAVA_11_HOME", "C:\Program Files\OpenJDK\jdk-11.0.2" , "Machine")


# Install Java 8
choco install jdk8 --force -y
$env:Path += ";C:\Program Files\Java\jdk1.8.0_211\bin"
[Environment]::SetEnvironmentVariable("JAVA_8_HOME", "C:\Program Files\Java\jdk1.8.0_211" , "Machine")


# Install Gradle 4.4.1
choco install gradle --version 4.4.1 --force -y
$env:Path += ";C:\ProgramData\chocolatey\lib\gradle\tools\gradle-4.4.1\bin"

# Install Maven 3.9.0
choco install maven --version 3.9.0 --force -y
$env:Path += ";C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.0\bin"


choco install dotnet --version=6.0.10 --force -y
choco install dotnet-6.0-sdk --version=6.0.100 --force -y
choco install dotnetcore-sdk --version=3.1.425 --force -y
$env:path += ";C:\Program Files\dotnet"
$env:path += ";C:\Users\Administrator\.dotnet\tools"

# Install Go 1.x
choco install golang --version 1.17.5 --force -y
$env:Path += ";C:\Program Files\Go\bin"


# Install Ruby 2.7
choco install ruby --version=2.7.7.1 --force -y
$env:Path += ";C:\tools\ruby27\bin"
gem install bundler



# install terraform
choco install terraform --force -y
$env:Path += ";C:\ProgramData\chocolatey\lib\terraform\tools"


# install visual studio 2022

choco install visualstudio2019buildtools --force -y
choco install visualstudio2019-workload-vctools --force -y
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin"




# set some env
$env:CARGO_LAMBDA_VERSION = "v0.17.1"

# install Rust
(New-Object Net.WebClient).DownloadFile("https://win.rustup.rs/", "C:\rustup-init.exe")
C:\rustup-init.exe -y --default-host x86_64-pc-windows-msvc --default-toolchain stable
$env:Path += ";C:\Users\Administrator\.cargo\bin"

rustup toolchain install stable --profile minimal --no-self-update
rustup default stable
rustup target add x86_64-unknown-linux-gnu --toolchain stable
rustup target add aarch64-unknown-linux-gnu --toolchain stable
choco install zig --force -y

$env:Path += ";C:\ProgramData\chocolatey\lib\zig\tools\zig-windows-x86_64-0.10.1"
(New-Object Net.WebClient).DownloadFile("https://github.com/cargo-lambda/cargo-lambda/releases/download/$env:CARGO_LAMBDA_VERSION/cargo-lambda-$env:CARGO_LAMBDA_VERSION.windows-x64.zip", "C:\Users\Administrator\cargo-lambda.zip")
Expand-Archive -DestinationPath C:\Users\Administrator\.cargo\bin C:\Users\Administrator\cargo-lambda.zip

Remove-Item "C:\Users\Administrator\cargo-lambda.zip" -Force
Remove-Item "C:\rustup-init.exe" -Force

rustc -V
cargo -V
cargo lambda -V

[Environment]::SetEnvironmentVariable("Path",$env:Path , "Machine")


C:\Python37\python -m pip install --upgrade setuptools wheel virtualenv
C:\Python38\python -m pip install --upgrade setuptools wheel virtualenv
C:\Python39\python -m pip install --upgrade setuptools wheel virtualenv
C:\Python37\python -m pip install awscli
C:\Python37\python -m pip install awscli
C:\Python37\python -m pip install awscli

### Cygwin

Write-Host "Installing Cygwin x64..." -ForegroundColor Cyan

if(Test-Path C:\cygwin) {
    Write-Host "Deleting existing installation..."
    Remove-Item C:\cygwin -Recurse -Force
}


# download installer
New-Item -Path C:\cygwin -ItemType Directory -Force
$exePath = "C:\cygwin\setup-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://cygwin.com/setup-x86_64.exe', $exePath)
dir C:\cygwin

# install cygwin
Start-ProcessWithOutput "$exePath -qnNdO -R C:/cygwin -s http://cygwin.mirror.constant.com -l C:/cygwin/var/cache/setup -P mingw64-i686-gcc-g++ -P mingw64-x86_64-gcc-g++ -P gcc-g++ -P autoconf -P automake -P bison -P libtool -P make -P python2 -P python -P python38 -P gettext-devel -P intltool -P libiconv -P pkg-config -P wget -P curl"
C:\Cygwin\bin\bash -lc true

cmd /c "C:\cygwin\bin\cygcheck -c | C:\cygwin\bin\grep cygwin"
cmd /c "C:\cygwin\bin\gcc --version"

Write-Host "Installed Cygwin x64" -ForegroundColor Green

if(Test-Path C:\cygwin64) {
    Write-Host "Deleting C:\cygwin64..."
    Remove-Item C:\cygwin64 -Recurse -Force
}

New-Item -ItemType SymbolicLink -Path "C:\cygwin64" -Target "C:\cygwin" -Force | Out-Null
dir C:\cygwin64

# compact folders
Write-Host "Compacting C:\cygwin..." -NoNewline
Start-ProcessWithOutput "compact /c /i /q /s:C:\cygwin" -IgnoreStdOut
Write-Host "OK" -ForegroundColor Green


$Env:Path += ";C:\cygwin\bin"

[Environment]::SetEnvironmentVariable("Path", $Env:Path, "Machine")



