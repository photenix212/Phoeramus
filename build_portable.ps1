$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$Python = Join-Path $Root ".venv\Scripts\python.exe"
if (-not (Test-Path $Python)) {
    throw "Missing .venv. Create it first: py -3.13 -m venv .venv"
}

if (-not (Test-Path ".\bin\ffmpeg.exe") -or -not (Test-Path ".\bin\ffprobe.exe")) {
    & ".\setup_ffmpeg.ps1"
}

Write-Host "[1/4] Installing build dependencies..."
& $Python -m pip install -U pip pyinstaller
& $Python -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed." }

Write-Host "[2/4] Cleaning previous build..."
Remove-Item -Recurse -Force ".\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\dist\Phoeramus" -ErrorAction SilentlyContinue
Remove-Item -Force ".\Phoeramus.spec" -ErrorAction SilentlyContinue

Write-Host "[3/4] Building Phoeramus..."
& $Python -m PyInstaller `
    --noconfirm `
    --clean `
    --windowed `
    --name "Phoeramus" `
    --contents-directory "." `
    --add-data "ui;ui" `
    --add-data "bin;bin" `
    --add-data "icon.png;." `
    --collect-all "yt_dlp" `
    --hidden-import "PySide6.QtQuick" `
    --hidden-import "PySide6.QtQuickControls2" `
    "main.py"
if ($LASTEXITCODE -ne 0) { throw "PyInstaller build failed." }

$Portable = Join-Path $Root "dist\Phoeramus"
New-Item -ItemType Directory -Force (Join-Path $Portable "data") | Out-Null
Remove-Item -Force (Join-Path $Portable "data\settings.json") -ErrorAction SilentlyContinue
Remove-Item -Force (Join-Path $Portable "data\history.json") -ErrorAction SilentlyContinue

Write-Host "[4/4] Creating portable ZIP..."
$Zip = Join-Path $Root "dist\Phoeramus-v1.0.0-portable.zip"
Remove-Item -Force $Zip -ErrorAction SilentlyContinue
Compress-Archive -Path "$Portable\*" -DestinationPath $Zip -CompressionLevel Optimal

Write-Host ""
Write-Host "READY"
Write-Host "EXE: $Portable\Phoeramus.exe"
Write-Host "ZIP: $Zip"
