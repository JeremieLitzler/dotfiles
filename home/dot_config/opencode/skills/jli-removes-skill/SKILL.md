---
name: jli-removes-skill
description: 'Remove globally installed skills managed by the `skills` CLI. Lists the installed skills and asks which to remove. Use when the user wants to remove, uninstall or delete an installed skill, even if they do not name the CLI.'
---

# JLI removes skill

## Steps

1. List the installed skills with `npx --yes skills@latest list -g 2>&1 | grep -E "^  [a-z]"` (ignore the `SKILLS_SKILL_SKIPPED` warnings).
2. Ask which to remove with the `question` tool and `multiple` selection, numbered: **1. Which skills do you want to remove?** Include a `None` option.
3. `None`: do nothing and say so.
4. Show the chosen names and ask for one confirmation before deleting.
5. Run `npx --yes skills@latest remove -g -s <name> <name> -y`.
6. Report the remaining skills with the same list command.
