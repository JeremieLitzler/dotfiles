#!/bin/bash
# Managed by chezmoi — runs once on first apply.
# Installs global npm packages.

eval "$(~/.local/bin/mise activate bash)"

npm install -g netlify-cli
npm install -g claude-replay
