# /// script
# requires-python = ">=3.10"
# dependencies = ["pymupdf>=1.24"]
# ///
"""Page-render helper for the pdf-to-markdown skill (text checks). Run with: uv run pdf_render.py <command> ...

Commands (all print JSON to stdout):
  info    PDF                                   page count
  render  PDF --page N --out FILE [--dpi 110] [--search TEXT] [--pad 30]
                                                render a page, or a close-up around TEXT
  marks   PDF --out DIR [--dpi 220]             find reference marks (superscripts) and render close-ups
  tables  PDF --out DIR [--dpi 90]              render every page holding a "Table N" caption
  emphasis PDF [--check MD]                     bold/italic runs in body-size text (page, style, text, line);
                                                with --check, only those MD does not emphasize yet
"""
import argparse, json, re, sys
from pathlib import Path

import pymupdf

TABLE = re.compile(r"^\s*table\s*\d+\s*[:.]", re.I)
SUPERSCRIPT_CHARS = "⁰¹²³⁴⁵⁶⁷⁸⁹"
SUP_FLAG = 1  # pymupdf span flag bit 0 = superscript


def text_blocks(page):
    return [(pymupdf.Rect(b[:4]), " ".join(b[4].split())) for b in page.get_text("blocks") if b[6] == 0 and b[4].strip()]


def cmd_render(doc, a):
    page = doc[a.page - 1]
    clip = None
    if a.search:
        hits = page.search_for(a.search)
        if not hits:
            sys.exit(f"text not found on page {a.page}: {a.search!r}")
        r = hits[0]
        clip = pymupdf.Rect(r.x0, r.y0 - 8, r.x1 + a.pad, r.y1 + 3)
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    page.get_pixmap(dpi=a.dpi, clip=clip).save(a.out)
    return {"file": a.out}


def cmd_marks(doc, a):
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    found = []
    for page in doc:
        for b in page.get_text("dict")["blocks"]:
            for line in b.get("lines", []):
                spans = line["spans"]
                for i, s in enumerate(spans):
                    t = s["text"]
                    sup = (s["flags"] & SUP_FLAG) and t.strip().isdigit()
                    glyph = re.search(rf"[{SUPERSCRIPT_CHARS}]+", t)
                    if not (sup or glyph):
                        continue
                    mark = t.strip() if sup else glyph.group()
                    before = (spans[i - 1]["text"] if sup and i else t[:glyph.start()] if glyph else "")[-30:]
                    r = pymupdf.Rect(s["bbox"])
                    clip = pymupdf.Rect(r.x0 - 120, r.y0 - 6, r.x1 + 40, r.y1 + 6) & page.rect
                    f = out / f"mark-p{page.number + 1:02d}-{len(found) + 1:03d}.png"
                    page.get_pixmap(dpi=a.dpi, clip=clip).save(str(f))
                    found.append({"page": page.number + 1, "extracted": mark, "context": before + mark, "closeup": str(f)})
    return found


def cmd_tables(doc, a):
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    res = []
    for page in doc:
        caps = [t for _, t in text_blocks(page) if TABLE.match(t)]
        if caps:
            f = out / f"table-page-{page.number + 1:02d}.png"
            page.get_pixmap(dpi=a.dpi).save(str(f))
            res.append({"page": page.number + 1, "captions": caps, "render": str(f)})
    return res


def style_of(span):
    """'bold', 'italic', 'bold italic' or '' from span flags and font name (some PDFs set only one)."""
    font = span["font"].lower()
    bold = bool(span["flags"] & 16) or any(w in font for w in ("bold", "black", "heavy", "semibold"))
    italic = bool(span["flags"] & 2) or "italic" in font or "oblique" in font
    return " ".join(s for s, on in (("bold", bold), ("italic", italic)) if on)


def cmd_emphasis(doc, a):
    """Runs of bold/italic text per line, so emphasis lost by pdftotext can be restored."""
    res = []
    for page in doc:
        sizes = [s["size"] for b in page.get_text("dict")["blocks"] for l in b.get("lines", []) for s in l["spans"] if s["text"].strip()]
        body = max(set(round(x) for x in sizes), key=lambda x: sum(round(y) == x for y in sizes)) if sizes else 0
        for b in page.get_text("dict")["blocks"]:
            for line in b.get("lines", []):
                spans = line["spans"]
                full = "".join(s["text"] for s in spans).strip()
                runs, cur = [], None
                for s in spans:
                    st = style_of(s) if s["text"].strip() else (cur[0] if cur else "")
                    if cur and st == cur[0]:
                        cur[1] += s["text"]
                    else:
                        cur = [st, s["text"], round(s["size"])]; runs.append(cur)
                for st, text, size in runs:
                    # larger-than-body bold text is a heading, which the heading pass already handles
                    if st and any(c.isalnum() for c in text) and size <= body + 1:
                        res.append({"page": page.number + 1, "style": st, "text": text.strip(), "whole_line": text.strip() == full, "line": full})
    if a.check:
        res = missing_emphasis(res, Path(a.check).read_text(encoding="utf-8"))
    return res


def missing_emphasis(runs, md):
    """Runs whose text is not inside a matching **bold** / *italic* span of the Markdown."""
    bold = re.findall(r"\*\*(.+?)\*\*", md)
    plain = re.sub(r"\*\*(.+?)\*\*", r"\1", md)
    italic = re.findall(r"(?<![*\w])\*(?!\*)(.+?)(?<!\*)\*(?![*\w])", plain)
    missing = []
    for r in runs:
        t = r["text"].strip().rstrip(":").strip()[:40]
        pool = (bold if "bold" in r["style"] else []) + (italic if "italic" in r["style"] else [])
        # a run split by a code span or a line wrap matches a span that contains it or is contained in it
        if not any(t in s or (len(s.strip(" :.")) > 3 and s.strip(" :.") in t) for s in pool):
            missing.append(r)
    return missing


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("info", "render", "marks", "tables", "emphasis"):
        s = sub.add_parser(name); s.add_argument("pdf")
        if name == "render":
            s.add_argument("--page", type=int, required=True); s.add_argument("--out", required=True)
            s.add_argument("--dpi", type=int, default=110); s.add_argument("--search")
            s.add_argument("--pad", type=int, default=30)
        if name == "emphasis":
            s.add_argument("--check", metavar="MD", help="list only the runs not yet emphasized in this Markdown file")
        if name in ("marks", "tables"):
            s.add_argument("--out", required=True)
            s.add_argument("--dpi", type=int, default=220 if name == "marks" else 90)
    a = p.parse_args(argv)
    doc = pymupdf.open(a.pdf)
    result = {
        "info": lambda: {"pages": doc.page_count},
        "render": lambda: cmd_render(doc, a),
        "marks": lambda: cmd_marks(doc, a),
        "tables": lambda: cmd_tables(doc, a),
        "emphasis": lambda: cmd_emphasis(doc, a),
    }[a.cmd]()
    json.dump(result, sys.stdout, ensure_ascii=False, indent=1)
    print()


if __name__ == "__main__":
    main()
