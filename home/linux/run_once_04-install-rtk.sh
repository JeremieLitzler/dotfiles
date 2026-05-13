#!/bin/bash
# Managed by chezmoi — runs once on first apply.
# Downloads latest RTK Linux binary and installs the auto-rewrite hook.

# Get latest release URL for Linux amd64
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/rtk-ai/rtk/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*linux.*amd64[^"]*"' \
    | head -1 \
    | cut -d'"' -f4)

if [ -n "$DOWNLOAD_URL" ]; then
    mkdir -p ~/.local/bin
    curl -fsSL "$DOWNLOAD_URL" -o ~/.local/bin/rtk
    chmod +x ~/.local/bin/rtk

    # Install the PreToolUse auto-rewrite hook
    ~/.local/bin/rtk init -g
fi
