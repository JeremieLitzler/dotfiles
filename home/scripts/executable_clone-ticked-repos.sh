#!/usr/bin/env bash
# Clone every repo ticked ("- [x]") in ACTIVE-REPOS.md into $REPOS_DIR (default /e/Git/GitHub).
# Repos whose folder already exists are skipped.
set -euo pipefail

# Folder holding ACTIVE-REPOS.md and the clones. Override with REPOS_DIR.
REPOS_DIR="${REPOS_DIR:-/e/Git/GitHub}"
cd "$REPOS_DIR"

grep -iE '^- \[x\] \[' ACTIVE-REPOS.md \
  | sed -E 's/^- \[[xX]\] \[([^]]+)\].*/\1/' \
  | while read -r repo; do
      name="${repo#*/}"
      if [ -d "$name" ]; then
        echo "skip  $repo (already cloned)"
      else
        echo "clone $repo"
        git clone "https://github.com/$repo.git" "$name"
      fi
    done
