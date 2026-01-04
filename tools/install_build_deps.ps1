$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

# read version number from .vsversion
$vsVersion = Get-Content ".vsversion" | ForEach-Object { $_.Trim() }
$componentId = "Microsoft.VisualStudio.Component.VC.$vsVersion.x86.x64"
write-host $componentId
write-host $componentId
write-host $componentId
write-host $componentId
write-host $componentId


$script:didFailToFetchVersions = $false
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function get-unicodechar($codepoint) {
    return [char]::convertfromutf32($codepoint)
}

function get-versioninfo {
    param (
        [string]$name,
        [scriptblock]$getInstalled,
        [scriptblock]$getLatest = $null,
        [string]$minVersion = "0.0.0"
    )

    $installed = & $getInstalled
    $latest = if ($getLatest) { & $getLatest } else { $minVersion }
    $isOutdated = $true

    $latest = $latest -replace ('-', '')

    if ([version]::TryParse($installed, [ref]$null) -and [version]::TryParse($latest, [ref]$null)) {
        $isOutdated = [version]$installed -lt [version]$latest
    } elseif ($installed -match '^\d{8}$' -and $latest -match '^\d{8}$') {
        $isOutdated = [int]$installed -lt [int]$latest
    } elseif ($latest -eq "0.0.0" -or $latest -eq "required") {
        $isOutdated = $true
    } else {
        $isOutdated = $installed -ne $latest
    }

    return [pscustomobject]@{
        Name        = $name
        Installed   = $installed
        Latest      = $latest
        IsOutdated  = $isOutdated
    }
}

function refresh-versioninfo {
    return @(
        get-versioninfo "cmake" { get-cmakeversion } { get-latestcmakeversion }
        get-versioninfo "ninja" { get-ninjaversion } { get-latestninjaversion }
        get-versioninfo "clang" { get-clangversion } { get-latestclangversion }
        get-versioninfo "git"   { get-gitversion }   { get-latestgitversion }
        get-versioninfo "msys2" { get-msys2version } { get-latestmsys2version }
        get-msvcstatus
    )
}

function add-to-path {
    param (
        [string]$path
    )

    if ((Test-Path $path) -and -not ($env:Path -split ";" | Where-Object { $_ -eq $path })) {
        $env:Path += ";$path"
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
        write-host "$(get-unicodechar 0x1f4a1) added $path to system PATH."
    } elseif (-not (Test-Path $path)) {
        write-host "$(get-unicodechar 0x26a0) warning: path '$path' does not exist!" -ForegroundColor Yellow
    } else {
        write-host "$(get-unicodechar 0x1f4a1) path already exists in PATH: $path"
    }
}

function test-isadmin {
    $identity = [system.security.principal.windowsidentity]::getcurrent()
    $principal = new-object system.security.principal.windowsprincipal($identity)
    return $principal.isinrole([system.security.principal.windowsbuiltinrole]::administrator)
}

function get-cmakeversion {
    try {
        $version = cmake --version 2>$null | select-string -pattern "cmake version (\d+\.\d+\.\d+)" | foreach-object { $_.matches.groups[1].value }
        if (-not [string]::isnullorempty($version)) {
            write-host "$(get-unicodechar 0x1f50d) cmake is installed: version $version"
            return $version
        }
    } catch {
        write-host "$(get-unicodechar 0x26a0) cmake is not installed or not found in path." -foregroundcolor yellow
    }
    return "0.0.0"
}

function get-latestcmakeversion {
    try {
        $response = invoke-restmethod -uri "https://api.github.com/repos/Kitware/CMake/releases/latest" -usebasicparsing
        $version = $response.tag_name -replace "^v", ""  # remove 'v' prefix if present
        write-host "$(get-unicodechar 0x1f50d) Found latest CMake version $version"
        return $version
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to fetch the latest CMake version from GitHub." -foregroundcolor yellow
        $didFailToFetchVersions = $true;
        return "0.0.0"
    }
}

function get-ninjaversion {
    try {
        $version = ninja --version 2>$null
        if (-not [string]::isnullorempty($version)) {
            write-host "$(get-unicodechar 0x1f50d) Finja is installed: version $version"
            return $version
        }
    } catch {
        write-host "$(get-unicodechar 0x26a0) Ninja is not installed or not found in path." -foregroundcolor yellow
    }
    return "0.0.0"
}

