# Create a test ZIP file for local testing
# This creates a ZIP with config.json and assets structure

Write-Host "Creating test ZIP file..." -ForegroundColor Yellow

$tempDir = ".\test_config"
$zipPath = ".\test_config.zip"

# Clean up old files
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

# Create directory structure
New-Item -ItemType Directory -Path "$tempDir\assets\icons" -Force | Out-Null

# Copy config.json
Copy-Item -Path ".\flutter_app\example_config.json" -Destination "$tempDir\config.json"

# Create a simple placeholder icon (optional)
# You can add real images here if needed

# Create ZIP
Write-Host "Creating ZIP file..." -ForegroundColor Yellow
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

# Clean up temp directory
Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "Test ZIP created: $zipPath" -ForegroundColor Green
Write-Host ""
Write-Host "To use it:" -ForegroundColor Cyan
Write-Host "1. Host it on a local server (e.g., Python: python -m http.server 8000)" -ForegroundColor White
Write-Host "2. Or use file:// protocol (limited functionality)" -ForegroundColor White
Write-Host "3. Enter the URL in the app: http://localhost:8000/test_config.zip" -ForegroundColor White

