# Downloads the TensorFlow Lite C DLL required by tflite_flutter on Windows.
# Run once from the project root: .\scripts\setup_tflite_windows.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$blobs = Join-Path $root "blobs"
$dll = Join-Path $blobs "libtensorflowlite_c-win.dll"
$url = "https://github.com/am15h/tflite_flutter_plugin/raw/master/example/blobs/libtensorflowlite_c-win.dll"

New-Item -ItemType Directory -Force -Path $blobs | Out-Null

if ((Test-Path $dll) -and ((Get-Item $dll).Length -gt 1MB)) {
    Write-Host "Already present: $dll"
    exit 0
}

Write-Host "Downloading $url ..."
Invoke-WebRequest -Uri $url -OutFile $dll -UseBasicParsing
Write-Host "Saved: $dll ($((Get-Item $dll).Length) bytes)"
