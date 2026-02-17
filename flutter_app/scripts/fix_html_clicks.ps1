# Fix all @click to onclick in HTML files
$files = Get-ChildItem -Path "html_screens" -Filter "*.html"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $content = $content -replace '@click="navigate\(', 'onclick="navigate('
    $content = $content -replace '@click="([^"]+)"', 'onclick="$1()"'
    Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
}

Write-Host "Fixed all @click to onclick in HTML files"

