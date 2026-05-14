# Phase 2: First-run bootstrap for a fresh Windows machine.
# Prerequisites: Chrome installed with Proton Pass extension (Phase 1).
# Run from PowerShell (not admin):
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   irm https://raw.githubusercontent.com/JeremieLitzler/dotfiles/main/bootstrap.ps1 | iex

# --- Install Scoop to E:\Applications\Scoop ---
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    E:
    cd .\Applications\
    irm get.scoop.sh -OutFile install-scoop.ps1
    .\install-scoop.ps1 -ScoopDir 'E:\Applications\Scoop' -NoProxy
    Remove-Item install-scoop.ps1 -ErrorAction SilentlyContinue
}

# --- Install git (required for scoop buckets and chezmoi) ---
scoop install git

# --- Install chezmoi ---
scoop install main/chezmoi

# --- Install Proton Pass CLI ---
Invoke-WebRequest -Uri https://proton.me/download/pass-cli/install.ps1 -OutFile install-passcli.ps1
.\install-passcli.ps1
Remove-Item install-passcli.ps1 -ErrorAction SilentlyContinue
# Add pass-cli to current session PATH
$env:Path += ";$env:USERPROFILE\AppData\Local\Programs\ProtonPass"
[Environment]::SetEnvironmentVariable('Path', $env:Path + ";$env:USERPROFILE\AppData\Local\Programs\ProtonPass", 'User')

# --- Authenticate with Proton Pass ---
Write-Host ""
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "  Run 'pass-cli login' now and authenticate" -ForegroundColor Yellow
Write-Host "  Then press any key to continue..." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""
pause

# --- Init chezmoi and apply dotfiles ---
chezmoi init --apply JeremieLitzler/dotfiles
