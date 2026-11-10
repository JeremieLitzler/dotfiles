"""PreToolUse hook: refuse file edits inside a git repo whose current branch is main/master.

Exit 2 blocks the tool call and feeds stderr back to Claude. Anything unexpected
(no path, not a repo, git error, detached HEAD) lets the call through.
"""
import json
import os
import subprocess
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

inp = data.get("tool_input") or {}
path = inp.get("file_path") or inp.get("notebook_path")
if not path:
    sys.exit(0)

path = os.path.abspath(path)
if f"{os.sep}.git{os.sep}" in path:
    sys.exit(0)  # scratch files under .git/ (PR bodies) never get committed

d = os.path.dirname(path)
while d and not os.path.isdir(d):
    parent = os.path.dirname(d)
    if parent == d:
        sys.exit(0)
    d = parent

try:
    branch = subprocess.run(
        ["git", "-C", d, "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True, timeout=5,
    )
except Exception:
    sys.exit(0)

if branch.returncode == 0 and branch.stdout.strip() in ("main", "master"):
    name = branch.stdout.strip()
    print(
        f"Blocked: {path} is in a git repo on '{name}'. "
        f"Create a feature branch first: git checkout -b <type>/<issue>-<slug> "
        f"(e.g. docs/11-data-commit-messages), then retry the edit.",
        file=sys.stderr,
    )
    sys.exit(2)
sys.exit(0)
