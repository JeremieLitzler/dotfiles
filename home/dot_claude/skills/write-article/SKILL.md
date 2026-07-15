---
name: write-article
description: Write a publish-ready blog article from an archived session summary in the "my-claude-conversations" repo, using the correct language template. Works from ANY project — locates the archive clone under D:/Git/GitHub or E:/Git/GitHub, cloning it first if it is missing. Use when the user asks to turn a session summary into a blog article, draft an article from a summary, or "write an article" for a given slug.
tools: Bash, Read, Write, WebSearch, WebFetch
---

# Write article

Write a publish-ready blog article from an archived session summary, using the correct language template. The summaries and articles live in the `my-claude-conversations` repo; this skill works from **any** project by locating (or cloning) that repo automatically.

## Input

`$ARGUMENTS` identifies the source session. Accept any of:

- a slug (e.g. `goodbye-clean-code-lessons-learned` or `2026-07-07-goodbye-clean-code-lessons-learned`),
- a path to a file in `summaries/` or `replays/`,
- nothing — then use the most recently modified file in `<REPO_ROOT>/summaries/` and confirm the pick with the human before writing.

Resolve the identifier to the matching `<REPO_ROOT>/summaries/YYYY-MM-DD-slug.md` (see step 1 for `REPO_ROOT`). Summaries whose article has already been written live in `<REPO_ROOT>/summaries/article-written/` — look there too when the top level has no match, and say so if that is where you found it. Read the summary in full — it is the **only** source for the article's content. Do not read or consult the replay.

## Steps

1. **Locate the archive repo.** Run the helper script — **one** command, so the human sees only **one** permission request:

   ```bash
   bash ~/.claude/skills/write-article/scripts/locate-repo.sh
   ```

   - It finds the `my-claude-conversations` clone under `D:/Git/GitHub` or `E:/Git/GitHub`, and **clones it there if it is missing**.
   - It ensures the `summaries/`, `summaries/article-written/`, and `articles/scheduled/` folders exist.
   - It prints `REPO_ROOT=<path>` on success. Use that `REPO_ROOT` for every repo-relative path below (the summary you read, the article you write, the archive move).

2. **Read the summary** and detect the language of its **prose** (French vs English — the same language the human used in the session).

3. **Pick the template by language:**
   - French summary: `assets/_french-example.md`
   - English summary: `assets/_english-example.md`

   These template files are bundled with this skill; resolve them relative to this `SKILL.md`. Read the chosen template. It defines the exact frontmatter shape, the closing "follow me" `{{< blockcontainer jli-notice-tip … >}}` block, and the photo-credit line — reproduce all of these in the target language, verbatim in structure.

4. **Generate the article title** in the summary's language. It should read as a standalone blog title, not a session log title — it does **not** need to match the summary's H1. Confirm the title with the human, or use theirs if they gave one.

   In the same breath, **ask which voice to write in**: first-person singular (*I / me / my*) or first-person plural (*we / us / our*). Apply the answer consistently throughout the article — never mix the two.

   And **ask for the publish date** (`YYYY-MM-DD`). The human decides when the article goes out, so never infer it: not from today's date, and not from the source summary's date. If they haven't given one, ask and wait for it.

5. **Derive a kebab-case `slug`** from the article title.

6. **Write the article** to `<REPO_ROOT>/articles/scheduled/YYYY-MM-DD-slug.md`, where `YYYY-MM-DD` is the **publish date** from step 4 and `slug` is from step 5.

   Frontmatter (fill every field, following the chosen template's exact key order and style):
   - `title` — from step 4, in quotes.
   - `description` — one or two sentences, same language as the article.
   - `image` — a placeholder filename following the template's convention (French template: `/images/YYYY-MM-DD-slug.jpg`; English template: `YYYY-MM-DD-slug.jpg`). The human will supply the real asset.
   - `imageAlt` — a short alt text describing the intended image.
   - `date` — the publish date from step 4. It must match the date in the filename.
   - `categories` / `tags` — choose fitting values from the article's topic.

   Body:
   - Rewrite the summary into flowing article prose in the **summary's language**, in the voice chosen in step 4. Lead with a hook, use `##` section headings, keep code blocks and links intact.
   - Prefer narrative prose; use bullet or checklist items only for genuine enumerations (mirror how `assets/_english-example.md` and `assets/_french-example.md` read).
   - Do not invent facts — every claim must trace back to the summary.
   - **References:** an article needs sources to feel authentic. If the summary already cites sources (links, article names, authors), carry them through. If it cites none, research the topic on the web and add real, verifiable citations — quote or link authoritative sources to back the article's key claims. Never fabricate a source, URL, quote, or author; only cite material you have actually verified exists.
   - Follow the **Style** rules below.
   - End with the template's "follow me" block and the photo-credit line, both translated to the article's language.
   - **The photo credit is a placeholder.** The `image` is a placeholder too, so its photographer and source can't be known yet — and inventing them would violate the no-fabrication rule above. Reproduce the credit line's shape with `TODO` standing in for the parts you can't know, e.g. `Credit: Photo by TODO on Pexels.` (English) or `Crédit : Photo de TODO sur Pexels.` (French). The human fills it in when they choose the image.

7. **Archive the source summary.** Once the article file exists, move `<REPO_ROOT>/summaries/YYYY-MM-DD-slug.md` into `<REPO_ROOT>/summaries/article-written/`, keeping its filename unchanged. Run `git mv` from inside `REPO_ROOT` so the rename is staged. Never copy-then-delete, and never touch the corresponding replay.

8. Report the path written and the summary's new location, and remind the human to drop the real `image` asset in place of the placeholder, and to replace the `TODO` in the photo-credit line. Leave committing/pushing to the human unless they ask.

## Style

The article must read as if a human wrote it. The tells below are what give away machine-generated prose — avoid every one of them.

**Code fences always name a language.** A block with no known programming language uses `plaintext`, never a bare fence. So ` ```plaintext ` rather than ` ``` `.

**No arrows.** Use `>` where you'd be tempted to write `→` — in navigation breadcrumbs, mappings, or anywhere else. For example, `Pipelines > Environments > ⋮ > Security`.

**No bold lead-ins in bullet lists.** A bullet that opens with a bolded noun phrase followed by a period or colon is the strongest tell there is. Either fold that phrase into the sentence, or drop the bold. Bold may still be used mid-sentence for genuinely key terms.

<avoid>
- **The authorization is permanent.** Granting permission, in Microsoft's words, "permits use of the service connection you authorized for all runs of this pipeline."
- **You may already have the rights.** Clicking **Permit** requires the **Administrator** role on the resource — not merely pipeline admin.
</avoid>

<prefer>
- Since the authorization is permanent, granting permission, in Microsoft's words, "permits use of the service connection you authorized for all runs of this pipeline."
- You may already have the rights. Clicking **Permit** requires the **Administrator** role on the resource — not merely pipeline admin.
</prefer>

**The conclusion is prose, not a bullet list.** Close with a few short sentences that carry the lesson. Never a "Takeaways" / "Key points" list that restates the article in fragments.

<avoid>
## Takeaways

- **Symptom:** a scheduled pipeline hangs on `Checks: Running` even though the stage condition evaluates true.
- **Cause:** first use of a protected resource by a new pipeline, plus no interactive approver on scheduled runs.
- **Fix:** click **Permit** once per resource.
</avoid>

<prefer>
## Conclusion

A scheduled pipeline that hangs on `Checks: Running` isn't a broken condition. It's a protected resource waiting on a click from a human who was never invited. Permit each resource once, and the gate never closes again.
</prefer>
