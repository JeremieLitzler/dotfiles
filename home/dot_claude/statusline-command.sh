#!/usr/bin/env bash
# Claude Code status line
# Shows: current directory, git branch, model name, context usage

input=$(cat)

# --- Current directory (basename only) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
dir_name=$(basename "$cwd")

# --- Git branch (skip optional locks, silent if not a repo) ---
branch=""
if [ -n "$cwd" ]; then
  branch=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# --- Model display name ---
model=$(echo "$input" | jq -r '.model.display_name // empty')

# --- Context usage percentage ---
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_label=""
if [ -n "$used" ] && [ "$used" != "null" ]; then
  ctx_label="$(printf '%.0f' "$used")% ctx"
fi

# --- Colors (dim-friendly ANSI codes) ---
RESET="\033[0m"
DIR_COLOR="\033[2;36m"    # dim cyan
GIT_COLOR="\033[2;32m"    # dim green
MODEL_COLOR="\033[2;35m"  # dim magenta
CTX_COLOR="\033[2;33m"    # dim yellow
SEP="\033[2m|\033[0m"

output="${DIR_COLOR}${dir_name}${RESET}"

if [ -n "$branch" ]; then
  output="${output} ${SEP} ${GIT_COLOR}${branch}${RESET}"
fi

if [ -n "$model" ]; then
  output="${output} ${SEP} ${MODEL_COLOR}${model}${RESET}"
fi

if [ -n "$ctx_label" ]; then
  output="${output} ${SEP} ${CTX_COLOR}${ctx_label}${RESET}"
fi

printf '%b\n' "$output"
