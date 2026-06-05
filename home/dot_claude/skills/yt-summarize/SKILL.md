---
name: yt-summarize
description: Summarize a YouTube video transcript. Handles plain text transcripts with optional chapter list, or VTT transcripts (with embedded timestamps). Supports two output forms: (1) paragraphs + insights checklist, (2) per-chapter summaries with optional checklist. Invoke when the user pastes a YouTube transcript and asks for a summary.
---

# /yt-summarize — YouTube Transcript Summarizer

Arguments: `$ARGUMENTS`

---

## Step 1 — Collect inputs

Check the conversation for:

- **Transcript**: plain text, or VTT format (lines that look like `00:01:23.456 --> 00:01:25.789` followed by caption text).
- **Chapter list** (optional): a list of timestamps + chapter titles the user pasted separately (e.g. `0:00 Intro`, `3:45 Main topic`).
- **YouTube URL** (optional): the full video URL (e.g. `https://www.youtube.com/watch?v=XXXXXXXXXXX`), used to generate per-chapter timestamp links.

If no transcript is present in the conversation yet, ask the user to paste it now, and specify what to include:

> Please paste the transcript. You can provide:
> - Plain text only (chapters optional — paste them too if you have them)
> - VTT content (timestamps + captions)
>
> Optionally, also paste the YouTube video URL so chapter timestamp links can be included in the summary.

If the transcript is present but no YouTube URL was provided, ask:

> Do you have the YouTube video URL? If so, paste it and I'll add a timestamp link at the end of each chapter.

Wait for the user to provide the content before continuing.

---

## Step 2 — Determine output form

Parse `$ARGUMENTS` for `--form1` or `--form2`. If neither is present, ask:

> Which summary form do you want?
> 1. **Global summary** — a few paragraphs covering the whole video, followed by a checklist of important and insightful points.
> 2. **Per-chapter summary** — a dedicated summary (2+ paragraphs) for each chapter or section.

Wait for the answer before continuing.

---

## Step 3 — For form 2 only: ask about checklist

If the chosen form is **form 2** and `$ARGUMENTS` contains neither `--checklist` nor `--no-checklist`, ask:

> Should each chapter summary also include a checklist of key insights? (yes / no)

Wait for the answer.

---

## Step 4 — Determine chapter structure

Use the following priority:

1. **Explicit chapter list provided** → use it as-is. Each entry defines one section to summarize.
2. **No chapter list, but VTT content present** → derive chapters yourself:
   - Scan the VTT for natural topic shifts (changes in subject, speaker, pacing).
   - Assign a descriptive title and approximate timestamp to each inferred section.
   - Show the inferred chapter list to the user before summarizing, so they can correct it if needed.
3. **Plain text with no chapters and no VTT** → treat the entire transcript as one section titled "Full video". Form 2 still applies (write 2+ paragraphs), but there is only one section.

---

## Step 5 — Parse VTT if needed

If the input is VTT:
- Strip `WEBVTT` header, cue identifiers, and `-->` timestamp lines.
- Concatenate the caption text in order, preserving sentence boundaries.
- Use the original timestamps to map each caption block to its chapter when chapters are known or inferred.

---

## Step 6 — Generate the summary

### Form 1 — Global summary

Write **3–5 paragraphs** that cover the full arc of the video:
- What the video is about (topic, context, speaker/channel if known).
- The main argument or narrative thread.
- Key supporting points, evidence, or demonstrations.
- Conclusion or call to action if present.

Then output a **checklist of important and insightful points**, formatted as:

```
## Key insights

- [ ] <insight>
- [ ] <insight>
...
```

Use ATX-style `##` headings throughout. Do not use `---` horizontal rules as section dividers.

Aim for 6–12 items. Prioritize:
- Actionable advice or steps the viewer can apply.
- Surprising or counterintuitive findings.
- Frameworks, mental models, or named concepts introduced.
- Specific data, numbers, or examples worth remembering.

---

### Form 2 — Per-chapter summary

For each chapter (in order):

```
## Chapter title

<2+ paragraphs summarizing this chapter>

### Key insights   ← only if checklist was requested
- [ ] <insight>
...

[Watch at M:SS](https://www.youtube.com/watch?v=VIDEO_ID&t=SECONDS)   ← only if YouTube URL was provided
```

Rules:
- Chapter headings use ATX-style `##` (e.g. `## Chapter title`). No timestamp in the heading. No `---` horizontal rules between sections.
- Minimum 2 paragraphs per chapter, even for short sections. The first paragraph introduces the chapter's topic and main claim; the second elaborates, provides examples, or covers the resolution/conclusion of that section.
- Longer or denser chapters warrant more paragraphs — use judgment.
- Checklist items should be specific to that chapter, not generic.
- Do not include the original chapter timestamp in the heading.
- If a YouTube URL was provided, append a `[Watch at M:SS](URL&t=SECONDS)` link after each chapter's content (after the checklist if present). Convert the chapter's timestamp to total seconds for the `t=` parameter. Do **not** add this link after the final Key insights section.

---

## Step 7 — Output language

Write the summary in the **same language as the transcript**. If the transcript mixes languages, use the dominant one. Do not translate unless the user explicitly asks.

---

## Edge cases

- **Very short transcript (< 5 minutes equivalent)**: Form 1 may produce only 2 paragraphs — that is fine. Form 2 may collapse to a single section.
- **No meaningful content in a chapter** (e.g. sponsor segment, intro jingle): note it briefly (`*[Sponsor segment — skipped]*`) and move on.
- **Duplicate or near-duplicate captions in VTT** (common with auto-generated subtitles): deduplicate before summarizing.
- **Missing timestamps in chapter list**: proceed without them, omit the timestamp from the heading.
