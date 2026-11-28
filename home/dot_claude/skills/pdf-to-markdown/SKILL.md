---
name: pdf-to-markdown
description: Extract a PDF's text (via its embedded text layer, or OCR if it's scanned/image-only) and turn it into clean, well-structured Markdown — de-hyphenating line-wrapped words, rejoining paragraphs, reconstructing headings and tables, repairing garbled or dropped superscript reference marks and checking tables against rendered pages, and stripping page-scan artifacts and boilerplate. Hands figures to /pdf-images. Invoke when the user asks to convert a PDF (or scanned booklet/document) to Markdown, or to "extract" a PDF/booklet's content to a .md file.
---

# /pdf-to-markdown — PDF (incl. OCR) to Clean Markdown

Arguments: `$ARGUMENTS` (path to the source PDF, if given)

Page rendering (page count, close-ups of reference marks, table pages) uses the bundled `scripts/pdf_render.py`, run with `uv run --quiet "<this skill's folder>/scripts/pdf_render.py" <command> "<pdf>" ...` (commands: `info`, `render`, `marks`, `tables`, `emphasis`; all print JSON). `uv` installs PyMuPDF for the run, so nothing is installed globally. On Windows, set `PYTHONIOENCODING=utf-8` first. If `uv` is missing, tell the user to install it (`scoop install uv`) rather than installing packages into their global Python.

Goal: reformat, don't summarize. Every paragraph of real body content in the source must survive into the output — the only allowed content loss is boilerplate explicitly called out in Step 6.

---

## Step 1 — Locate source and output

Identify the source PDF (from `$ARGUMENTS` or the conversation). Confirm where the final `.md` should live — default to the same directory as the PDF, same basename, `.md` extension, unless the user says otherwise.

---

## Step 2 — Extract raw text per page

Prefer the embedded text layer over OCR — it's exact, OCR is a fallback for scanned/image-only PDFs.

1. Check for `pdftotext` (poppler/xpdf) on PATH — it's commonly available even when no Python PDF libraries are installed. Extract per page with explicit page markers so later steps can track position and re-extract a single page cheaply:

   ```bash
   for i in $(seq 1 $PAGECOUNT); do
     echo "--- PAGE $i ---"
     pdftotext -enc UTF-8 -layout -f $i -l $i "source.pdf" -
     echo
   done > extracted_raw.txt
   ```

   Get `$PAGECOUNT` from `pdfinfo source.pdf`, or if poppler's pdfinfo isn't installed, from `pdf_render.py info source.pdf`. Don't loop to a guessed upper bound: pdftotext does not fail past the last page, so the loop never stops early. `-layout` preserves reading order better for simple single-column pages. Always pass `-enc UTF-8` and read the dump as UTF-8: without it pdftotext uses the system code page (on Windows, cp1252), which turns em dashes into `--` and superscript reference marks into the wrong characters (`²` where the page shows `11`).

2. If `pdftotext` isn't available, try a Python library already installed (check with a quick `import` before assuming): `pdfplumber` or `pypdf`. Same per-page-with-markers approach.

3. Save this raw dump as an intermediate file (scratchpad or repo root) — not the final deliverable. Keeping it lets you redo the cleanup pass without re-extracting.

---

## Step 3 — Detect whether real OCR is needed

If the raw extraction from Step 2 comes back empty or near-empty across many pages despite the PDF clearly having content (check the page count vs. characters extracted), the PDF has no text layer — it's scanned images and needs actual OCR.

- Check for `tesseract` on PATH. If present: rasterize each page (`pdftoppm -png`, or `pdf_render.py render --page N --dpi 300`) and run `tesseract` per page image, still inserting the same `--- PAGE N ---` markers.
- If no OCR tool is available, **stop and tell the user** OCR tooling isn't installed rather than fabricating text from the page images. Ask how they want to proceed (install tesseract, use a different OCR pipeline, etc.) — never guess at document content you can't actually read.

---

## Step 4 — Clean the raw text into real paragraphs

Working from the raw per-page dump:

- Remove `--- PAGE N ---` markers and blank/near-blank pages (cover, blank leaves, colophon-only pages) once their content (if any) has been folded into the surrounding flow.
- **De-hyphenate line-wrap breaks**: OCR/text-layer extraction wraps mid-word at the end of a printed line (e.g. `gener-\nation` → `generation`). Only join these — never touch legitimate hyphenated compounds that aren't a mid-word line break.
- **Rejoin wrapped lines into paragraphs**: a paragraph in the source is usually one logical block that got split one-line-per-typeset-line. Merge those into a single flowing paragraph; keep the paragraph break where the source actually breaks (blank line, indent, new sentence starting a new visual block).
- Fix only unambiguous OCR misreads (stray smart-quote glyphs, obvious character substitutions like `a"sume` → `assume`). Do not rephrase or "improve" the author's wording — this is reformatting, not editing.

