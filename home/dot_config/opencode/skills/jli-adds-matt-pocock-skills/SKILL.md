---
name: jli-adds-matt-pocock-skills
description: 'Install the 18 Matt Pocock skills used on this machine from github.com/mattpocock/skills into ~/.agents/skills for OpenCode. Use on a fresh machine or when those skills are missing, because ~/.agents/skills is not stored in chezmoi.'
---

# JLI adds Matt Pocock skills

`~/.agents/skills` is not stored in chezmoi because it changes at every `npx skills update`. This skill is the record of which skills to install.

## Skills installed on 2026-11-24

ask-matt, code-review, codebase-design, diagnosing-bugs, domain-modeling, grill-with-docs, grilling, implement, improve-codebase-architecture, pr, prototype, research, retro, setup-matt-pocock-skills, tdd, wayfinder, wizard, writing-for-agents.

Started only with `@<name>` (they set `disable-model-invocation: true`): ask-matt, grill-with-docs, implement, improve-codebase-architecture, retro, wayfinder, setup-matt-pocock-skills.

## Steps

1. List what is already installed with `npx --yes skills@latest list -g 2>&1 | grep -E "^  [a-z]"` (ignore the `SKILLS_SKILL_SKIPPED` warnings) and tell the user which of the 18 are missing. If none is missing, say so and stop.
2. Show the command and ask one confirmation with the `question` tool before running it.
3. Run, with only the missing names in `-s` (all 18 on a fresh machine):

   ```sh
   npx --yes skills@latest add mattpocock/skills -g -a opencode -y --copy -s ask-matt code-review codebase-design diagnosing-bugs domain-modeling grill-with-docs grilling implement improve-codebase-architecture pr prototype research retro setup-matt-pocock-skills tdd wayfinder wizard writing-for-agents
   ```

4. The installer warns that skills run with full agent permissions. Relay that warning.
5. Report the result with the same list command. To update or remove later, use `@jli-updates-skills` or `@jli-removes-skill`.
