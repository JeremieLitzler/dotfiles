#!/bin/bash
# Managed by chezmoi — runs once on first apply.
# Installs global tool versions via mise.

eval "$(~/.local/bin/mise activate bash)"

mise use --global node@lts
mise use --global python@latest
mise use --global go@latest
mise use --global hugo@latest