function get-latestninjaversion {
    try {
        $response = invoke-restmethod -uri "https://api.github.com/repos/ninja-build/ninja/releases/latest" -usebasicparsing
        $version = $response.tag_name -replace "^v", ""  # remove 'v' prefix if present
        write-host "$(get-unicodechar 0x1f50d) Found latest Ninja version $version"
        return $version
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to fetch the latest Ninja version from GitHub." -foregroundcolor yellow
        $didFailToFetchVersions = $true;
        return "0.0.0"
    }
}

function get-clangversion($tool) {
    try {
        $version = clang-format --version 2>$null | select-string -pattern "clang-format version (\d+\.\d+\.\d+)" | foreach-object { $_.matches.groups[1].value }
        if ($version) {
            write-host "$(get-unicodechar 0x1f50d) clang is installed: version $version"
            return $version
        }
    } catch {
        write-host "$(get-unicodechar 0x26a0) clang is not installed or not found in path." -foregroundcolor yellow
    }
    return "0.0.0"
}

function get-latestclangversion {
    try {
        $releases = invoke-restmethod -uri "https://api.github.com/repos/llvm/llvm-project/releases" -usebasicparsing
        foreach ($release in $releases) {
            if ($release.assets | where-object { $_.name -match "llvm-.*-win64.exe" }) {
                $version = $release.tag_name -replace "^llvmorg-", ""
                write-host "$(get-unicodechar 0x1f50d) Found latest LLVM version $version"
                return $version
            }
        }
    } catch {
        write-host "$(get-unicodechar 0x26a0) failed to fetch the latest LLVM version from GitHub." -foregroundcolor yellow
        $didFailToFetchVersions = $true;
        return "0.0.0"
    }
}

function get-latestmsys2version {
    try {
        $headers = @{ "User-Agent" = "installer-script" }
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/msys2/msys2-installer/releases" -Headers $headers -UseBasicParsing

        foreach ($release in $releases) {
            if (-not $release.prerelease -and -not $release.draft -and $release.tag_name -notmatch "nightly") {
                $version = $release.tag_name
                $versionNormalized = $version -replace('-', '')
                write-host "$(get-unicodechar 0x1f50d) Found latest MSYS2 version $versionNormalized"
                return $version
            }
        }

        write-host "$(get-unicodechar 0x26a0) no stable MSYS2 releases found." -ForegroundColor Yellow
    } catch {
        write-host "$(get-unicodechar 0x26a0) failed to fetch MSYS2 releases from GitHub." -ForegroundColor Yellow
    }

    $didFailToFetchVersions = $true;
    return "0.0.0"
}

function get-gitversion {
    try {
        $version = git --version 2>$null | select-string -pattern "git version (\d+\.\d+\.\d+).*" | foreach-object { $_.matches.groups[1].value }
        if ($version) {
            write-host "$(get-unicodechar 0x1f50d) Git is installed: version $version"
            return $version
        }
    } catch {
        write-host "$(get-unicodechar 0x26a0) Git is not installed or not found in path." -foregroundcolor yellow
    }
    return "0.0.0"
}

function is-msvc-component-installed {
#    if (-not (Test-Path $vswhere)) {
#        write-host "$(get-unicodechar 0x26a0) vswhere.exe not found!" -ForegroundColor Yellow
#        return $false
#    }
#
## Look for the component in installed product instances
#    $output = & $vswhere -format json -products * -requires $componentId 2>$null
#
#    return ($output -ne $null -and $output.Trim().Length -gt 0)
}

function get-msvcstatus {
    $vsInstallPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community"

    $toolsetDir = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC"
    Get-ChildItem -Directory $toolsetDir | Select-Object Name
    $actualVersions = Get-ChildItem $toolsetDir | Select-Object -ExpandProperty Name
    if ($actualVersions -contains $vsversion) {
        write-host "$(get-unicodechar 0x1f50d) MSVC $vsversion is present."
        $isInstalled = $true;
    } else {
        write-host "$(get-unicodechar 0x26a0) MSVC $vsversion is missing." -foregroundcolor yellow
        $isInstalled = $false;
    }

    return [pscustomobject]@{
        Name       = "msvc"
        Installed  = if ($isInstalled) { "installed" } else { "missing" }
        Latest     = "required"
        IsOutdated = -not $isInstalled
    }
}

