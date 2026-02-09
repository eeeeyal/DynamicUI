# Flutter Installation Script for Windows
# Run this script as Administrator or with appropriate permissions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Installation Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Find the ZIP file
Write-Host "Step 1: Looking for Flutter ZIP file..." -ForegroundColor Yellow

$zipFile = $null
$possiblePaths = @(
    "$env:USERPROFILE\Downloads\flutter_windows_*.zip",
    "$env:USERPROFILE\Desktop\flutter_windows_*.zip",
    ".\flutter_windows_*.zip"
)

foreach ($path in $possiblePaths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $zipFile = $found.FullName
        Write-Host "Found: $zipFile" -ForegroundColor Green
        break
    }
}

if (-not $zipFile) {
    Write-Host "ZIP file not found automatically." -ForegroundColor Red
    Write-Host "Please enter the full path to flutter_windows_3.38.9-stable.zip:" -ForegroundColor Yellow
    $zipFile = Read-Host
    if (-not (Test-Path $zipFile)) {
        Write-Host "File not found: $zipFile" -ForegroundColor Red
        exit 1
    }
}

# Step 2: Choose extraction location
Write-Host ""
Write-Host "Step 2: Choose extraction location..." -ForegroundColor Yellow
Write-Host "Recommended: C:\src\flutter" -ForegroundColor Cyan
Write-Host "Or press Enter to use: C:\src\flutter" -ForegroundColor Cyan
$extractPath = Read-Host "Enter path (or press Enter for default)"

if ([string]::IsNullOrWhiteSpace($extractPath)) {
    $extractPath = "C:\src\flutter"
}

# Check if directory exists
if (Test-Path $extractPath) {
    Write-Host "Warning: Directory already exists: $extractPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Installation cancelled." -ForegroundColor Red
        exit 0
    }
    Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Create parent directory if needed
$parentDir = Split-Path -Parent $extractPath
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    Write-Host "Created directory: $parentDir" -ForegroundColor Green
}

# Step 3: Extract ZIP
Write-Host ""
Write-Host "Step 3: Extracting Flutter..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Cyan

try {
    Expand-Archive -Path $zipFile -DestinationPath $parentDir -Force
    Write-Host "Extraction completed!" -ForegroundColor Green
} catch {
    Write-Host "Error extracting ZIP: $_" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Alternative: Use .NET
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $parentDir)
    Write-Host "Extraction completed!" -ForegroundColor Green
}

# Verify extraction
$flutterBin = Join-Path $extractPath "bin\flutter.bat"
if (-not (Test-Path $flutterBin)) {
    Write-Host "Error: Flutter not found after extraction!" -ForegroundColor Red
    Write-Host "Expected: $flutterBin" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 4: Adding Flutter to PATH..." -ForegroundColor Yellow

# Add to user PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterBinPath = Join-Path $extractPath "bin"

if ($currentPath -notlike "*$flutterBinPath*") {
    $newPath = $currentPath + ";" + $flutterBinPath
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added to PATH: $flutterBinPath" -ForegroundColor Green
} else {
    Write-Host "Already in PATH: $flutterBinPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Close and reopen PowerShell/CMD for PATH changes to take effect!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Close this PowerShell window" -ForegroundColor White
Write-Host "2. Open a NEW PowerShell window" -ForegroundColor White
Write-Host "3. Run: flutter doctor" -ForegroundColor White
Write-Host "4. Run: flutter pub get (in flutter_app directory)" -ForegroundColor White
Write-Host ""
Write-Host "Flutter installed at: $extractPath" -ForegroundColor Green

