# Create ZIP file for CASPIT Testing Interface
# This script creates a ZIP file with config.json and index_static.html

$zipPath = "caspit_config.zip"
$configPath = "caspit_config.json"
$htmlPath = "index_static.html"

Write-Host "Creating CASPIT config ZIP..." -ForegroundColor Green

# Check if files exist
if (-not (Test-Path $configPath)) {
    Write-Host "Error: $configPath not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $htmlPath)) {
    Write-Host "Error: $htmlPath not found!" -ForegroundColor Red
    exit 1
}

# Remove old ZIP if exists
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
    Write-Host "Removed old ZIP file" -ForegroundColor Yellow
}

# Create ZIP file
try {
    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "caspit_zip_temp"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Copy files to temp directory
    Copy-Item $configPath -Destination (Join-Path $tempDir "config.json")
    Copy-Item $htmlPath -Destination (Join-Path $tempDir "index_static.html")
    
    Write-Host "Added config.json" -ForegroundColor Green
    Write-Host "Added index_static.html" -ForegroundColor Green
    
    # Create ZIP using Compress-Archive
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "`n✅ ZIP created successfully: $zipPath" -ForegroundColor Green
    Write-Host "`nTo use this ZIP:" -ForegroundColor Cyan
    Write-Host "1. Load it in the Flutter app using the config loader" -ForegroundColor Cyan
    Write-Host "2. Or place it in the app's documents directory" -ForegroundColor Cyan
    Write-Host "`nFile size: $((Get-Item $zipPath).Length) bytes" -ForegroundColor Gray
} catch {
    Write-Host "Error creating ZIP: $_" -ForegroundColor Red
    exit 1
}

