#!/usr/bin/env bash
# locate-repo.sh — find (or clone) the "my-claude-conversations" repo, so the
# write-article skill can read summaries and write articles inside it from ANY
# project directory.
#
# It will:
#   1. Locate the my-claude-conversations clone (D: then E:, under Git/GitHub).
#   2. Clone it there if it is missing (preferring D:, falling back to E:).
#   3. Ensure the summaries/, summaries/article-written/, and articles/scheduled/
#      folders exist.
#   4. Print REPO_ROOT= so the caller knows where to read/write.
#
# Usage: bash locate-repo.sh
set -euo pipefail

REPO_NAME="my-claude-conversations"
REMOTE_URL="https://github.com/JeremieLitzler/my-claude-conversations.git"
# Candidate parents, in preference order — always <disk>/Git/GitHub.
CANDIDATES=(/d/Git/GitHub /e/Git/GitHub)

# --- 1. locate an existing clone -------------------------------------------
repo=""
for base in "${CANDIDATES[@]}"; do
  if [ -d "$base/$REPO_NAME/.git" ]; then
    repo="$base/$REPO_NAME"
    break
  fi
done

# --- 2. clone it if missing (first candidate whose disk exists) ------------
if [ -z "$repo" ]; then
  for base in "${CANDIDATES[@]}"; do
    disk=$(printf '%s' "$base" | cut -d/ -f2)   # d, e, ...
    if [ -d "/$disk" ]; then
      echo "Cloning $REPO_NAME into $base ..." >&2
      mkdir -p "$base"
      git clone "$REMOTE_URL" "$base/$REPO_NAME" >&2
      repo="$base/$REPO_NAME"
      break
    fi
  done
fi

if [ -z "$repo" ]; then
  echo "Could not locate or clone $REPO_NAME — no D: or E: disk available." >&2
  exit 1
fi

# --- 3. ensure the folders the skill reads/writes exist --------------------
mkdir -p "$repo/summaries/article-written" "$repo/articles/scheduled"

# --- 4. tell the caller where the repo lives -------------------------------
echo "REPO_ROOT=$repo"
