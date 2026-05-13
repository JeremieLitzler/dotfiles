# Phase 5: Standalone idempotent WSL installer.
# Run from PowerShell as Administrator:
#   .\setup-wsl.ps1
# Safe to re-run — checks state at each step and resumes from where it left off.
# May require a reboot after Step 1.

$ubuntuPath = 'E:\WSL\Ubuntu'
$exportPath = 'E:\WSL\Ubuntu-export.tar'

# --- Pre-check: Proton Pass CLI ---
if (-not (Get-Command pass-cli -ErrorAction SilentlyContinue)) {
    Write-Host "pass-cli not found. Install it first:" -ForegroundColor Red
    Write-Host "  Invoke-WebRequest -Uri https://proton.me/download/pass-cli/install.ps1 -OutFile install.ps1; .\install.ps1" -ForegroundColor Yellow
    exit 1
}

$passCheck = pass-cli info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "pass-cli not logged in. Run 'pass-cli login' first." -ForegroundColor Red
    exit 1
}
Write-Host "pass-cli authenticated." -ForegroundColor Green

# --- Step 1: Enable WSL feature ---
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne 'Enabled') {
    Write-Host "Enabling WSL feature..." -ForegroundColor Cyan
    wsl --install --no-distribution
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "  Reboot now, then re-run this script." -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    exit 0
}
Write-Host "WSL feature already enabled." -ForegroundColor Green

# --- Step 2: Install Ubuntu ---
$installed = wsl -l -q 2>$null | Where-Object { $_ -match 'Ubuntu' }
if (-not $installed) {
    Write-Host "Installing Ubuntu..." -ForegroundColor Cyan
    wsl --install Ubuntu
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "  Ubuntu is installing. Complete the user" -ForegroundColor Yellow
    Write-Host "  creation prompt inside Ubuntu, then" -ForegroundColor Yellow
    Write-Host "  close Ubuntu and re-run this script." -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    exit 0
}
Write-Host "Ubuntu already installed." -ForegroundColor Green

# --- Step 3: Relocate to E:\WSL\Ubuntu ---
$wslOutput = wsl -l -v 2>$null
if ($wslOutput -match 'Ubuntu' -and (Test-Path $ubuntuPath)) {
    Write-Host "Ubuntu already relocated to $ubuntuPath." -ForegroundColor Green
} else {
    Write-Host "Relocating Ubuntu to $ubuntuPath..." -ForegroundColor Cyan

    # Get the default username from Proton Pass
    $defaultUser = pass-cli item view "pass://vBD6igol40j9TgRpoaiYnl2PngDIyS3HmQSWKrN3Bu2Dm6d7iTDXIVX0ltxOXUlBlWwvtiSUSeZyT_lx4svADQ==/-7n5Zh8ehoACaVHszmyisRk0RjTk-7gnVz2DuSjudsrT1Ujj5W7vC02VByUnT_29F3OBkBsgRC4jnFqyCv0ZVA==/Username"    if (-not $defaultUser) { $defaultUser = Read-Host "Enter WSL Ubuntu username" }

    New-Item -ItemType Directory -Force -Path $ubuntuPath | Out-Null

    wsl --export Ubuntu $exportPath
    wsl --unregister Ubuntu
    wsl --import Ubuntu $ubuntuPath $exportPath

    # Restore default user
    ubuntu config --default-user $
