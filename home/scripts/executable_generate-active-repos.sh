#!/usr/bin/env bash
# Generate $REPOS_DIR/ACTIVE-REPOS.md (default /e/Git/GitHub): the 100 owned repos (forks excluded) with the most
# recent pushes, as a checkbox list. Ticks from an existing ACTIVE-REPOS.md are kept.
set -euo pipefail

# Folder holding ACTIVE-REPOS.md and the clones. Override with REPOS_DIR.
REPOS_DIR="${REPOS_DIR:-/e/Git/GitHub}"
cd "$REPOS_DIR"
out="ACTIVE-REPOS.md"

# Repos already ticked in the current file, to keep their tick.
ticked=""
if [ -f "$out" ]; then
  ticked=$(grep -iE '^- \[x\] \[' "$out" | sed -E 's/^- \[[xX]\] \[([^]]+)\].*/\1/' || true)
fi

{
  echo "# Active repos"
  echo
  echo "Top 100 owned repos (forks excluded), sorted by last push date. Check the ones to clone."
  echo

  gh repo list --source --limit 1000 \
    --json nameWithOwner,description,pushedAt,isPrivate,isArchived \
    --jq 'sort_by(.pushedAt) | reverse | .[:100][]
          | [.nameWithOwner, .pushedAt[:10], .isPrivate, .isArchived, ((.description // "") | gsub("[\n\t]"; " ") | gsub("^ +| +$"; ""))]
          | @tsv' \
  | while IFS=$'\t' read -r repo pushed private archived desc; do
      name="${repo#*/}"

      tags=()
      [ "$private" = "true" ] && tags+=("private")
      [ "$archived" = "true" ] && tags+=("archived")
      [ -d "$name" ] && tags+=("already cloned")
      tag=""
      [ ${#tags[@]} -gt 0 ] && tag=" ($(IFS=,; echo "${tags[*]}" | sed 's/,/, /g'))"

      box=" "
      grep -qxF "$repo" <<< "$ticked" && box="x"

      line="- [$box] [$repo](https://github.com/$repo) - $pushed$tag"
      [ -n "$desc" ] && line="$line: $desc"
      echo "$line"
    done
} > "$out.tmp"

mv "$out.tmp" "$out"
echo "Wrote $out"
