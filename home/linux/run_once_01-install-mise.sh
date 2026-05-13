#!/bin/bash
# run_once_01-install-mise.sh
# Managed by chezmoi — runs once on first apply.
# Installs mise and adds activation to shell profile.

if ! command -v mise &> /dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
fi

# Add mise activation to .bashrc if not already present
if ! grep -q 'mise activate bash' ~/.bashrc; then
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
fi
