# Analyze HTML.GZ file structure to understand config location
param(
    [string]$FilePath = ""
)

if ([string]::IsNullOrEmpty($FilePath)) {
    Write-Host "Please provide the path to the HTML.GZ file" -ForegroundColor Yellow
    Write-Host "Usage: .\analyze_html_gz.ps1 -FilePath 'path\to\file.html.gz'" -ForegroundColor Cyan
    exit 1
}

if (-not (Test-Path $FilePath)) {
    Write-Host "File not found: $FilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Analyzing file: $FilePath" -ForegroundColor Cyan
Write-Host ""

# Create temp directory
$tempDir = Join-Path $env:TEMP "html_gz_analysis_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Decompress GZ
    Write-Host "Decompressing GZ file..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    $gzStream = [System.IO.File]::OpenRead($FilePath)
    $gzipStream = New-Object System.IO.Compression.GZipStream($gzStream, [System.IO.Compression.CompressionMode]::Decompress)
    $decompressedFile = Join-Path $tempDir "decompressed.html"
    $fileStream = [System.IO.File]::Create($decompressedFile)
    $gzipStream.CopyTo($fileStream)
    
    $fileStream.Close()
    $gzipStream.Close()
    $gzStream.Close()
    
    Write-Host "File decompressed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Read HTML content
    $htmlContent = Get-Content -Path $decompressedFile -Raw -Encoding UTF8
    $htmlLength = $htmlContent.Length
    
    Write-Host "HTML Content Length: $htmlLength characters" -ForegroundColor Cyan
    Write-Host ""
    
    # Search for config-related keywords
    Write-Host "=== Searching for config-related keywords ===" -ForegroundColor Yellow
    Write-Host ""
    
    $keywords = @("screens", "version", "theme", "config", "appConfig", "app-config")
    foreach ($keyword in $keywords) {
        $count = ([regex]::Matches($htmlContent, $keyword, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
        if ($count -gt 0) {
            Write-Host "Found '$keyword': $count occurrences" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "=== Searching for JSON-like structures ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Look for JSON objects
    $jsonPattern = '\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
    $jsonMatches = [regex]::Matches($htmlContent, $jsonPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    Write-Host "Found $($jsonMatches.Count) potential JSON objects" -ForegroundColor Cyan
    
    # Check first few matches
    $foundConfig = $false
    for ($i = 0; $i -lt [Math]::Min(10, $jsonMatches.Count); $i++) {
        $match = $jsonMatches[$i]
        $jsonStr = $match.Value
        $preview = if ($jsonStr.Length -gt 200) { $jsonStr.Substring(0, 200) + "..." } else { $jsonStr }
        
        if ($jsonStr -match '"screens"' -or $jsonStr -match '"version"' -or $jsonStr -match '"theme"') {
            Write-Host ""
            Write-Host "=== FOUND CONFIG CANDIDATE #$($i+1) ===" -ForegroundColor Green
            Write-Host "Length: $($jsonStr.Length) characters" -ForegroundColor Cyan
            Write-Host "Preview: $preview" -ForegroundColor White
            Write-Host ""
            
            # Save to file for inspection
            $configFile = Join-Path $tempDir "config_candidate_$($i+1).json"
            $jsonStr | Out-File -FilePath $configFile -Encoding UTF8
            Write-Host "Saved to: $configFile" -ForegroundColor Yellow
            $foundConfig = $true
        }
    }
    
    Write-Host ""
    Write-Host "=== Searching in script tags ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Extract script tags
    $scriptPattern = '<script[^>]*>(.*?)</script>'
    $scriptMatches = [regex]::Matches($htmlContent, $scriptPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    Write-Host "Found $($scriptMatches.Count) script tags" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $scriptMatches.Count; $i++) {
        $scriptContent = $scriptMatches[$i].Groups[1].Value
        $scriptLength = $scriptContent.Length
        
        Write-Host ""
        Write-Host "Script #$($i+1): Length=$scriptLength" -ForegroundColor Cyan
        
        # Check if contains config keywords
        $hasConfig = $false
        foreach ($keyword in $keywords) {
            if ($scriptContent -match $keyword) {
                Write-Host "  Contains '$keyword'" -ForegroundColor Green
                $hasConfig = $true
            }
        }
        
        if ($hasConfig) {
            # Look for config assignment
            $configPatterns = @(
                '(?:const|let|var)\s+\w*config\w*\s*=\s*(\{.*?\});',
                'window\.\w*config\w*\s*=\s*(\{.*?\});',
                'appConfig\s*[:=]\s*(\{.*?\})',
                'config\s*[:=]\s*(\{.*?\})'
            )
            
            foreach ($pattern in $configPatterns) {
                $match = [regex]::Match($scriptContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($match.Success) {
                    Write-Host "  Found config assignment!" -ForegroundColor Green
                    $configJson = $match.Groups[1].Value
                    $preview = if ($configJson.Length -gt 200) { $configJson.Substring(0, 200) + "..." } else { $configJson }
                    Write-Host "  Preview: $preview" -ForegroundColor White
                    
                    # Save to file
                    $configFile = Join-Path $tempDir "config_from_script_$($i+1).json"
                    $configJson | Out-File -FilePath $configFile -Encoding UTF8
                    Write-Host "  Saved to: $configFile" -ForegroundColor Yellow
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Analysis complete ===" -ForegroundColor Green
    Write-Host "Temp files saved in: $tempDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To inspect the decompressed HTML:" -ForegroundColor Yellow
    Write-Host "  notepad $decompressedFile" -ForegroundColor White
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    # Don't delete temp dir - user might want to inspect files
    Write-Host ""
    Write-Host "Note: Temp directory will NOT be deleted: $tempDir" -ForegroundColor Yellow
}