function get-msys2version {
    $componentsPath = "C:\msys64\components.xml"
    if (-not (Test-Path $componentsPath)) {
        write-host "$(get-unicodechar 0x26a0) MSYS2 components.xml not found. MSYS2 may not be installed." -ForegroundColor Yellow
        return "0.0.0"
    }

    try {
        [xml]$xml = Get-Content $componentsPath
        $versionNode = $xml.Packages.Package | Where-Object { $_.Name -eq "com.msys2.root" }

        if ($versionNode.Version) {
            write-host "$(get-unicodechar 0x1f50d) MSYS2 is installed: version $($versionNode.Version)"
            return $versionNode.Version
        } else {
            write-host "$(get-unicodechar 0x26a0) MSYS2 version not found in XML." -ForegroundColor Yellow
        }
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to parse MSYS2 components.xml" -ForegroundColor Yellow
    }

    return "0.0.0"
}

function install-gitbash {
    write-host "$(get-unicodechar 0x1f680) Downloading Git..."
    $gitInstallerUrl = get-latestgitinstaller
    $gitInstallerPath = "$env:temp\gitinstaller.exe"

    try {
        invoke-webrequest -uri $gitInstallerUrl -outfile $gitInstallerPath
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to download Git." -foregroundcolor red
        return
    }

    write-host "$(get-unicodechar 0x1f4e6) Running Git installer..."
    write-host "$(get-unicodechar 0x1f4e6) If this hangs, press Enter"
    $exitCode = (Start-Process -FilePath $gitInstallerPath -ArgumentList "/VERYSILENT /NORESTART" -Wait -PassThru).ExitCode

    if ($exitCode -ne 0) {
        Write-Host "$(get-unicodechar 0x26A0) Git installer exited with code $exitCode" -ForegroundColor Yellow
    } else {
        Write-Host "$(get-unicodechar 0x2705) Git installed successfully!"
    }
}

function get-latestgitversion {
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -UseBasicParsing
        $version = $response.tag_name -replace "^v", "" -replace "\.windows\.\d+$", ""
        write-host "$(get-unicodechar 0x1f50d) Found latest Git version $version"
        return $version
    } catch {
        Write-Host "$(get-unicodechar 0x26A0) Failed to fetch latest Git version from GitHub." -ForegroundColor Yellow
        return "0.0.0"
    }
}

function get-latestgitinstaller {
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -UseBasicParsing
        foreach ($asset in $response.assets) {
            if ($asset.name -match "Git-.*-64-bit\.exe$") {
                return $asset.browser_download_url
            }
        }
        throw "Could not find matching 64-bit installer"
    } catch {
        Write-Host "$(get-unicodechar 0x26A0) Failed to fetch latest Git installer." -ForegroundColor Yellow
        return $null
    }
}

function get-latestcmakeinstaller {
    try {
        $headers = @{ "User-Agent" = "installer-script" }
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/Kitware/CMake/releases/latest" -Headers $headers -UseBasicParsing

        foreach ($asset in $release.assets) {
            if ($asset.name -like "*-windows-x86_64.msi") {
                return $asset.browser_download_url
            }
        }

        write-host "$(get-unicodechar 0x26a0) No suitable CMake MSI installer found in latest release." -ForegroundColor Yellow
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to fetch latest CMake release from GitHub." -ForegroundColor Yellow
    }

    return $null
}

