# Create a test GZ file for local testing
# This creates a GZ file with config.json compressed

Write-Host "Creating test GZ file..." -ForegroundColor Yellow

$configFile = ".\flutter_app\example_config.json"
$gzPath = ".\test_config.gz"

if (-not (Test-Path $configFile)) {
    Write-Host "Error: example_config.json not found!" -ForegroundColor Red
    exit 1
}

# Read config.json
$configContent = Get-Content -Path $configFile -Raw -Encoding UTF8

# Create GZ file using .NET compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

try {
    # Create temporary file
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $configContent, [System.Text.Encoding]::UTF8)
    
    # Compress to GZ
    $gzStream = [System.IO.File]::Create($gzPath)
    $gzipStream = New-Object System.IO.Compression.GZipStream($gzStream, [System.IO.Compression.CompressionMode]::Compress)
    $fileStream = [System.IO.File]::OpenRead($tempFile)
    $fileStream.CopyTo($gzipStream)
    
    $fileStream.Close()
    $gzipStream.Close()
    $gzStream.Close()
    
    # Clean up temp file
    Remove-Item $tempFile -Force
    
    Write-Host ""
    Write-Host "Test GZ file created: $gzPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "To use it:" -ForegroundColor Cyan
    Write-Host "1. Run the Flutter app" -ForegroundColor White
    Write-Host "2. Click 'Choose Local File'" -ForegroundColor White
    Write-Host "3. Select: test_config.gz" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "Error creating GZ file: $_" -ForegroundColor Red
    exit 1
}

