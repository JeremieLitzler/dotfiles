---
name: jli-summarize-article
description: Summarize an article the user has read into a "### Key point" paragraph plus a "### Checklist" of actionable `- [ ]` items, written so the summary revives the reader's memory of the article later. When a summary file is given (usually under D:\main-database\summaries), insert the result under its `# Summary` heading and also show it in chat; otherwise answer in chat only. Use whenever the user pastes an article (often between <article> tags) and asks to summarize it, asks for "the key point and a checklist", or asks to add/update a summary in a file in main-database, even if they do not name this skill.
---

# Summarize an article for later recall

The user reads self-improvement, productivity and investing articles and keeps notes files where the summary sits above the full article text. They come back weeks later and read the summary first. So the summary's job is not to replace the article: it is a set of cues that bring back what they read, plus the actions they meant to take.

The guidance below comes from the research in `E:\Git\GitHub\my-claude-conversations\conversations\2026-11-02-memory-reviving-summaries\README.md`. Read it only if you need the reasoning behind a rule.

## Inputs

- **The article**: pasted in the message, often wrapped in `<article>` or pasted-content tags.
- **A target file** (optional): a path such as `@D:\main-database\summaries\<slug>.md`. These files usually look like a tag line (`#personal_development`), an empty `# Summary` heading, then `# Article` with the URL, a cover image and the full text.

If a target file is given, read it first. The file often holds a fuller version of the article than the paste (the paste can be cut off mid-section). Summarize the most complete version you have, and tell the user if the paste was truncated.

## Output format

```markdown
### Key point

<one paragraph>

### Checklist

- [ ] <action>
- [ ] <action>
```

Use exactly these two `###` headings. Write each paragraph and each list item as one line (no hard wrapping), and never use arrow characters (write ">" instead).

### Key point

Two to five plain sentences. Keep it short enough that the reader can glance at it and try to recall the rest before looking at the checklist or the article: trying to recall is what makes the review work, rereading alone does little.

- Start with the article's central claim and the author's own reason for it, in your words rather than quotes. Meaning outlasts wording in memory, and copied sentences cue the wording, not the idea.
- Cover the main recommendations the article makes, because points left out of the summary tend to fade from memory.
- Keep one or two of the author's distinctive details in the author's own terms: a named rule ("90/10 rule"), a number ("about 12 quarters"), a personal anecdote (wrote the first book at 28), a quoted line ("go fishing"). Attach each to the point it illustrates. These details are what make this article different from every similar article the user has read, so they are the strongest recall cues.
- Refer to the writer as "the author" or by name, and use they/them for them.

### Checklist

- One item per distinct recommendation in the article. There is no target count: a short article may give 8 items, a long how-to 25.
- Each item is a concrete imperative action. When the article gives a trigger or a moment, put it in the item ("When a new idea shows up, write it down for later"; "Before buying, decide the maximum position size"). Plans phrased as "when X, do Y" are the ones people actually carry out.
- Keep the author's specifics in the items (percentages, durations, thresholds, examples), so the checklist is usable without rereading.
- Leave out vague items that would fit any article ("stay motivated") and colorful details that carry no lesson.
- Add nothing the author did not say: no extra tips, justifications or examples. A summary that gets reread many times becomes what the reader remembers as the article.

### Grouping the checklist

Pick per article:

- **By cadence** (`#### Monthly: ...`, `#### Weekly: ...`, `#### Daily: ...`, `#### As needed: ...`) when the advice implies a routine, for example prioritization or habit articles. Not every area can be dealt with every day, and cadence groups show what to do when.
- **By phase** (`#### Research: ...`, `#### Entry: ...`, `#### Exit: ...`) when the advice follows a sequence, for example a process or a trade.
- **Flat list** when there are about ten items or fewer, or the advice has no natural schedule or sequence.

Give each `####` heading a short label after the colon saying what the group is about. Order groups the way the reader would live through them.

## Writing it to the file

When a target file is given:

1. Re-read the file just before editing: the user often edits it while you work, and their version wins.
2. Put the summary directly under `# Summary`, keeping everything else (tag line, `# Article`, URL, image, article text) unchanged. If a summary is already there, replace only the summary content and say so.
3. Don't try to commit: these folders sit in an encrypted vault that git cannot read.

## Reply in chat

- With a target file: say in one sentence where the summary went, then show the summary itself, then add one short note for anything the user should know (truncated paste, an existing summary replaced, grouping chosen without being asked and the alternative).
- Without a target file: reply with the summary only, plus any such note.
