# PowerShell script to create example ZIP file with config.json and images
# This creates a standard ZIP format that the Flutter app can consume

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Example ZIP File" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Create temporary directory
$tempDir = Join-Path $env:TEMP "flutter_zip_example"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "`nStep 1: Creating config.json..." -ForegroundColor Yellow

# Create config.json with example structure
$configJsonContent = @'
{
  "version": "1.0.0",
  "screens": [
    {
      "id": "home",
      "type": "list",
      "title": "בית",
      "items": [
        {
          "id": "item1",
          "title": "תמונות",
          "subtitle": "צפה בתמונות מהזיכרון",
          "icon": "images/photo.png",
          "route": "/photos"
        },
        {
          "id": "item2",
          "title": "הגדרות",
          "subtitle": "הגדרות האפליקציה",
          "icon": "images/settings.png",
          "route": "/settings"
        },
        {
          "id": "item3",
          "title": "אודות",
          "subtitle": "מידע על האפליקציה",
          "icon": "images/info.png",
          "route": "/about"
        }
      ]
    }
  ],
  "theme": {
    "primaryColor": "#1976D2",
    "secondaryColor": "#424242",
    "backgroundColor": "#FFFFFF"
  }
}
'@

$configPath = Join-Path $tempDir "config.json"
[System.IO.File]::WriteAllText($configPath, $configJsonContent, [System.Text.Encoding]::UTF8)

Write-Host "✓ config.json created" -ForegroundColor Green

Write-Host "`nStep 2: Creating images directory..." -ForegroundColor Yellow

# Create images directory
$imagesDir = Join-Path $tempDir "images"
New-Item -ItemType Directory -Path $imagesDir | Out-Null

# Create placeholder images (simple colored squares as PNG)
Write-Host "Creating placeholder images..." -ForegroundColor Gray

# Create a simple 1x1 PNG image (valid PNG format)
$pngBytes = [byte[]]@(
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82
)

$photoPath = Join-Path $imagesDir "photo.png"
[System.IO.File]::WriteAllBytes($photoPath, $pngBytes)

$settingsPath = Join-Path $imagesDir "settings.png"
[System.IO.File]::WriteAllBytes($settingsPath, $pngBytes)

$infoPath = Join-Path $imagesDir "info.png"
[System.IO.File]::WriteAllBytes($infoPath, $pngBytes)

Write-Host "  Created: photo.png, settings.png, info.png" -ForegroundColor Gray

Write-Host "✓ Images created" -ForegroundColor Green

Write-Host "`nStep 3: Creating ZIP file..." -ForegroundColor Yellow

# Create ZIP file
$zipPath = Join-Path $PSScriptRoot "example_app_config.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Use .NET compression to create ZIP
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipPath)

Write-Host "✓ ZIP file created: $zipPath" -ForegroundColor Green

# Cleanup
Remove-Item $tempDir -Recurse -Force

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Success!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nExample ZIP file created at:" -ForegroundColor Yellow
Write-Host "$zipPath" -ForegroundColor White
Write-Host "`nYou can now:" -ForegroundColor Yellow
Write-Host "1. Load this ZIP file in the Flutter app" -ForegroundColor White
Write-Host "2. Use it as a template for your backend" -ForegroundColor White
Write-Host "`nZIP Structure:" -ForegroundColor Yellow
Write-Host "  example_app_config.zip" -ForegroundColor White
Write-Host "    ├── config.json" -ForegroundColor Gray
Write-Host "    └── images/" -ForegroundColor Gray
Write-Host "        ├── photo.png" -ForegroundColor Gray
Write-Host "        ├── settings.png" -ForegroundColor Gray
Write-Host "        └── info.png" -ForegroundColor Gray

