# Packages a Release build into IPTVX-<version>-windows-x64-setup.exe.
#
#   pwsh packaging/windows/package.ps1 -BuildDir build/release -Version 0.2.0 -OutDir dist
#
# Requires windeployqt (Qt bin on PATH) and Inno Setup 6 (ISCC.exe).
param(
    [Parameter(Mandatory)] [string] $BuildDir,
    [Parameter(Mandatory)] [string] $Version,
    [string] $OutDir = "dist"
)
$ErrorActionPreference = "Stop"
$Repo = (Resolve-Path "$PSScriptRoot/../..").Path
$Stage = Join-Path $BuildDir "deploy"
New-Item -ItemType Directory -Force -Path $Stage, $OutDir | Out-Null

# qt_standard_project_setup() puts executables at the build root on Windows.
$exe = @("IPTVX.exe", "src/app/IPTVX.exe") | ForEach-Object { Join-Path $BuildDir $_ } |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) { throw "IPTVX.exe not found in $BuildDir" }
Copy-Item $exe $Stage -Force
windeployqt --release --qmldir (Join-Path $Repo "src/ui/qml") `
    --no-translations --no-system-d3d-compiler --no-compiler-runtime `
    (Join-Path $Stage "IPTVX.exe")
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed" }
# IPTVX only uses SQLite: drop the other SQL drivers.
Get-ChildItem (Join-Path $Stage "sqldrivers") -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "sqlite" } | Remove-Item -Force

# MSVC runtime next to the app (no separate redistributable install needed).
$vcRedist = Get-ChildItem "$env:VCToolsRedistDir\x64\Microsoft.VC*.CRT" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($vcRedist) { Copy-Item "$($vcRedist.FullName)\*.dll" $Stage -Force }

$iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source
if (-not $iscc) { $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" }
if (-not (Test-Path $iscc)) { throw "Inno Setup (ISCC.exe) not found" }

$name = "IPTVX-$Version-windows-x64-setup"
& $iscc "/DAppVersion=$Version" "/DSourceDir=$((Resolve-Path $Stage).Path)" "/DRepoDir=$Repo" `
    "/DOutputDir=$((Resolve-Path $OutDir).Path)" "/DOutputName=$name" `
    (Join-Path $Repo "packaging/windows/iptvx.iss")
if ($LASTEXITCODE -ne 0) { throw "ISCC failed" }
Write-Host "Created $OutDir/$name.exe"
