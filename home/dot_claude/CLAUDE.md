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

<!-- /rtk-instructions -->
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# grilling-rounds
- **grilling-rounds** (`~/.claude/skills/grilling-rounds/SKILL.md`) - a grilling session's rounds go to files, not chat.
Any grilling session records its rounds in files, never in chat. Immediately after invoking `mattpocock-skills:grilling` — directly, or via `/grill-me` or `/grill-with-docs` — invoke the Skill tool with `skill: "grilling-rounds"`, before producing any output.

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

## About "reporter" (carrying over)

When the user says "reporter" (carry over) actions, questions or any item from one document to another, it means CUT and PASTE: move the full text to the destination AND delete it from the source. NEVER duplicate it. If the source needs a trace, ask first.
