# /// script
# requires-python = ">=3.10"
# dependencies = ["pymupdf>=1.24"]
# ///
"""PDF figure helper for the pdf-images skill. Run with: uv run pdf_images.py <command> ...

Commands (all print JSON to stdout):
  list    PDF [--min-px 120]                    embedded images with page, size, caption, suggested slug
  extract PDF --out DIR --prefix P [--only XREF:NAME ...] [--min-px 120]
                                                save images as PNG (alpha kept, CMYK converted)
  render  PDF --page N --out FILE [--dpi 110] [--search TEXT] [--pad 30]
                                                render a page, or a close-up around TEXT
"""
import argparse, json, re, sys
from pathlib import Path

import pymupdf

CAPTION = re.compile(r"^\s*(figure|fig\.)\s*(\d+)\s*[:.\-]?\s*(.*)", re.I | re.S)


def slug(text, max_words=7):
    text = re.split(r"\s+(?:-|\||\(|->)\s*", text.strip(), maxsplit=1)[0]
    words = re.sub(r"[^a-z0-9]+", " ", text.lower()).split()
    if words and words[0] in ("the", "a", "an"):
        words = words[1:]
    return "-".join(words[:max_words]) or "image"


def text_blocks(page):
    return [(pymupdf.Rect(b[:4]), " ".join(b[4].split())) for b in page.get_text("blocks") if b[6] == 0 and b[4].strip()]


def find_caption(page, rect, blocks):
    """Nearest 'Figure N' block to the image; else the nearest text block just above it."""
    best = None
    for r, t in blocks:
        m = CAPTION.match(t)
        if m:
            d = min(abs(r.y0 - rect.y1), abs(rect.y0 - r.y1))
            if best is None or d < best[0]:
                best = (d, int(m.group(2)), t, m.group(3))
    if best:
        return {"figure": best[1], "caption": best[2], "slug": slug(best[3])}
    above = [(rect.y0 - r.y1, t) for r, t in blocks if r.y1 <= rect.y0 + 2 and not t.lower().startswith(("may ", "page "))]
    near = min(above, default=None)
    return {"figure": None, "caption": None, "preceding_text": near[1] if near else None,
            "slug": slug(near[1]) if near else "image"}


def list_images(doc, min_px):
    out, seen = [], set()
    for page in doc:
        blocks = text_blocks(page)
        for info in page.get_images(full=True):
            xref, w, h = info[0], info[2], info[3]
            if xref in seen or min(w, h) < min_px:
                continue  # repeated logos/backgrounds and small icons
            rects = page.get_image_rects(xref)
            if not rects:
                continue
            seen.add(xref)
            # an image drawn on many pages is decoration (header logo, TOC background)
            pages_using = sum(1 for p in doc if any(i[0] == xref for i in p.get_images()))
            out.append({"page": page.number + 1, "xref": xref, "width": w, "height": h,
                        "repeated_on_pages": pages_using, **find_caption(page, rects[0], blocks)})
    return out


def save_png(doc, xref, path):
    pix = pymupdf.Pixmap(doc, xref)
    smask = doc.extract_image(xref).get("smask")
    if smask:
        pix = pymupdf.Pixmap(pix, pymupdf.Pixmap(doc, smask))
    if pix.n - pix.alpha > 3:
        pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
    pix.save(str(path))
    return pix.width, pix.height


def cmd_extract(doc, a):
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    if a.only:
        plan = [(int(x.split(":", 1)[0]), x.split(":", 1)[1]) for x in a.only]
    else:
        plan, n_img = [], 0
        for im in list_images(doc, a.min_px):
            if im["repeated_on_pages"] > 1:
                continue
            if im["figure"] is not None:
                name = f"fig-{im['figure']:02d}-{im['slug']}"
            else:
                n_img += 1
                name = f"img-p{im['page']:02d}-{im['slug']}"
            plan.append((im["xref"], name))
    saved = []
    for xref, name in plan:
        name = name if name.endswith(".png") else f"{a.prefix}-{name}.png" if a.prefix else f"{name}.png"
        path = out / name
        if path.exists() and not a.overwrite:
            saved.append({"xref": xref, "file": str(path), "skipped": "exists (use --overwrite)"})
            continue
        w, h = save_png(doc, xref, path)
        saved.append({"xref": xref, "file": str(path), "width": w, "height": h})
    return saved


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


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("list", "extract", "render"):
        s = sub.add_parser(name); s.add_argument("pdf")
        if name in ("list", "extract"):
            s.add_argument("--min-px", type=int, default=120)
        if name == "extract":
            s.add_argument("--out", required=True); s.add_argument("--prefix", default="")
            s.add_argument("--only", nargs="*", help="XREF:NAME pairs, NAME without prefix/extension")
            s.add_argument("--overwrite", action="store_true")
        if name == "render":
            s.add_argument("--page", type=int, required=True); s.add_argument("--out", required=True)
            s.add_argument("--dpi", type=int, default=110); s.add_argument("--search")
            s.add_argument("--pad", type=int, default=30)
    a = p.parse_args(argv)
    doc = pymupdf.open(a.pdf)
    result = {
        "list": lambda: list_images(doc, a.min_px),
        "extract": lambda: cmd_extract(doc, a),
        "render": lambda: cmd_render(doc, a),
    }[a.cmd]()
    json.dump(result, sys.stdout, ensure_ascii=False, indent=1)
    print()


if __name__ == "__main__":
    main()
