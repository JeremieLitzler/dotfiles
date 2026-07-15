---
name: save-session
description: Archive the current Claude Code session as an HTML replay plus a Markdown summary in the "my-claude-conversations" repo. Works from ANY project — locates the archive clone under D:/Git/GitHub or E:/Git/GitHub, cloning it first if it is missing. Use when the user asks to save, archive, or record the current session.
tools: Bash, Read, Write
---

# Save Session

Archive the current Claude Code session as an HTML replay plus a Markdown
summary. The archive lives in the `my-claude-conversations` repo; this skill
works from **any** project by locating (or cloning) that repo automatically.

## Naming

Both files use `YYYY-MM-DD-slug.{html,md}` — today's date plus a kebab-cased
slug derived from a title for the session.

## Steps

1. Generate a title from the conversation. Confirm with the human or use their
   chosen title.
2. Derive a kebab-case `slug` from the title.
3. Render the replay by running the wrapper script — **one** command, so the
   human sees only **one** permission request. Do NOT inline discovery + replay
   as separate calls.

   ```bash
   bash ~/.claude/skills/save-session/scripts/save-session.sh "YYYY-MM-DD-slug.html" "<title>" "<description>"
   ```

   - The script locates the `my-claude-conversations` clone under
     `D:/Git/GitHub` or `E:/Git/GitHub`, and **clones it there if
     it is missing**.
   - It encodes the current dir the way Claude Code names its transcript folder
     (`~/.claude/projects/<encoded-cwd>/`, every `:` `/` `\` `.` → `-`), picks
     the most recently modified `.jsonl`, and passes it to `npx claude-replay`
     with `-o`, `--title`, `--description`.
   - Only the **basename** of the first argument is used; the replay always
     lands in `<repo>/replays/`.
   - Fill in the `YYYY-MM-DD-slug` filename, `<title>`, and `<description>`
     **before** running — nothing needs inspecting mid-command.
   - The script prints `REPO_ROOT=<path>` and `REPLAY=<path>` on success. Use
     `REPO_ROOT` to place the summary in the next step.
   - `--title` / `--description` must follow the conversation's language.

4. Write the summary to `<REPO_ROOT>/summaries/YYYY-MM-DD-slug.md` (using the
   `REPO_ROOT` printed by the script).

   - Write the summary in the **same language the human used in the
     conversation** (French → French, English → English, …). Only structural
     scaffolding may stay as-is; the prose matches the conversation's language.

5. Leave committing/pushing to the human unless they ask — mention the two new
   files and the repo path.
