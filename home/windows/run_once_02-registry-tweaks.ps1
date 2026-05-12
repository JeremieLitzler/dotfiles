# run_once_02-registry-tweaks.ps1
# Managed by chezmoi — runs once on first apply.
# Restores the legacy Windows 11 right-click context menu.

$regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-a12c-4e6b-a4fc-1681e7e682a2}\InprocServer32"
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "(default)" -Value ""
}