function install-cmake {
    write-host "$(get-unicodechar 0x1f680) Downloading latest cmake..."

    $cmakeInstallerUrl = get-latestcmakeinstaller
    $cmakeInstallerPath = "$env:temp\cmake-installer.msi"
    
    try {
        Invoke-WebRequest -Uri $cmakeInstallerUrl -OutFile "$cmakeInstallerPath" -Headers @{ "User-Agent" = "installer-script" }
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to download CMake." -foregroundcolor red
    }

    write-host "$(get-unicodechar 0x1f4e6) Running clang installer..."
    write-host "$(get-unicodechar 0x1f4e6) If this hangs, press Enter"
    $exitCode = (Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i `"$cmakeInstallerPath`" /quiet /norestart" `
        -Wait -PassThru).ExitCode

    if ($exitCode -ne 0) {
        Write-Host "$(get-unicodechar 0x26A0) CMake installer exited with code $exitCode" -ForegroundColor Yellow
    } else {
        Write-Host "$(get-unicodechar 0x2705) CMake installed successfully!"
    }
}

function install-ninja {
    write-host "$(get-unicodechar 0x1f680) Downloading latest ninja..."
    $ninjaurl = "https://github.com/ninja-build/ninja/releases/latest/download/ninja-win.zip"
    try {
        invoke-webrequest -uri $ninjaurl -outfile "$env:temp\ninja.zip"
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to download Ninja." -foregroundcolor red
    }

    try {
        expand-archive -path "$env:temp\ninja.zip" -destinationpath "$env:localappdata\ninja-build" -force
        write-host "$(get-unicodechar 0x2705) Ninja installed successfully!"
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to install Ninja." -foregroundcolor red
    }
}

function install-msvc {
    write-host "$(get-unicodechar 0x1f680) Installing MSVC toolchain $componentId..."
    $vsInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
    $vsInstallPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community"

    if (Test-Path $vsInstaller) {

        Start-Process -FilePath $vsInstaller -ArgumentList @(
            "modify",
            "--installPath `"$vsInstallPath`"",
            "--add $componentId",
            # can add more --add flags here if needed
            "--quiet",
            "--norestart"
        ) -Wait

        write-host "$(get-unicodechar 0x2705) MSVC installed successfully!"
    } else {
        Write-Host "$(get-unicodechar 0x26a0) Visual Studio Installer not found. Please install Visual Studio with component id $componentId manually." -ForegroundColor Yellow
    }
}

