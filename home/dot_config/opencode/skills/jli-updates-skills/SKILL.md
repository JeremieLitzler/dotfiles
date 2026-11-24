---
name: jli-updates-skills
description: 'Update the globally installed skills managed by the `skills` CLI (the Matt Pocock skills in ~/.agents/skills). Asks whether to update all, some, or none. Use when the user wants to update, refresh or upgrade their installed skills, even if they do not name the CLI.'
---

# JLI updates skills

Skills here are installed with `npx skills@latest` into `~/.agents/skills`; the state is in `~/.agents/.skill-lock.json`. Never edit files inside `~/.agents/skills`: an update overwrites them.

## Steps

1. Ask with the `question` tool, one question per call: **1. How do you want to update skills?**
   - A) `Yes, all`
   - B) `Not all`
   - C) `None`
2. `Yes, all`: run `npx --yes skills@latest update -g -y`.
3. `Not all`: list the installed skills with `npx --yes skills@latest list -g 2>&1 | grep -E "^  [a-z]"` (the first token of each line is the name; ignore the `SKILLS_SKILL_SKIPPED` warnings), ask which to update with the `question` tool and `multiple` selection, then run `npx --yes skills@latest update <name> <name> -g -y`.
4. `None`: do nothing and say so.
5. After an update, run `npx --yes skills@latest list -g 2>&1 | grep -E "^  [a-z]"` and report which skills were touched. Remind the user that `~/.agents/skills` is not stored in chezmoi and that nothing needs re-saving.
