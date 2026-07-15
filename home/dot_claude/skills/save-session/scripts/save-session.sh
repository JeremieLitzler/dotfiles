#!/usr/bin/env bash
# save-session.sh — archive the CURRENT Claude Code session as an HTML replay
# inside the "my-claude-conversations" repo, from ANY project directory.
#
# It will:
#   1. Locate the my-claude-conversations clone (D: then E:, under Git/GitHub).
#   2. Clone it there if it is missing (preferring D:, falling back to E:).
#   3. Discover this session's transcript from the current project's cwd.
#   4. Render the replay into <repo>/replays/<basename> via npx claude-replay.
#   5. Print REPO_ROOT= and REPLAY= so the caller knows where to write the
#      Markdown summary (<repo>/summaries/<same-slug>.md).
#
# Usage: bash save-session.sh <output-html> <title> <description>
#   <output-html>  file name or replays/<name>.html — only the basename is used
#   <title>        replay title (match the conversation's language)
#   <description>  link-preview description (same language)
#
# Requires Git Bash: `pwd -W` yields the Windows path Claude Code uses to name
# its per-project transcript directory under ~/.claude/projects/.
set -euo pipefail

output=${1:?usage: save-session.sh <output-html> <title> <description>}
title=${2:?missing <title>}
description=${3:?missing <description>}

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

# --- 3. discover this session's transcript from the current cwd ------------
# Encode the Windows cwd the way Claude Code names the transcript dir:
# every : / \ . becomes -
dir="$HOME/.claude/projects/$(pwd -W | sed 's#[:/\\.]#-#g')"
transcript=$(ls -t "$dir"/*.jsonl 2>/dev/null | head -1)

if [ -z "${transcript:-}" ]; then
  echo "No .jsonl transcript found in $dir" >&2
  exit 1
fi

# --- 4. render the replay into <repo>/replays/<basename> -------------------
mkdir -p "$repo/replays" "$repo/summaries"
outfile="$repo/replays/$(basename "$output")"
npx claude-replay "$transcript" -o "$outfile" --title "$title" --description "$description"

# --- 5. tell the caller where things landed --------------------------------
echo "REPO_ROOT=$repo"
echo "REPLAY=$outfile"