---

## Step 5 — Reconstruct structure as Markdown

Map the source's visual/typographic structure onto Markdown, using judgment based on font size, ALL CAPS, centering, or position cues visible in the raw layout:

- Title → `#`
- Author / edition / copyright / printing notice → an italic line under the title
- Part/section headings → `##`
- Sub-headings → `###`
- Notable pull-quotes or epigraphs → `>` blockquote
- Tabular or chart-like data (dates, figures, columns of aligned values) → a proper Markdown table, with its "Table N: ..." caption as an italic line below it
- Figure captions ("Figure N: ...") → an italic line `*Figure N: ...*` where the figure sits in the flow; `/pdf-images` later inserts the image above it (Step 10)
- Reference marks (endnote numbers after a word) → `<sup>N</sup>`, exactly as extracted; Step 9 checks them against close-ups
- Bold and italic emphasis in body text → `**bold**` and `*italic*`. pdftotext drops all emphasis, so run `pdf_render.py emphasis source.pdf`: it lists every bold or italic run in body-size text with its page and full line. Restore each run where it appears: run-in labels (`**Tools:** ...`), bolded list-item openers, defined terms, an emphasized closing line. Skip runs from parts you left out (cover, table of contents, page headers), and don't add emphasis the list doesn't show, so the Markdown stays faithful to the page. When done, run `pdf_render.py emphasis source.pdf --check output.md`: it lists only the runs the Markdown doesn't emphasize yet. Fix each one, or confirm it is one you meant to skip (cover lines, headings, the table of contents). An edit script can miss phrases without saying so, so trust the check, not the script's report.
- Use `---` sparingly, only between major parts — not between every section

---

## Step 6 — Handle non-body boilerplate

Ads, subscription/order forms, mailing address lists, and similar back-matter that isn't part of the document's actual content: leave these out of the body. Add one short italic editorial note near the end of the file stating what was omitted and why (e.g. *"Mailing-address boilerplate omitted — no longer current."*). Never silently drop content that IS part of the actual text (arguments, narrative, data) — only drop things that are clearly promotional/administrative cruft.

---

## Step 7 — Save output

Write the final `.md` next to the source PDF (same basename) unless the user asked for a different location. Mention the intermediate raw-text file if you kept one, in case the user wants to inspect it.

---

## Step 8 — Fidelity check

Before reporting done, skim the cleaned Markdown against the raw extraction section-by-section to confirm no real content paragraph got dropped or merged away. The bar is: a reader of the Markdown gets the same content as a reader of the PDF, just reformatted and reflowed.

---

## Step 9 — Repair reference marks and check tables against the page

Text extraction garbles superscripts set in an odd font (`²` where the page shows `11`), drops some entirely, and mixes up table cells that wrap over several lines. Only a rendered page shows the truth, so check both whenever the PDF has endnotes or tables.

**Reference marks.** Run `pdf_render.py marks source.pdf --out <scratch dir>`. Each entry gives the page, the text just before the mark, the extracted character(s) and a close-up PNG. For each one, compare with the Markdown:

- **Garbled**: the Markdown has a different number at that spot. Open the close-up with the Read tool and write the number you see.
- **Dropped**: the sentence has no mark at all. Add it.
- **Already correct**: leave it.

Write marks as `<sup>N</sup>`. When the extracted character and the close-up disagree, trust the close-up, because it is what the reader of the PDF sees. If a number seems to point at the wrong endnote, keep it as printed and tell the user. It's the author's error, and changing it would no longer be faithful.

**Tables.** Run `pdf_render.py tables source.pdf --out <scratch dir>`, open each page render with the Read tool, and compare it cell by cell with the Markdown table, paying special attention to cells that wrap. Fix what differs. For a table without a "Table N" caption, use `pdf_render.py render --page N` on its page.

---

## Step 10 — Hand off to /pdf-images when the PDF has figures

Text extraction can't recover pictures. When the text has "Figure N" captions, or the PDF holds other content images (an equation, a diagram, a chart), invoke `/pdf-images` with the source PDF and the saved `.md`. It asks the user where the images go, extracts them and embeds them above their captions. If the PDF has no figures, skip this step and say so in the report.

---

## Edge cases

- **Multi-column layouts**: `pdftotext -layout` can interleave columns out of order. If a page reads incoherently, try `-raw` or extract that page separately with column-aware handling; don't just leave scrambled text in the output.
- **Very large PDFs**: process and clean in page-range batches rather than trying to hold the whole document in context at once; append batches to the output file as you go.
- **Non-English or mixed-language source**: preserve the original language — don't translate unless the user explicitly asks.
- **Scanned PDF with no OCR tool available**: stop and ask (Step 3) rather than inventing plausible-sounding content.
