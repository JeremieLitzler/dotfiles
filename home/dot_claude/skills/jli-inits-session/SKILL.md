---
name: jli-inits-session
description: 'Create a new conversations/YYYY-MM-DD-slug/ folder in the "my-claude-conversations" repo with a README.md that opens with the user''s initial prompt (lightly cleaned) as the first heading (single-line prompt) or as standalone paragraphs (multi-line prompt), followed by a skeleton for the verified Q&A, conclusion and sources written during the session. Invoke as /jli-inits-session <prompt text>. Use whenever the user wants to record, keep or archive the prompt that starts a piece of work, or opens a new conversation folder from a prompt, even if they do not name the file.'
tools: Bash, Write, AskUserQuestion
---

# JLI inits session

The archive repo keeps one folder per piece of work, and the prompt that started it is the anchor a future session reads first. Keeping the prompt close to what the user typed matters because paraphrasing loses the intent and the constraints the user chose to state.

The folder holds a single file, `README.md`. It opens with the initial prompt, then records the session: the verified questions and answers, the final recommendation and one list of sources, filled in as the session goes.

## Steps

1. Take the skill argument as the prompt. If the argument is empty, ask the user for the prompt text instead of guessing one from the conversation. Apply only the light cleanup below.
2. Propose two kebab-case ASCII slugs of 2 to 6 words from the prompt's subject, in the prompt's language (`push-notification-strategy`, `strategie-notifications-push`). Make them genuinely different (e.g. one narrow, one broad) so the choice means something.
3. Human gate: ask the user to pick the slug with AskUserQuestion, one question, the two suggestions as options. The tool adds a free-text "Other" option automatically, so the user can type any slug they want. The slug becomes a folder name that is awkward to rename once linked, which is why the user decides it. Use the chosen or typed text as the slug; the locator normalises it.
4. Run the locator, which finds (or clones) the repo and creates `conversations/YYYY-MM-DD-<slug>/`:

   ```bash
   bash ~/.claude/skills/brainstorm/scripts/locate-brainstorm.sh "<slug>"
   ```

   Read `BRAINSTORM_DIR=` from its output. If `MODE=resume`, a folder with that slug already exists: if it already holds `README.md`, stop and tell the user rather than overwrite it.
5. Write `<BRAINSTORM_DIR>/README.md` with the Write tool (not a shell heredoc, which can mangle quotes and `$`), using the skeleton below with the cleaned prompt inserted.
6. Report the folder path and the file name in one or two lines. Do not commit; the user decides when.

## Light cleanup of the prompt

The prompt is cleaned lightly, never rewritten:

- Strip stray punctuation left by the invocation, such as a leading `: `.
- Fix typos and obvious grammar slips.
- Keep the user's wording, order, language, questions and constraints. Add nothing and drop no question or constraint.
- A multi-line prompt keeps its paragraph breaks, one paragraph per original paragraph.

## README.md skeleton

There is no "Questions and answers" heading in either form. `<prompt>` stands for the cleaned prompt.

**Single-line prompt:** it is the value of the first heading.

```markdown
# <prompt>

Only claims verified against primary sources are kept.
```

**Multi-line prompt:** a heading can't hold it, so the prompt is standalone paragraphs at the top, with no heading, blockquote, quotes or label.

```markdown
<prompt paragraph 1>

<prompt paragraph 2>

Only claims verified against primary sources are kept.
```

## Filling README.md during the session

Each question the user asks gets an entry appended to `README.md` when the user asks to save it, in the order asked, and the session ends with a conclusion and a sources list when the user asks for them.

- Heading `## Q<n>. <the question, reworded as a clear title>`, with the answer under it.
- Inside an answer, group content under `### **Label**` sub-headings (bold text inside an H3), for example `### **Key size limits**`.
- Keep only claims verified against primary sources (official documentation, specifications, vendor references). Drop any claim that could not be verified, including ones from memory or a search snippet that was not opened.
- Where a claim rests on a secondary page, say so in the sentence.
- When the sources are silent on something the user needs, add a `### **Not stated in the docs reviewed**` list naming the gaps instead of guessing.
- Close with `## Conclusion and recommendation`: one opening sentence with the recommendation, then bold-labelled bullets giving the reasons, and a last paragraph saying what to test before relying on it.
- Put a single `## Sources` section last: markdown links to the pages actually used, each listed once (deduplicate across all answers). Do not put a sources list under each answer.
- Follow the user's markdown rules: one line per paragraph or list item (no hard wrap), no arrow characters.
- Never edit the opening prompt (first heading or first paragraphs) afterwards. If the user's own edits to `README.md` differ from what the skill wrote, keep their version and do not restore the original.
