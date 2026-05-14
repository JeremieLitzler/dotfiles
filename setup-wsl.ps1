# setup-wsl.ps1 — Phase 5: Standalone idempotent WSL installer.
# Run from PowerShell as Administrator:
#   .\setup-wsl.ps1
# Safe to re-run — checks state at each step and resumes from where it left off.
# May require a reboot after Step 1.

$ubuntuPath = 'E:\WSL\Ubuntu'
$exportPath = 'E:\WSL\Ubuntu-export.tar'

# --- Step 1: Enable WSL (modern Windows 11 installs WSL as a platform component,
#     not the legacy optional feature, so test wsl --version instead) ---
wsl --version 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing WSL..." -ForegroundColor Cyan
    wsl --install --no-distribution
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "  Reboot now, then re-run this script." -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    exit 0
}
Write-Host "WSL already installed." -ForegroundColor Green

# --- Step 2: Install Ubuntu ---
wsl -d Ubuntu -- true 2>$null
if ($LASTEXITCODE -ne 0) {
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
if ((Test-Path $ubuntuPath) -and (Get-ChildItem $ubuntuPath -ErrorAction SilentlyContinue)) {
    Write-Host "Ubuntu already relocated to $ubuntuPath." -ForegroundColor Green
} else {
    Write-Host "Relocating Ubuntu to $ubuntuPath..." -ForegroundColor Cyan

    # Get the default username before export
    $defaultUser = wsl -d Ubuntu -- whoami 2>$null
    if (-not $defaultUser) { $defaultUser = Read-Host "Enter WSL Ubuntu username" }

    New-Item -ItemType Directory -Force -Path $ubuntuPath | Out-Null

    wsl --export Ubuntu $exportPath
    wsl --unregister Ubuntu
    wsl --import Ubuntu $ubuntuPath $exportPath

    # Restore default user via wsl.conf (ubuntu.exe not available with wsl --install)
    wsl -d Ubuntu -u root -- bash -c "printf '[user]\ndefault=$defaultUser\n' > /etc/wsl.conf"
    wsl --terminate Ubuntu

    Remove-Item $exportPath -ErrorAction SilentlyContinue
    Write-Host "Ubuntu relocated to $ubuntuPath." -ForegroundColor Green
}

# --- Step 4: Verify ---
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
wsl -l -v
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  WSL ready. Open Ubuntu and run Phase 6." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green