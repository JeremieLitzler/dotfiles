#!/usr/bin/env bash
set -euo pipefail

base="${1:-}"

if [[ -z "$base" ]]; then
  if git show-ref --verify --quiet refs/remotes/origin/develop; then
    base="develop"
  elif git show-ref --verify --quiet refs/remotes/origin/main; then
    base="main"
  else
    echo "Could not detect base branch (no origin/develop or origin/main). Pass one explicitly: refresh-from-develop.sh <branch>" >&2
    exit 1
  fi
fi

current_branch=$(git branch --show-current)

if [[ -z "$current_branch" ]]; then
  echo "Detached HEAD state; refusing to rebase." >&2
  exit 1
fi

if [[ "$current_branch" == "$base" ]]; then
  echo "Already on $base, nothing to refresh." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean. Commit or stash changes first." >&2
  exit 1
fi

echo "Fetching origin/$base..."
git fetch origin "$base"

echo "Rebasing $current_branch onto origin/$base..."
git rebase "origin/$base"
