# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A [chezmoi](https://www.chezmoi.io/) dotfiles repo for managing configuration across Windows and WSL/Linux. All managed files live under `home/` (the chezmoi source root, set via `.chezmoiroot`).

## Key chezmoi concepts used here

- `dot_*` → deployed with a `.` prefix (e.g. `dot_gitconfig` → `~/.gitconfig`)
- `executable_*` → deployed with execute permission
- `*.tmpl` → Go template processed at apply time; `{{ .osid }}` is `"windows"` or `"linux"`
- `run_once_*` → script runs once on first `chezmoi apply`
- `run_onchange_*` → script re-runs whenever the hash embedded in its comment changes

OS detection is driven by `.chezmoi.toml.tmpl`, which sets `.osid`. Platform-specific files are excluded via `home/.chezmoiignore`.

## Common commands

```powershell
# Preview changes before applying
chezmoi diff

# Apply all dotfiles and run pending scripts
chezmoi apply

# Edit a managed file (opens source, applies on save)
chezmoi edit ~/.gitconfig

# Add a new file to chezmoi management
chezmoi add <path>

# Re-run a run_once script (e.g. after editing it)
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## Repository layout

```
bootstrap.ps1          # Phase 2: fresh Windows machine bootstrap (run manually)
setup-symlinks.ps1     # Phase 4.2: move Chrome/Signal data to E:\ and symlink (run as Admin)
setup-wsl.ps1          # Phase 5: idempotent WSL Ubuntu installer (run as Admin)

home/                  # chezmoi source root (.chezmoiroot = "home")
  .chezmoi.toml.tmpl   # sets .osid and Proton Pass vault IDs
  .chezmoiignore       # excludes linux/* on Windows and windows/* on Linux
  dot_gitconfig.tmpl   # ~/.gitconfig — pulls git user/email from Proton Pass at apply time
  dot_claude/CLAUDE.md # deployed to ~/.claude/CLAUDE.md (the global Claude Code instructions)
  dot_config/mise/config.toml  # mise global tool versions (node, python, go, hugo)
  dot_local/bin/
    executable_update.sh       # Linux: mise self-update + RTK upgrade + npm update -g
    update_executables.ps1     # Windows: scoop update * + RTK re-download + npm update -g

  windows/             # Windows-only run_once scripts (ignored on Linux)
    run_once_01-scoop-apps.ps1.tmpl   # install Scoop buckets + apps
    run_once_02-registry-tweaks.ps1   # restore legacy Win11 right-click menu
    run_once_03-npm-globals.ps1       # install netlify-cli, claude-replay
    run_once_04-rtk-install.ps1       # download RTK binary to E:\rtk\bin\
    run_once_05-env-variables.ps1     # set CLAUDE_CODE_GIT_BASH_PATH, update PATH

  linux/               # Linux-only run_once scripts (ignored on Windows)
    run_once_01-install-mise.sh       # install mise + activate in .bashrc
    run_once_02-mise-tools.sh         # mise use --global for node/python/go/hugo
    run_once_03-npm-globals.sh        # install netlify-cli, claude-replay
    run_once_04-install-rtk.sh        # download RTK binary + rtk init -g hook
    run_onchange_02-mise-tools.sh     # re-runs when config.toml hash changes
```

## Secrets

Secrets (git name/email, WSL username) are pulled at `chezmoi apply` time via the `protonPass` template function — requires `pass-cli` to be installed and authenticated (`pass-cli login`). Never hard-code credentials; always use the `protonPass` template function or prompt the user.

## Adding a new managed tool

- **Windows**: add `scoop install <app>` to `home/windows/run_once_01-scoop-apps.ps1.tmpl`
- **Linux**: add `mise use --global <tool>@<version>` to `home/dot_config/mise/config.toml`; the `run_onchange_02-mise-tools.sh` will re-run automatically on next apply because the sha256 of `config.toml` is embedded in its header comment

## Script ordering

Scripts run in alphanumeric order. The numeric prefix (01–05) enforces dependency order: git must exist before scoop buckets, scoop apps before npm globals, etc. When adding a new `run_once` script, choose a prefix that respects these dependencies.
