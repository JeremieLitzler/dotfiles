# run_once_04-rtk-install.ps1
# Managed by chezmoi — runs once on first apply.
# Downloads latest RTK binary for Windows and creates MINGW64 symlink.

# Get latest release download URL
$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/rtk-ai/rtk/releases/latest'
$asset = $release.assets | Where-Object { $_.name -match 'windows.*amd64' -and $_.name -match '\.exe$' } | Select-Object -First 1

if ($asset) {
    New-Item -ItemType Directory -Force -Path 'E:\rtk\bin' | Out-Null
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile 'E:\rtk\bin\rtk.exe'
}
