---
name: jli-adds-skill
description: 'Add a skill globally with the `skills` CLI, from a GitHub owner/repo, a URL or a local path, installed for OpenCode into ~/.agents/skills. Use when the user wants to add, install or import a skill, even if they do not name the CLI.'
---

# JLI adds skill

## Steps

1. Ask with the `question` tool, one question per call: **1. What do you need to add? Provide name, URL or path.**
   - A) `Yes`
   - B) `No`
2. `No`: do nothing and say so.
3. `Yes`: ask for the skill name (or `*` for every skill of the source) and for the source (GitHub `owner/repo`, URL or local path). If the user does not know the skill name, run `npx --yes skills@latest add <source> --list` and ask which of the listed skills to take.
4. Show the exact command and run it: `npx --yes skills@latest add <source> -g -a opencode -y --copy -s <name>`. `--copy` avoids symlinks on Windows; `-g` installs at user level.
5. The installer warns that skills run with full agent permissions. Relay that warning and suggest reading the `SKILL.md` of a skill from an unknown source before first use.
6. Report the result with `npx --yes skills@latest list -g 2>&1 | grep -E "^  [a-z]"`. Many Matt Pocock skills use `disable-model-invocation: true`, so say they are started with `@<name>`.
