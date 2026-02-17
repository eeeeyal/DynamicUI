# Add Flutter to PATH permanently and refresh current session

Write-Host "Adding Flutter to PATH..." -ForegroundColor Yellow

# Add to User PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterPath = "C:\src\flutter\bin"

if ($currentPath -notlike "*$flutterPath*") {
    $newPath = $currentPath + ";" + $flutterPath
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added Flutter to User PATH" -ForegroundColor Green
} else {
    Write-Host "Flutter already in User PATH" -ForegroundColor Yellow
}

# Refresh current session PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""
Write-Host "PATH refreshed for current session!" -ForegroundColor Green
Write-Host "Testing Flutter..." -ForegroundColor Yellow

# Test Flutter
try {
    $flutterVersion = & "C:\src\flutter\bin\flutter.bat" --version 2>&1 | Select-Object -First 1
    Write-Host "Flutter is working: $flutterVersion" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now use 'flutter' command in this PowerShell session!" -ForegroundColor Cyan
} catch {
    Write-Host "Error testing Flutter: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Note: For new PowerShell windows, Flutter will work automatically." -ForegroundColor Yellow


