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
choco install python --version 3.7.6 -y --params "/InstallDir:C:\Python37" --force
$env:Path += ";C:\Python37"
choco install python --version 3.8.10 -y --params "/InstallDir:C:\Python38" --force
$env:Path += ";C:\Python38"
choco install python --version 3.9.13 -y --params "/InstallDir:C:\Python39" --force
$env:Path += ";C:\Python39"

choco install git -y --force
$env:Path += ";C:\Program Files\Git\bin"

git config --global core.autocrlf false
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
git config --system core.longpaths true
git --version

choco install make -y --force
$env:Path += ";C:\ProgramData\chocolatey\lib\make\tools\install\bin"

choco install nodejs-lts --version=18.14.1 --force -y
$env:Path += ";C:\Program Files\nodejs"

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
[Environment]::SetEnvironmentVariable("SAM_CLI_DEV", "1" , "Machine")
[Environment]::SetEnvironmentVariable("CARGO_LAMBDA_VERSION", "v0.17.1" , "Machine")
$env:CARGO_LAMBDA_VERSION = "v0.17.1"
[Environment]::SetEnvironmentVariable("TMPDIR", "%TEMP%" , "Machine")
[Environment]::SetEnvironmentVariable("TMP", "%TEMP%", "Machine")
[Environment]::SetEnvironmentVariable("PYTHON_HOME", "C:\\Python37" , "Machine")
[Environment]::SetEnvironmentVariable("PYTHON_SCRIPTS", "C:\\Python37\\Scripts" , "Machine")
[Environment]::SetEnvironmentVariable("PYTHON_EXE", "C:\\Python37\\python.exe" , "Machine")
[Environment]::SetEnvironmentVariable("PYTHON_ARCH", "64" , "Machine")
[Environment]::SetEnvironmentVariable("HOME", "C:\Users\Administrator" , "Machine")
[Environment]::SetEnvironmentVariable("HOMEDRIVE", "C:" , "Machine")
[Environment]::SetEnvironmentVariable("HOMEPATH", "C:\\Users\\Administrator" , "Machine")
[Environment]::SetEnvironmentVariable("NOSE_PARAMETERIZED_NO_WARN",1 , "Machine")
[Environment]::SetEnvironmentVariable("AWS_S3", "AWS_S3_TESTING" , "Machine")
[Environment]::SetEnvironmentVariable("AWS_ECR", "AWS_ECR_TESTING" , "Machine")
[Environment]::SetEnvironmentVariable("RUST_BACKTRACE","1", "Machine")

refreshenv

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
C:\Python38\python -m pip install awscli
C:\Python39\python -m pip install awscli


[Environment]::SetEnvironmentVariable("Path", $Env:Path, "Machine")



