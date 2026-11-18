"""PreToolUse hook (Bash): refuse git commit/push and shell file writes in a repo on main/master.

Exit 2 blocks the call and feeds stderr back to Claude. Anything unexpected lets it through.
"""
import json
import re
import subprocess
import sys

try:
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    cwd = data.get("cwd") or "."
except Exception:
    sys.exit(0)

cmd = re.sub(r"\d?>>?\s*(/dev/null|&\d)", "", cmd)  # harmless redirects
# git commit / push (with or without the rtk prefix, in chains), redirections, sed -i, tee.
risky = re.search(
    r"(^|[;&|]\s*|&&\s*)(rtk\s+)?git\s+(-C\s+\S+\s+)?(commit|push)\b"
    r"|(^|[^>])>>?\s*[^\s&|>]|\bsed\s+(-\w*i|--in-place)|\btee\b",
    cmd,
)
if not risky:
    sys.exit(0)
try:
    branch = subprocess.run(
        ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True, text=True, timeout=5,
    )
except Exception:
    sys.exit(0)

name = branch.stdout.strip()
if branch.returncode == 0 and name in ("main", "master"):
    print(
        f"Blocked: this command commits, pushes or writes files while the repo is on '{name}'. "
        f"Create a feature branch first: git checkout -b <type>/<issue>-<slug>.",
        file=sys.stderr,
    )
    sys.exit(2)
sys.exit(0)
