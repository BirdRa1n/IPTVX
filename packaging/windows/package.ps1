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
    --no-translations --no-system-d3d-compiler --no-compiler-runtime --no-opengl-sw `
    (Join-Path $Stage "IPTVX.exe")
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed" }
# ---- Prune what IPTVX never loads --------------------------------------------
# IPTVX uses the Basic Qt Quick Controls style and SQLite only. windeployqt
# copies every style (and QtWidgets for the widget style plugin).
$styles = "FluentWinUI3","Fusion","Imagine","Material","Universal","WindowsStyleImpl","Windows","Native"
foreach ($s in $styles) {
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Stage "Qt6QuickControls2$s.dll"), (Join-Path $Stage "Qt6QuickControls2${s}StyleImpl.dll")
}
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Stage "Qt6QuickNativeStyle.dll"), (Join-Path $Stage "Qt6Widgets.dll"),
    (Join-Path $Stage "Qt6QuickParticles.dll"), (Join-Path $Stage "Qt6QuickShapesDesignHelpers.dll"),
    (Join-Path $Stage "Qt6QuickVectorImage.dll"), (Join-Path $Stage "Qt6QuickVectorImageGenerator.dll"),
    (Join-Path $Stage "Qt6QuickVectorImageHelpers.dll")
foreach ($d in "FluentWinUI3","Fusion","Imagine","Material","Native","Universal","Windows","designer") {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $Stage "qml/QtQuick/Controls/$d")
}
foreach ($d in "qml/QtQuick/NativeStyle","qml/QtQuick/Particles","qml/QtQuick/VectorImage","qml/QtQuick/Shapes/DesignHelpers","styles") {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $Stage $d)
}
Get-ChildItem (Join-Path $Stage "sqldrivers") -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "sqlite" } | Remove-Item -Force

# Safety net: every Qt DLL still referenced by a shipped binary must be shipped.
$missing = @()
Get-ChildItem $Stage -Recurse -Include *.dll, *.exe | ForEach-Object {
    $bin = $_
    dumpbin /nologo /dependents $bin.FullName | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^Qt6\w+\.dll$' } | ForEach-Object {
            if (-not (Test-Path (Join-Path $Stage $_))) { $missing += "$($bin.Name) -> $_" }
        }
}
if ($missing.Count -gt 0) { $missing | Write-Error; throw "Pruned DLLs are still referenced" }

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
