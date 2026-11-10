Create a pull request from the current branch after evaluating its contents with the human. Merging is `/close-pr`.

**Usage:** `/open-pr`

Aborts if the current branch is `main`.

## Step 1 — Verify branch

Run:

```bash
rtk git status
```

If the current branch is `main`, stop and tell the user: "Already on main — check out a feature branch first."

## Step 2 — Evaluate commits

Run in parallel:

```bash
rtk git log main..HEAD
rtk git diff main...HEAD
```

From these, extract:

- **Commits**: list of subject lines (most recent first)
- **Files changed**: list with a one-line summary of what changed in each
- **Overall purpose**: one sentence describing what this branch achieves

Present the evaluation to the user in this format:

```plaintext
Branch: <branch-name>
Commits (<N>):
  - <subject>
  - …

Files changed:
  - <file> — <what changed>
  - …

Summary: <one-sentence purpose>
```

Take the issue number from the branch name (`docs/8-state-management` gives #8) and add to the evaluation: `Issue link: Closes #N or Refs #N?`. With no number in the branch name, ask which issue, if any.

## Step 3 — Human review: pre-check PR to create

Wait for explicit approval or corrections, including the issue link keyword, before proceeding to Step 4. Apply any changes the user requests to the draft title/body.

## Step 4 — Create the pull request

Derive a PR title from the branch commits (use the evaluation summary if a single-commit branch, otherwise synthesize from all subjects).

Run:

```bash
rtk gh pr create \
  --title "<derived title>" \
  --body "$(cat <<'EOF'
## Summary

- <bullet per logical change, drawn from the commit list>

## Files changed

- `<file>` — <what changed>

## Test plan

- [ ] <checks derived from the diff>

<Closes|Refs> #N

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Report the PR URL to the user and stop. Merging is `/close-pr`.
