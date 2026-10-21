$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Bin = Join-Path $Root "bin"
$Ffmpeg = Join-Path $Bin "ffmpeg.exe"
$Ffprobe = Join-Path $Bin "ffprobe.exe"

if ((Test-Path $Ffmpeg) -and (Test-Path $Ffprobe)) {
    Write-Host "FFmpeg and ffprobe are already installed in .\bin"
    exit 0
}

New-Item -ItemType Directory -Force $Bin | Out-Null
$Temp = Join-Path $env:TEMP "phoeramus-ffmpeg"
$Zip = Join-Path $Temp "ffmpeg.zip"
Remove-Item -Recurse -Force $Temp -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $Temp | Out-Null

$Url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
Write-Host "Downloading FFmpeg essentials..."
Invoke-WebRequest -Uri $Url -OutFile $Zip

Write-Host "Extracting..."
Expand-Archive -Path $Zip -DestinationPath $Temp -Force
$ExtractedBin = Get-ChildItem $Temp -Directory | Where-Object { $_.Name -like "ffmpeg-*" } | Select-Object -First 1
if (-not $ExtractedBin) { throw "Could not locate extracted FFmpeg folder." }

Copy-Item (Join-Path $ExtractedBin.FullName "bin\ffmpeg.exe") $Ffmpeg -Force
Copy-Item (Join-Path $ExtractedBin.FullName "bin\ffprobe.exe") $Ffprobe -Force
Remove-Item -Recurse -Force $Temp -ErrorAction SilentlyContinue
Write-Host "Ready: .\bin\ffmpeg.exe and .\bin\ffprobe.exe"
