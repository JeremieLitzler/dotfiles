#!/bin/bash
# Managed by chezmoi — re-runs when config.toml changes.
# config.toml hash: {{ include "dot_config/mise/config.toml" | sha256sum }}

eval "$(~/.local/bin/mise activate bash)"
mise install
