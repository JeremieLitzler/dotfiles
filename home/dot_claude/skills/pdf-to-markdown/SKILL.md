---
name: pdf-to-markdown
description: Extract a PDF's text (via its embedded text layer, or OCR if it's scanned/image-only) and turn it into clean, well-structured Markdown — de-hyphenating line-wrapped words, rejoining paragraphs, reconstructing headings and tables, and stripping page-scan artifacts and boilerplate. Invoke when the user asks to convert a PDF (or scanned booklet/document) to Markdown, or to "extract" a PDF/booklet's content to a .md file.
---

# /pdf-to-markdown — PDF (incl. OCR) to Clean Markdown

Arguments: `$ARGUMENTS` (path to the source PDF, if given)

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
     pdftotext -layout -f $i -l $i "source.pdf" -
     echo
   done > extracted_raw.txt
   ```

   Get `$PAGECOUNT` from `pdfinfo source.pdf` if needed. `-layout` preserves reading order better for simple single-column pages.

2. If `pdftotext` isn't available, try a Python library already installed (check with a quick `import` before assuming): `pdfplumber` or `pypdf`. Same per-page-with-markers approach.

3. Save this raw dump as an intermediate file (scratchpad or repo root) — not the final deliverable. Keeping it lets you redo the cleanup pass without re-extracting.

---

## Step 3 — Detect whether real OCR is needed

If the raw extraction from Step 2 comes back empty or near-empty across many pages despite the PDF clearly having content (check `pdfinfo` page count vs. characters extracted), the PDF has no text layer — it's scanned images and needs actual OCR.

- Check for `tesseract` on PATH. If present: rasterize each page (`pdftoppm -png` or similar) and run `tesseract` per page image, still inserting the same `--- PAGE N ---` markers.
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
- Tabular or chart-like data (dates, figures, columns of aligned values) → a proper Markdown table
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

## Edge cases

- **Multi-column layouts**: `pdftotext -layout` can interleave columns out of order. If a page reads incoherently, try `-raw` or extract that page separately with column-aware handling; don't just leave scrambled text in the output.
- **Very large PDFs**: process and clean in page-range batches rather than trying to hold the whole document in context at once; append batches to the output file as you go.
- **Non-English or mixed-language source**: preserve the original language — don't translate unless the user explicitly asks.
- **Scanned PDF with no OCR tool available**: stop and ask (Step 3) rather than inventing plausible-sounding content.
