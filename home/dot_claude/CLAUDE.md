# Main CLAUDE.md

## About assumptions

NEVER assume anything and ask questions to the human to make the intent is understood.

Number each question, letter each option, and name the subject inside every question (no bare "it").

## About "→"

- NEVER use "→" in generated text. Use the regular ">" character.
- NEVER use "←" in generated text. Use the regular "<" character.
- NEVER use "↔" in generated text. Use the regular "<>" characters.

## About horizontal rules ("---")

NEVER put `---` between paragraphs or sections in generated markdown. Azure DevOps wikis render a `---` that directly follows a text line as a level 2 heading, so separators break the wiki copy of the document. Use headings to separate sections. Leave YAML front matter and fenced code blocks exactly as authored.

## About line wrapping

No hard-wrap markdown prose at ~80 characters. Write each paragraph, list item, table row, and blockquote line as ONE line and let the editor soft-wrap. Leave fenced code blocks (including mermaid) exactly as authored.

<!-- rtk-instructions v2 -->

## RTK

Prefix every `git` and `gh` command with `rtk`, in chains too: `rtk git add . && rtk git commit -m "msg"`.

Known `rtk` quirks:

- Read comments with `rtk gh issue view N --json title,body,comments` because `rtk gh issue view N --comments` doesn't work.
- `rtk git commit` may exit 128 with "fatal: Needed a single revision" although the commit worked. When the output prints the new commit hash, treat it as noise.

<!-- /rtk-instructions -->

# grilling-rounds

Found (`~/.claude/skills/grilling-rounds/SKILL.md`) writes a grilling session's rounds go to files, not chat.

Any grilling session records its rounds in files, never in chat. Immediately after invoking `mattpocock-skills:grilling` — directly, or via `/grill-me` or `/grill-with-docs` — invoke the Skill tool with `skill: "grilling-rounds"`, before producing any output.

## About "reporter" (carrying over)

When the user says "reporter" (carry over) actions, questions or any item from one document to another, it means CUT and PASTE: move the full text to the destination AND delete it from the source. NEVER duplicate it. If the source needs a trace, ask first.
