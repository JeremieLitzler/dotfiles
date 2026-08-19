#!/usr/bin/env bash
# locate-brainstorm.sh — find (or clone) the "my-claude-conversations" repo and
# open the brainstorming folder for a subject, so the `brainstorm` skill works
# from ANY project directory.
#
# It will:
#   1. Locate the my-claude-conversations clone. Search order depends on the OS:
#        Windows (git bash) : /d/Git/GitHub, /e/Git/GitHub, $HOME
#        Linux / macOS      : $HOME, $HOME/Git/GitHub, $HOME/git
#      $BRAINSTORM_REPO overrides everything when set.
#   2. Clone it into the first candidate whose filesystem root exists.
#   3. Reuse prompts/*-<slug>/ if such a folder already exists (resume mode),
#      otherwise create prompts/YYYY-MM-DD-<slug>/ (new mode).
#   4. Print REPO_ROOT=, BRAINSTORM_DIR=, MODE=, and — in resume mode — an
#      inventory of what is already in the folder.
#
# Usage: bash locate-brainstorm.sh "<kebab-case-slug>"
set -euo pipefail

REPO_NAME="my-claude-conversations"
REMOTE_URL="https://github.com/JeremieLitzler/my-claude-conversations.git"

# Candidate PARENT directories, in preference order. On Windows the repo lives
# on a data disk; on Linux/macOS it sits in the home directory.
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    CANDIDATES=(/d/Git/GitHub /e/Git/GitHub "$HOME/Git/GitHub" "$HOME") ;;
  *)
    CANDIDATES=("$HOME" "$HOME/Git/GitHub" "$HOME/git" "$HOME/Projects") ;;
esac

slug="${1:-}"
if [ -z "$slug" ]; then
  echo "Usage: bash locate-brainstorm.sh \"<kebab-case-slug>\"" >&2
  exit 2
fi
# Normalise: transliterate accents (é -> e, not a dash), lowercase, everything
# that is not [a-z0-9-] becomes a dash, squeeze and trim dashes.
# iconv//TRANSLIT renders é as 'e in the C locale, hence the quote/accent purge
# BEFORE the dash substitution — otherwise "préparation" becomes "pr-eparation".
slug=$(printf '%s' "$slug" | { iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || cat; })
slug=$(printf '%s' "$slug" \
  | tr -d "'\`^~\"" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9-]\+/-/g' -e 's/--\+/-/g' -e 's/^-//' -e 's/-$//')
if [ -z "$slug" ]; then
  echo "Slug is empty after normalisation — pass a kebab-case ASCII slug." >&2
  exit 2
fi

# --- 1. locate an existing clone -------------------------------------------
repo=""
if [ -n "${BRAINSTORM_REPO:-}" ]; then
  # Explicit override — must already be a clone, we do not guess around it.
  if [ -d "$BRAINSTORM_REPO/.git" ]; then
    repo="$BRAINSTORM_REPO"
  else
    echo "BRAINSTORM_REPO=$BRAINSTORM_REPO is not a git clone." >&2
    exit 1
  fi
else
  for base in "${CANDIDATES[@]}"; do
    if [ -d "$base/$REPO_NAME/.git" ]; then
      repo="$base/$REPO_NAME"
      break
    fi
  done
fi

# --- 2. clone it if missing (first candidate whose root exists) ------------
if [ -z "$repo" ]; then
  for base in "${CANDIDATES[@]}"; do
    # Only the filesystem root has to exist (/d, /home, …); the intermediate
    # Git/GitHub levels are created below.
    root="/$(printf '%s' "$base" | sed 's|^/||' | cut -d/ -f1)"
    if [ -d "$root" ]; then
      echo "Cloning $REPO_NAME into $base ..." >&2
      mkdir -p "$base"
      git clone "$REMOTE_URL" "$base/$REPO_NAME" >&2
      repo="$base/$REPO_NAME"
      break
    fi
  done
fi

if [ -z "$repo" ]; then
  echo "Could not locate or clone $REPO_NAME. Tried: ${CANDIDATES[*]}" >&2
  echo "Set BRAINSTORM_REPO=/path/to/$REPO_NAME to point at it explicitly." >&2
  exit 1
fi

mkdir -p "$repo/prompts"

# --- 3. reuse an existing folder for this slug, else create today's --------
dir=""
for candidate in "$repo/prompts"/*-"$slug"; do
  if [ -d "$candidate" ]; then
    dir="$candidate"
    break
  fi
done

if [ -n "$dir" ]; then
  mode="resume"
else
  mode="new"
  dir="$repo/prompts/$(date +%Y-%m-%d)-$slug"
  mkdir -p "$dir"
fi

# --- 4. tell the caller where things are ----------------------------------
echo "REPO_ROOT=$repo"
echo "BRAINSTORM_DIR=$dir"
echo "MODE=$mode"

if [ "$mode" = "resume" ]; then
  echo "--- existing contents ---"
  # Top level only; directories are summarised by entry count so a raw-data
  # folder holding 76 weekly exports does not drown the listing.
  for entry in "$dir"/*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    if [ -d "$entry" ]; then
      n=$(find "$entry" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
      echo "$name/ ($n entries)"
    else
      echo "$name"
    fi
  done | sort
fi
