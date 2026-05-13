# Run periodically to update all tools.

Write-Host "=== Updating Scoop apps ===" -ForegroundColor Cyan
scoop update *

Write-Host "=== Updating RTK ===" -ForegroundColor Cyan
# Re-download latest
$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/rtk-ai/rtk/releases/latest'
$asset = $release.assets | Where-Object { $_.name -match 'windows.*amd64' -and $_.name -match '\.exe$' } | Select-Object -First 1
if ($asset) {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile 'E:\rtk\bin\rtk.exe'
}

Write-Host "=== Updating npm globals ===" -ForegroundColor Cyan
npm update -g
