---
name: register-matt-pocock-repo
description: Add the current repo to the catalog README of the "where-do-i-use-matt-pocock-skills" repo when it starts using Matt Pocock's skillset. Use whenever a `mattpocock-skills:*` skill is invoked (including `mattpocock-skills:setup-matt-pocock-skills`) in a repo not yet listed. Locates the catalog clone under D:/Git/GitHub or E:/Git/GitHub, cloning it first if missing.
tools: Bash, Read, Edit
---

# Register Matt Pocock Repo

The catalog lives in the `where-do-i-use-matt-pocock-skills` repo (`JeremieLitzler/where-do-i-use-matt-pocock-skills`). Its `README.md` is a flat list, one line per repo that uses Matt Pocock's skills. This skill adds the **current repo** to that list.

It is invoked **after** a `mattpocock-skills:*` skill, in the same turn. It never invokes those skills itself, and it never changes the repo the user is working in.

## 1. Identify the current repo

Run `git remote get-url origin` in the working directory. Stop silently, with no output, when:

- the directory is not a git repository, or has no `origin`;
- `origin` is not on GitHub;
- the repo is the catalog repo itself.

Derive `<owner>/<name>` from the URL (strip `.git`, accept HTTPS and SSH forms). The entry is:

```markdown
- [<name>](https://github.com/<owner>/<name>)
```

## 2. Locate the catalog clone

Look for `where-do-i-use-matt-pocock-skills` under `D:/Git/GitHub`, then `E:/Git/GitHub`. If neither has it, clone `https://github.com/JeremieLitzler/where-do-i-use-matt-pocock-skills` into whichever of those directories exists (`D:` first).

Work from that clone for every step below, using `git -C <clone>`.

## 3. Check before changing

1. `git -C <clone> status --porcelain`. When it is not empty, **stop** and tell the user the clone has uncommitted changes. Never stash, reset or discard them.
2. `git -C <clone> fetch origin`, then check out `main` and fast-forward it to `origin/main`.
3. Read `README.md`. When a line already links to `github.com/<owner>/<name>`, the repo is registered: say so in one line and stop. A later call is a no-op, so this skill is safe to run after every `mattpocock-skills:*` invocation.

## 4. Add the entry

Branch from the up-to-date `main`: `docs/register-<name>`.

Insert the entry in the list at its alphabetical position, comparing names **case-insensitively**. Do not reorder the other lines, do not touch the intro paragraph, and keep each item on one line.

## 5. Commit and push

Commit with the message `docs: register <name>`, ending with the attribution lines the session context gives for commits. Push with `git push -u origin docs/register-<name>`.

`main` only moves through a merged pull request, so **stop after the push**. Do not open or merge the PR unless the user asks; name `open-pr` as the next move.

## Reporting

One line in chat: the repo registered, the branch pushed, and the catalog path. Nothing else.

> Registered `<name>` in `<clone>/README.md` on `docs/register-<name>` and pushed it. Open a PR to merge it into `main`.