function install-msys2 {
    write-host "$(get-unicodechar 0x1f680) Downloading MSYS2..."

    $latest = get-latestmsys2version
    $latestNormalized = $latest -replace ('-', '')
    $msys2Url = "https://github.com/msys2/msys2-installer/releases/download/$latest/msys2-x86_64-$latestNormalized.exe"
    $installerPath = "$env:TEMP\msys2-installer.exe"
    $msys2Root = "C:\msys64"

    try {
        Invoke-WebRequest -Uri $msys2Url -OutFile $installerPath -Headers @{ "User-Agent" = "installer-script" }
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to download MSYS2." -foregroundcolor red
        return
    }

    write-host "$(get-unicodechar 0x1f4e6) Running MSYS2 installer..."
    write-host "$(get-unicodechar 0x1f4e6) If this hangs, press Enter"
    $exitCode = (Start-Process -FilePath $installerPath -ArgumentList "install --root `"$msys2Root`" --confirm-command" -Wait -PassThru).ExitCode

    if ($exitCode -ne 0) {
        Write-Host "$(get-unicodechar 0x26A0) MSYS2 installer exited with code $exitCode" -ForegroundColor Yellow
    } else {
        Write-Host "$(get-unicodechar 0x2705) MSYS2 installed successfully!"
    }
}

function install-make {
    write-host "$(get-unicodechar 0x1f4e6) Installing make via pacman..."

    $msysBash = "C:\msys64\usr\bin\bash.exe"

    if (Test-Path $msysBash) {
        $exitCode = (Start-Process -NoNewWindow -FilePath $msysBash -ArgumentList "-l", "-c", "'pacman -Syuu --noconfirm'" -Wait -PassThru).ExitCode
        $exitCode = (Start-Process -NoNewWindow -FilePath $msysBash -ArgumentList "-l", "-c", "'pacman -S --noconfirm make'" -Wait -PassThru).ExitCode
        write-host "$(get-unicodechar 0x2705) Installed make"
    } else {
        write-host "$(get-unicodechar 0x26a0) MSYS2 bash not found at $msysBash" -ForegroundColor Yellow
    }
}


function install-llvm {
    write-host "$(get-unicodechar 0x1f680) Downloading LLVM (includes clang-format and clang-tidy)..."
    $latestversion = get-latestclangversion

    $url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-$latestversion/llvm-$latestversion-win64.exe"

    try {
        $installer = "$env:temp\llvm-installer.exe"
        Invoke-WebRequest -uri $url -outfile $installer -Headers @{ "User-Agent" = "installer-script" }
    } catch {
        write-host "$(get-unicodechar 0x26a0) Failed to download LLVM." -foregroundcolor red
        return;
    }

    write-host "$(get-unicodechar 0x1f4e6) Running LLVM installer..."
    write-host "$(get-unicodechar 0x1f4e6) If this hangs, press Enter"
    $exitCode = (Start-Process -FilePath $installer -ArgumentList "/S" -Wait -PassThru).ExitCode

    if ($exitCode -ne 0) {
        Write-Host "$(get-unicodechar 0x26A0) LLVM installer exited with code $exitCode" -ForegroundColor Yellow
    } else {
        Write-Host "$(get-unicodechar 0x2705) LLVM installed successfully!"
    }
}

# install git pre-commit hook
$githooksdir = join-path $psscriptroot "../.git/hooks"
$precommithook = join-path $psscriptroot "../.githooks/pre-commit"

if (-not (test-path "$githooksdir/pre-commit")) {
    write-host "installing pre-commit hook..."
    copy-item -path $precommithook -destination "$githooksdir/pre-commit" -force
    icacls "$githooksdir/pre-commit" /grant everyone:rx > $null  # ensure it's executable
    write-host "$(get-unicodechar 0x2705) installed pre-commit hook"
} else {
    write-host "$(get-unicodechar 0x2705) pre-commit hook already installed. skipping..."
}

$results = refresh-versioninfo

if (-not ($results | Where-Object { $_.IsOutdated })) {
    write-host "$(get-unicodechar 0x2705) CMake, Ninja, LLVM, Git Bash, MSVC, and MSYS2 are already up to date!"

    $confirmation = Read-Host "Do you want to update system PATH? [Y/N]"

    if ($confirmation -notin @("Y", "y")) {
        write-host "$(get-unicodechar 0x1F92C) Aborting setup."
        write-host "$(get-unicodechar 0x1f91d) press any key to exit..." -foregroundcolor cyan
        $null = $host.ui.rawui.readkey("noecho,includekeydown")
        exit 1
    }
}

if (-not (test-isadmin)) {
    write-host "$(get-unicodechar 0x26a0) warning: admin rights required to install cmake/ninja." -foregroundcolor yellow
    write-host "🚀 restarting as administrator..."
    
    start-process powershell -argumentlist "-file `"$pscommandpath`"" -verb runas
    exit
}

$cmake, $ninja, $clang, $git, $msys2, $msvc = refresh-versioninfo

$outdated = $results | Where-Object { $_.IsOutdated }
if ($outdated -and $didFailToFetchVersions) {
    Write-Host "$(get-unicodechar 0x26A0) Failed to fetch latest versions. This may be due to GitHub rate limiting."
    Write-Host "$(get-unicodechar 0x26A0) All tools will now be (re)installed to ensure a clean setup."
    Write-Host "$(get-unicodechar 0x26A0) If you're being rate limited by GitHub the installers will fail (obviously)."
    $confirmation = Read-Host "Do you want to continue? [Y/N]"

    if ($confirmation -notin @("Y", "y")) {
        Write-Host "0x1F92C Aborting setup."
        exit 1
    }
}
if ($cmake.IsOutdated) { install-cmake }
if ($ninja.IsOutdated) { install-ninja }
if ($clang.IsOutdated) { install-llvm }
if ($git.IsOutdated)   { install-gitbash }
if ($msvc.IsOutdated)  { install-msvc }
if ($msys2.IsOutdated) { install-msys2 }
install-make

write-host "$(get-unicodechar 0x1f4e6) Updating PATH..."
add-to-path "$env:ProgramFiles\git\bin"
add-to-path "$env:ProgramFiles\CMake\bin"
add-to-path "$env:localappdata\ninja-build"
add-to-path "C:\msys64\usr\bin"
add-to-path "$env:ProgramFiles\LLVM\bin"

write-host "$(get-unicodechar 0x1F501) Refreshing PATH from system environment..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")


write-host ""
foreach ($r in refresh-versioninfo) {
    if ($r.IsOutdated) {
        write-host "$(get-unicodechar 0x274C) $($r.Name) is still outdated. Installed: $($r.Installed), Latest: $($r.Latest)" -foregroundcolor red
    } else {
        write-host "$(get-unicodechar 0x2705) $($r.Name) is now up to date! (v$r.Installed)"
    }
}

if ($results | Where-Object { $_.IsOutdated }) {
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
    write-host "$(get-unicodechar 0x274C) Some tools failed to install or update. You must install these manually. See README for help." -foregroundcolor red
    write-host ""
} else {
    write-host "$(get-unicodechar 0x2705) All tools installed and up to date!" -foregroundcolor green
}

write-host ""
write-host "$(get-unicodechar 0x1f91d) Press any key to exit..." -foregroundcolor cyan
$null = $host.ui.rawui.readkey("noecho,includekeydown")
exit
