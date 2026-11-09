Refresh the current branch by rebasing it onto the latest `develop` (or `main`, auto-detected) from `origin`.

Steps:

1. Run `bash ~/.claude/scripts/refresh-git-default-branch.sh` (pass a branch name as an argument to override auto-detection, e.g. `bash ~/.claude/scripts/refresh-git-default-branch.sh main`).
2. The script aborts safely if the working tree is dirty, HEAD is detached, or you're already on the base branch.
3. If the rebase stops on conflicts, resolve them, `git add` the resolved files, then `git rebase --continue`.
4. Report the resulting commit range (`git log --oneline -5`) and whether a force-push is needed on the remote tracking branch.
