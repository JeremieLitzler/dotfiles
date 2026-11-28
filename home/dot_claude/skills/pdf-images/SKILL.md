---
name: pdf-images
description: Extract the figures (embedded images, diagrams, equation images) from a PDF as PNG files, name them from their captions, and embed them into the Markdown conversion of that PDF, asking the user where the images should go. Companion to /pdf-to-markdown, which calls it when the PDF has figures. Use whenever the user asks to "extract figures/images/diagrams from a PDF", to add the PDF's pictures to a note or .md file, or to replace "Figure N" captions with the actual images, even if they don't name this skill.
---

# /pdf-images: PDF figures into Markdown

Arguments: `$ARGUMENTS` (the source PDF and, if given, the target Markdown file)

Text extraction (`/pdf-to-markdown`) keeps the figure captions but loses the figures themselves. This skill recovers them with PyMuPDF, run through `uv` so nothing is installed globally. Reference marks and table checks belong to `/pdf-to-markdown` (its Step 9), not here.

The bundled script does the deterministic work. Run it as:

```bash
uv run --quiet "<this skill's folder>/scripts/pdf_images.py" <command> "<pdf>" ...
```

On Windows, set `PYTHONIOENCODING=utf-8` before the command so the JSON prints superscript characters correctly. If `uv` is missing, stop and tell the user to install it (`scoop install uv`, `winget install astral-sh.uv`, or `pipx install uv`) rather than installing PyMuPDF into their global Python.

| Command | What it returns |
| --- | --- |
| `list PDF` | every embedded image: page, xref, pixel size, `repeated_on_pages`, the "Figure N" caption nearest to it (or the text just above it), a suggested slug |
| `extract PDF --out DIR --prefix P [--only XREF:NAME ...] [--overwrite]` | saves PNGs, transparency kept, CMYK converted to RGB |
| `render PDF --page N --out FILE [--dpi 110] [--search TEXT]` | a page image, or a close-up around TEXT (for vector figures, and for viewing an image in context) |

## Step 1: Locate the inputs

Identify the source PDF and the target Markdown file (the conversion of that PDF, or a note holding it under some heading). If no Markdown file exists yet and the user wants one, run `/pdf-to-markdown` first. If the user only wants the image files, the target file is optional.

## Step 2: Ask where things go, with suggestions

Where the images live depends on how the user organizes their files, so ask instead of deciding. Ask the questions together in one message, number each question, letter each option, put the recommended option first, and name the subject inside every question. Build the suggestions from what you can see:

1. **Image folder.** Inspect before suggesting:
   - If the target .md is inside an Obsidian vault (a parent folder has `.obsidian/`), read `.obsidian/app.json`: if `attachmentFolderPath` is set, suggest it. Also look for an existing `images/`, `attachments/` or `assets/` folder at the vault root that already holds images, and suggest it.
   - A folder next to the target .md (the same folder, or an `images/` subfolder).
   - The folder of the PDF.
   - A dedicated subfolder named after the document.
2. **File name prefix.** Suggest a short slug of the document title (e.g. `new-sdlc` for "The New SDLC With Vibe Coding"), and offer "no prefix". Files are named `<prefix>-fig-NN-<caption-slug>.png`; a prefix keeps one shared images folder sorted by document.
3. **Embed syntax.** Suggest `![[file.png]]` when the target .md is in an Obsidian vault, otherwise `![Figure N: caption](relative/path/file.png)` (the path relative to the .md file, with spaces encoded as `%20`). Standard syntax also renders in Azure DevOps wikis and on GitHub.

Skip a question only when the user's request already answers it.

## Step 3: List and decide which images are figures

Run `list`. Then sort the images:

- **Captioned figures** (`figure` is a number): keep them all.
- **Images on several pages** (`repeated_on_pages` > 1): logos, page backgrounds, table-of-contents art. Skip them.
- **Uncaptioned images**: open each one with the Read tool (extract it to the scratchpad first, or `render` its page) and decide. Content images, like an equation or a diagram without a caption, are kept. Name them from what they show (e.g. `equation-agent-equals-model-plus-harness`), because the suggested slug comes from the preceding sentence and is often weak. Cover art and decorative backgrounds are skipped. If you can't tell, ask.
- `list` already drops images smaller than 120 px on a side (bullet icons, tip icons). Lower `--min-px` only if a real figure is that small.

Review the suggested slugs as well. The script cuts a caption at ` - `, ` | ` or ` (`, which sometimes leaves a run-on phrase (`factory-model-developer-designs-the-system`): shorten it to the figure's title (`factory-model`). Pass the final names with `--only XREF:NAME`, where NAME is `fig-NN-<slug>` without prefix or extension, and the script adds the prefix and `.png`.

A figure drawn as vector graphics (not an embedded image) does not appear in `list`. If a "Figure N" caption in the text has no image, `render` that page (or a `--search` close-up around the caption) and save it as the figure, and tell the user it is a page render.

## Step 4: Extract

Run `extract` into the chosen folder. It refuses to overwrite an existing file unless you pass `--overwrite`. If a name clashes with a file that isn't from an earlier run of this skill on the same PDF, ask before overwriting. Open one or two of the saved PNGs with the Read tool to confirm they are the right images.

## Step 5: Embed into the target Markdown

For each figure, find its caption line in the target file (usually an italic `*Figure N: ...*` line written by `/pdf-to-markdown`) and insert the embed on its own line directly above it, with a blank line between:

```markdown
![[new-sdlc-fig-03-vibe-coding-to-agentic-engineering-spectrum.png]]

*Figure 3: The Vibe Coding to Agentic Engineering Spectrum*
```

Keep the caption text exactly as it is: it is part of the document. For a kept uncaptioned image, replace any placeholder note that `/pdf-to-markdown` left (e.g. `*[Equation shown as an image ...]*`), or insert the embed right after the sentence that introduces it ("A useful equation:"). If the file has an editorial note saying the figures were omitted, update it to say they were extracted, and where to.

Use Edit for each insertion, so that the rest of the file, its line endings and its encoding are left alone.

## Step 6: Report

Tell the user:
- how many images were saved and where (full paths);
- which images were skipped and why (repeated, decorative, too small);
- anything rendered from a page rather than extracted.

Don't paste the document back into the chat.
