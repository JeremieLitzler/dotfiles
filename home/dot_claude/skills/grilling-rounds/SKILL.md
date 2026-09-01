---
name: grilling-rounds
description: Write each round of a grilling session to a GRILLING-ROUND-vXX.md file the user answers in their editor, instead of asking the questions in chat. Use whenever a grilling session starts — immediately after invoking `grilling`, `grill-me`, or `grill-with-docs`.
tools: Bash, Read, Write, AskUserQuestion
---

# Grilling Rounds

A grilling session records its rounds **in files**, never in chat. The user answers in their own editor, at their own pace, and the whole series is committed as the record of what was decided and why.

`grilling` shows a chat template ("Format a round like so: ❓ **Q1** …"). **Ignore it.** Its *method* — design tree, frontier, one round at a time, a recommendation on every question, finding facts yourself — is unchanged and governs everything below. Only the destination changes: rounds go to files, and the chat gets one line.

This skill is invoked **immediately after** `grilling`, in the same turn, before producing any output. It never invokes `grilling` itself, and it never chooses the grill variant — `/grill-me` or `/grill-with-docs` has already decided that by the time this runs.

## Setting up the session

Do this once, before writing round v01.

**1. Pick the destination.** Relative to the current repo root:

| Condition | Directory |
| --- | --- |
| `prompts/` exists | `prompts/YYYY-MM-DD-<slug>/` |
| else `docs/` exists | `docs/grillings/YYYY-MM-DD-<slug>/` |
| else | `grilling-sessions/YYYY-MM-DD-<slug>/` |

`YYYY-MM-DD` is the session's **start** date, fixed at v01 and never recomputed — even if the session resumes days later.

Outside a git repository, the destination is the `my-claude-conversations` archive instead. Locate it the way `save-session` does: look for the clone under `D:/Git/GitHub` or `E:/Git/GitHub`, cloning it there if missing. It has a `prompts/`, so rounds land in `<archive>/prompts/YYYY-MM-DD-<slug>/`.

**2. Derive the slug** from the conversation — the subject or feature being grilled, kebab-cased. Ask for it outright only when there is nothing to derive from.

**3. Confirm in one `AskUserQuestion` call** carrying two questions: the directory (all three options, detected one first) and the slug. Outside a repo there is nothing to choose, so drop the directory question and ask only the slug, stating the destination in it.

**4. If the chosen folder already exists** and contains `GRILLING-ROUND-*.md`, **resume it** — never create a new one. Read every round file in order, rebuild what is settled from the user's actual answers, and continue at the next number.

## Writing a round

One file per round: `GRILLING-ROUND-vNN.md`, zero-padded, starting at `v01`. **Never rewrite a round file** — the user's answers live in it.

Write it in **the language the user is writing in**, fixed at v01 and held for the whole session. Technical terms stay in English.

Each file carries, in this order:

1. `# Grilling round vNN — <subject>`
2. `## Settled in vNN-1` — what the previous round's answers closed, one line each. This is where the user catches a misread answer, so state the decision as you understood it, not just the option letter.
3. `## Reopened` — which earlier questions came back and why. Omit when empty.
4. The questions.

Each question takes this shape:

```markdown
## Q<n> - <title>

<body, including options as a lettered list where there are options>

➡️ Recommendation: <your recommended answer, with the reasoning that makes it a recommendation>

### Answer to Q<n>
```

Leave the answer heading empty. The user writes under it; everything from that heading to the next `##` or `---` is their answer, so they can use paragraphs, lists and code blocks freely.

**Numbering is continuous across the whole session** — v01 has Q1–Q4, v02 continues at Q5. Letter suffixes (`Q30`, `Q30b`) are reserved for a re-ask pair, so a question and the decision it reopens read as linked.

**One decision per question number. No question contains a second decision.** A related decision takes the next letter suffix — never a "Sub-decision:" paragraph tacked onto another question. A decision without its own answer slot does not get answered.

**Every question carries a `➡️ Recommendation:`**, confirmations included. No exceptions.

Then output **one line** in chat: the path, the question count, and how to resume. Nothing else — no question titles, no summary.

> Wrote `<path>/GRILLING-ROUND-v02.md` — 4 questions. Answer under each `### Answer to Q<n>` heading, save, then tell me you answered.

## When the user says they answered

Any message that plainly means "I answered" resumes the loop. There is no keyword.

**Re-read every `GRILLING-ROUND-*.md` in the folder**, in order, and rebuild the settled set from the user's answers themselves — not from your own `Settled` recaps, which are exactly what a misread answer is hiding in.

Then classify each answer:

- **Blank** — not an answer. Point back: "Q28 in v06 is blank." The user edits that file. **Never restate the question** in a new round.
- **Itself a question** ("SPI ?", "what if I… ?") — not settled. Answer it under its own new number, and re-ask the original decision under a **second** new number with its own answer slot. Answering without re-asking loses the decision.
- **Contradicts an earlier answer** — reopens that branch, **narrowed**. The contradiction already says which options died; restate only what is still live, naming what it eliminated and why.
- **Addresses a different decision than the one asked** — split it. Fold the volunteered content into whichever decision it actually bears on, reopening that one if it was settled; re-ask the unanswered question **verbatim** under a new number.
- **Settled** — record it in the next round's `Settled` section.

Recompute the frontier and write the next round file.

## With-docs sessions

When `grill-with-docs` ran, `domain-modeling` is active and produces ADRs and a glossary. Those are **in addition to** the round files, never a replacement: a round file records a decision *being made*, an ADR records it *once made*.

They live in different places. ADRs and `CONTEXT.md` go wherever `domain-modeling` normally puts them — the repo's own doc layout. The session folder holds only rounds and the summary, and links out to them. If the repo has no doc layout, say so and offer a fallback rather than inventing one.

## Ending

When the frontier is empty, write `GRILLING-SUMMARY.md` in the session folder **first**, in three parts:

1. **Prose restatement** of the shared understanding — what a reader needs six months later, including *why* things changed from the starting proposal.
2. **Decision index** — a flat list, one line per decision: the question number, the round it was settled in, and the decision. **Never a table**; column widths make it unreadable in a Markdown editor. Close it with a line naming which questions were superseded, and by what.
3. **A paste-ready section** for wherever the outcome belongs — the issue, the ticket, the PR — written in the user's voice, since they will paste it under their own name.

Flag anything that was never grilled but had to be decided to produce the artefact, so the user can object before it exists.

Then write the final round file with **one** question: does the summary match your understanding? Corrections edit `GRILLING-SUMMARY.md` in place and do not open a new round, unless a correction reopens a real decision.

The job ends there. Producing a spec, tickets, or the implementation is a separate ask — `to-spec`, `to-tickets` and `implement` exist for that. Name them as the next moves and stop.
