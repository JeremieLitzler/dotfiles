---
name: markdown-to-pdf
description: Convert a Markdown (.md) file into a print-styled PDF, fully offline. Uses a pure-stdlib Python Markdown renderer plus a Chromium-based browser (Chrome or Edge, auto-discovered) in headless print-to-pdf mode -- no pip installs, no network calls. Invoke when the user asks to "generate/export/print a PDF from" a Markdown file, or to convert docs/README/notes to PDF.
tools: Bash, Read
---

# Markdown to PDF

Convert a `.md` file to a clean, print-styled `.pdf`, running entirely
locally.

## How it works

- **Markdown parsing** is a small, self-contained regex-based renderer
  (headings, paragraphs, nested lists, blockquotes, fenced/inline code,
  bold/italic, links, images, horizontal rules, pipe tables) -- pure Python
  stdlib, nothing to `pip install`.
- **PDF rendering** wraps the generated HTML in a print-friendly A4
  stylesheet and runs a Chromium-based browser in `--headless
  --print-to-pdf` mode.

## Dependency

The **only** real dependency is a Chromium-based browser already installed
on the machine: **Google Chrome** or **Microsoft Edge** (Edge ships with
Windows by default, so this is normally already satisfied). The script
auto-discovers it, in order:

1. `--browser <path>` flag, if passed
2. `MARKDOWN_TO_PDF_BROWSER` env var, if set
3. `PATH` lookup (`chrome`, `msedge`, `chromium`, etc.)
4. Windows: the registry `App Paths` key (same lookup `start chrome` uses --
   no hardcoded install paths, works regardless of drive letter or install
   location)
5. macOS: standard `/Applications/*.app` bundle paths

If none is found, the script prints an install link and exits non-zero
rather than guessing -- surface that message to the user rather than
retrying blindly.

## Steps

1. Identify the source `.md` file (from the user's message or conversation
   context).
2. Run the script — **one** command, so the human sees only **one**
   permission request:

   ```bash
   python3 ~/.claude/skills/markdown-to-pdf/scripts/markdown_to_pdf.py "<input.md>"
   ```

   - Default output: same name/directory as the source, `.pdf` extension.
   - `-o/--output <path.pdf>` to choose a different output path.
   - `--title "<Title>"` to override the document title (default: the
     file's first `# H1`, else the filename).
   - `--keep-html` to keep the intermediate HTML file next to the PDF
     (useful if the user wants to inspect or tweak the styling).
   - `--browser <path>` to point at a specific browser executable directly.

3. The script prints `OUTPUT_PDF=<path>` on success. Report that path back
   to the user.

## Limitations (mention if relevant)

- This is a compact renderer, not full CommonMark: no setext headings
  (`Title\n===`), no nested blockquotes, no footnotes, no task-list
  checkboxes. Good for READMEs/docs/notes; for anything requiring exact
  CommonMark fidelity, note the gap rather than silently approximating.
- Table column alignment (`:---`, `---:`) is parsed but not applied visually
  -- all columns render left-aligned.
