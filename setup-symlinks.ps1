# Phase 4.2: Move Chrome and Signal data to E: and symlink back.
# Run from PowerShell as Administrator:
#   .\setup-symlinks.ps1
# Prerequisites: Chrome and Signal must be installed, configured, and FULLY CLOSED.

# --- Pre-check: Admin ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

function Move-And-Symlink {
    param (
        [string]$Source,
        [string]$Destination
    )

    # Already a symlink — skip
    if ((Get-Item $Source -ErrorAction SilentlyContinue).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host "Already symlinked: $Source" -ForegroundColor Green
        return
    }

    # Source doesn't exist — nothing to move
    if (-not (Test-Path $Source)) {
        Write-Host "Source not found, skipping: $Source" -ForegroundColor Yellow
        return
    }

    # Copy to destination
    Write-Host "Copying $Source → $Destination ..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination) | Out-Null
    Copy-Item -Path $Source -Destination $Destination -Recurse -Force

    # Remove original and create symlink
    Remove-Item -Path $Source -Recurse -Force
    New-Item -ItemType SymbolicLink -Path $Source -Target $Destination | Out-Null
    Write-Host "Symlinked: $Source → $Destination" -ForegroundColor Green
}

# --- Chrome ---
Move-And-Symlink `
    -Source "$env:LOCALAPPDATA\Google\Chrome" `
    -Destination "E:\Applications\AppData\Local\Google\Chrome"

# --- Signal ---
Move-And-Symlink `
    -Source "$env:APPDATA\Signal" `
    -Destination "E:\Applications\AppData\Roaming\Signal"

Write-Host ""
Write-Host "Done. You can reopen Chrome and Signal." -ForegroundColor Green
