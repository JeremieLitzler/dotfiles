---
name: close-pr
description: Merge an open pull request once CI is green, then clean up the local repo - sync main, delete the merged branch, prune stale remote refs, sweep other merged local branches, and confirm the linked issue closed. Use whenever the user says to merge a PR, close a PR, "CI is passing so merge", refresh main after a merge, or clean up local branches, even if they only name one of these steps.
---

# close-pr

Merge a pull request and leave the local repo clean. The user invoking this skill is the go-ahead to merge, so do not ask again, but a PR whose CI is not green is not ready: stop and say what failed.

Prefix commands with `rtk` where the user's global instructions call for it.

## 1. Find the PR and check CI

Use the PR number the user gave. Without one, use the PR of the current branch (`gh pr view --json number,state,headRefName`). If none or several match, ask.

```bash
gh pr view <n> --json state,headRefName,mergeable
gh pr checks <n>
```

The merge happens only when CI is green: every check reports `pass` (skipped checks do not count against it). Treat anything else as not green and stop without merging:

- a check that is failing, cancelled or still pending (it will finish on its own, so report that rather than merging over it);
- no checks reported at all (`gh pr checks` says none): ask the user rather than assume green;
- a PR that is not open or not mergeable.

Say which check blocked the merge, with its link. Never work around it: no `--admin`, no `--auto` (which merges later without re-checking), and no re-running a failed check to get a pass unless the user asks.

## 2. Merge

Only after step 1 found CI green.

```bash
gh pr merge <n> --rebase --delete-branch
```

Rebase is the default because that is how this user's repos keep a linear history. Use `--squash` or `--merge` only when the user names one. `--delete-branch` removes the remote branch and, when run from that branch, the local one.

## 3. Clean up locally

```bash
git checkout main && git pull
git fetch --prune
```

Use the repo's default branch if it is not `main` (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`). The pull fast-forwards, because a rebase merge puts new commits on the remote's main. Pruning drops the remote-tracking refs for branches that no longer exist on origin.

Delete the branch that was merged if it is still there, with the safe form so unmerged work is never lost:

```bash
git branch -d <headRefName>
```

A rebase merge rewrites the commits, so `-d` may refuse a branch that is in fact merged. Check `gh pr view <n> --json state` says `MERGED` before using `-D` on that one branch, and nothing else.

## 4. Sweep other merged branches

```bash
git branch --merged main
```

List every branch other than main and the current one, show the list to the user, and delete only after they confirm. Rebase merges make `--merged` miss branches whose PRs landed, so also list local branches whose upstream is gone (`git branch -vv` marks them `: gone]`), labelled separately, and ask about those too. Never delete a branch the user did not see listed.

## 5. Confirm the issue closed

If the PR body or commits say `Closes #N`, run `gh issue view <n> --json state -q .state` and report it. If it is still open, say so; do not close it yourself.

## Report

End with: the PR state, the new tip of main (`git log --oneline -1`), the branches deleted, and the issue state. Keep it to a few lines.
