#!/usr/bin/env python3
"""
markdown_to_pdf.py -- convert a Markdown file to a print-styled PDF.

Dependencies (checked automatically, nothing to install for the Markdown
parsing itself -- it is pure Python stdlib):
  - Python 3.8+
  - A Chromium-based browser already installed on this machine: Google
    Chrome or Microsoft Edge. Neither is a Python package -- if neither is
    found, the script prints an install hint and exits non-zero instead of
    guessing.

Usage:
  python markdown_to_pdf.py <input.md> [-o output.pdf] [--title "Title"] [--keep-html]

The Markdown subset supported: ATX headings (#..######), paragraphs,
unordered/ordered lists (with nesting via 2-space indent), blockquotes,
fenced code blocks, inline code, bold/italic, links, images, horizontal
rules, and pipe tables. It is deliberately a compact renderer, not a full
CommonMark implementation -- good enough for READMEs, docs, and notes.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# --------------------------------------------------------------------------
# Inline (span-level) rendering
# --------------------------------------------------------------------------

_INLINE_CODE_RE = re.compile(r"`([^`]+)`")
_IMAGE_RE = re.compile(r'!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)')
_LINK_RE = re.compile(r'\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)')
_BOLD_RE = re.compile(r"\*\*(.+?)\*\*|__(.+?)__")
_ITALIC_RE = re.compile(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)|(?<!_)_(?!_)(.+?)(?<!_)_(?!_)")


def render_inline(text: str) -> str:
    """Render inline markdown (bold, italic, code, links, images) to HTML."""
    text = html.escape(text, quote=False)

    stashed_code: list[str] = []

    def stash_code(match: "re.Match[str]") -> str:
        stashed_code.append(match.group(1))
        return f"\x00CODE{len(stashed_code) - 1}\x00"

    text = _INLINE_CODE_RE.sub(stash_code, text)
    text = _IMAGE_RE.sub(r'<img alt="\1" src="\2">', text)
    text = _LINK_RE.sub(r'<a href="\2">\1</a>', text)
    text = _BOLD_RE.sub(lambda m: f"<strong>{m.group(1) or m.group(2)}</strong>", text)
    text = _ITALIC_RE.sub(lambda m: f"<em>{m.group(1) or m.group(2)}</em>", text)

    def restore_code(match: "re.Match[str]") -> str:
        return f"<code>{stashed_code[int(match.group(1))]}</code>"

    return re.sub(r"\x00CODE(\d+)\x00", restore_code, text)


# --------------------------------------------------------------------------
# Block-level rendering
# --------------------------------------------------------------------------

_HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
_HR_RE = re.compile(r"^(-{3,}|\*{3,}|_{3,})$")
_UL_ITEM_RE = re.compile(r"^(\s*)[-*+]\s+(.*)$")
_OL_ITEM_RE = re.compile(r"^(\s*)\d+[.)]\s+(.*)$")
_BLOCKQUOTE_RE = re.compile(r"^>\s?(.*)$")
_FENCE_RE = re.compile(r"^```")
_TABLE_SEPARATOR_RE = re.compile(r"^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$")


def _close_list_stack(stack: list[dict], out: list[str], min_indent: int | None = None) -> None:
    while stack and (min_indent is None or stack[-1]["indent"] >= min_indent):
        if stack[-1]["li_open"]:
            out.append("</li>")
        out.append(f"</{stack[-1]['type']}>")
        stack.pop()


def _handle_list_item(line: str, stack: list[dict], out: list[str]) -> None:
    ul_match = _UL_ITEM_RE.match(line)
    ol_match = None if ul_match else _OL_ITEM_RE.match(line)
    indent_text, content = (ul_match or ol_match).groups()
    indent = len(indent_text)
    list_type = "ul" if ul_match else "ol"

    _close_list_stack(stack, out, min_indent=indent + 1)

    top = stack[-1] if stack else None
    if top and top["indent"] == indent:
        if top["li_open"]:
            out.append("</li>")
        if top["type"] != list_type:
            out.append(f"</{top['type']}>")
            out.append(f"<{list_type}>")
            top["type"] = list_type
    else:
        out.append(f"<{list_type}>")
        stack.append({"indent": indent, "type": list_type, "li_open": False})

    out.append(f"<li>{render_inline(content)}")
    stack[-1]["li_open"] = True


def _render_table(rows: list[str], out: list[str]) -> None:
    header_cells = [c.strip() for c in rows[0].strip().strip("|").split("|")]
    out.append("<table><thead><tr>")
    for cell in header_cells:
        out.append(f"<th>{render_inline(cell)}</th>")
    out.append("</tr></thead><tbody>")
    for row in rows[2:]:
        cells = [c.strip() for c in row.strip().strip("|").split("|")]
        out.append("<tr>")
        for cell in cells:
            out.append(f"<td>{render_inline(cell)}</td>")
        out.append("</tr>")
    out.append("</tbody></table>")


def markdown_to_html_body(markdown_text: str) -> str:
    lines = markdown_text.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    list_stack: list[dict] = []
    paragraph: list[str] = []
    blockquote: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            out.append(f"<p>{render_inline(' '.join(paragraph))}</p>")
            paragraph.clear()

    def flush_blockquote() -> None:
        if blockquote:
            out.append(f"<blockquote><p>{render_inline(' '.join(blockquote))}</p></blockquote>")
            blockquote.clear()

    index = 0
    total = len(lines)
    while index < total:
        line = lines[index]
        stripped = line.strip()

        if _FENCE_RE.match(stripped):
            flush_paragraph()
            flush_blockquote()
            _close_list_stack(list_stack, out)
            code_lines: list[str] = []
            index += 1
            while index < total and not _FENCE_RE.match(lines[index].strip()):
                code_lines.append(lines[index])
                index += 1
            escaped = html.escape("\n".join(code_lines))
            out.append(f"<pre><code>{escaped}</code></pre>")
            index += 1
            continue

        if not stripped:
            flush_paragraph()
            flush_blockquote()
            _close_list_stack(list_stack, out)
            index += 1
            continue

        heading = _HEADING_RE.match(stripped)
        if heading:
            flush_paragraph()
            flush_blockquote()
            _close_list_stack(list_stack, out)
            level = len(heading.group(1))
            out.append(f"<h{level}>{render_inline(heading.group(2))}</h{level}>")
            index += 1
            continue

        if _HR_RE.match(stripped):
            flush_paragraph()
            flush_blockquote()
            _close_list_stack(list_stack, out)
            out.append("<hr>")
            index += 1
            continue

        if (
            "|" in line
            and index + 1 < total
            and _TABLE_SEPARATOR_RE.match(lines[index + 1])
        ):
            flush_paragraph()
            flush_blockquote()
            _close_list_stack(list_stack, out)
            table_rows = [line, lines[index + 1]]
            index += 2
            while index < total and "|" in lines[index] and lines[index].strip():
                table_rows.append(lines[index])
                index += 1
            _render_table(table_rows, out)
            continue

        block_quote_match = _BLOCKQUOTE_RE.match(stripped)
        if block_quote_match:
            flush_paragraph()
            _close_list_stack(list_stack, out)
            blockquote.append(block_quote_match.group(1))
            index += 1
            continue

        if _UL_ITEM_RE.match(line) or _OL_ITEM_RE.match(line):
            flush_paragraph()
            flush_blockquote()
            _handle_list_item(line, list_stack, out)
            index += 1
            continue

        flush_blockquote()
        _close_list_stack(list_stack, out)
        paragraph.append(stripped)
        index += 1

    flush_paragraph()
    flush_blockquote()
    _close_list_stack(list_stack, out)
    return "\n".join(out)


# --------------------------------------------------------------------------
# HTML document template
# --------------------------------------------------------------------------

_PAGE_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
  @page {{ size: A4; margin: 22mm 20mm; }}
  body {{
    font-family: "Segoe UI", Calibri, Arial, sans-serif;
    color: #1a1a1a;
    line-height: 1.55;
    font-size: 11.5pt;
    max-width: 720px;
    margin: 0 auto;
  }}
  h1 {{ font-size: 19pt; margin: 0 0 14pt 0; border-bottom: 2px solid #2b2b2b; padding-bottom: 8pt; }}
  h2 {{ font-size: 14.5pt; margin: 22pt 0 8pt 0; border-bottom: 1px solid #ccc; padding-bottom: 3pt; }}
  h3 {{ font-size: 12.5pt; margin: 16pt 0 6pt 0; color: #333; }}
  h4, h5, h6 {{ font-size: 11.5pt; margin: 12pt 0 4pt 0; color: #333; }}
  p {{ margin: 8pt 0; text-align: justify; }}
  ul, ol {{ margin: 6pt 0; padding-left: 20pt; }}
  li {{ margin: 3pt 0; }}
  li > ul, li > ol {{ margin: 3pt 0; }}
  a {{ color: #1a54a8; text-decoration: none; }}
  a:hover {{ text-decoration: underline; }}
  em {{ font-style: italic; }}
  strong {{ font-weight: 600; }}
  blockquote {{ margin: 8pt 0; padding: 2pt 12pt; border-left: 3px solid #ccc; color: #444; }}
  code {{ font-family: Consolas, monospace; background: #f2f2f2; padding: 1px 4px; border-radius: 3px; font-size: 10.5pt; }}
  pre {{ background: #f2f2f2; padding: 8pt 10pt; border-radius: 4px; overflow-x: auto; }}
  pre code {{ background: none; padding: 0; }}
  table {{ border-collapse: collapse; width: 100%; margin: 10pt 0; font-size: 10.5pt; }}
  th, td {{ border: 1px solid #ccc; padding: 4pt 8pt; text-align: left; }}
  th {{ background: #f2f2f2; }}
  hr {{ border: none; border-top: 1px solid #ccc; margin: 16pt 0; }}
  img {{ max-width: 100%; }}
</style>
</head>
<body>
{body}
</body>
</html>
"""


def build_html_document(markdown_text: str, title: str) -> str:
    body = markdown_to_html_body(markdown_text)
    return _PAGE_TEMPLATE.format(title=html.escape(title, quote=True), body=body)


# --------------------------------------------------------------------------
# Chromium discovery and PDF rendering
# --------------------------------------------------------------------------

_WHICH_CANDIDATES = [
    "chrome", "chrome.exe", "google-chrome", "google-chrome-stable",
    "chromium", "chromium-browser", "msedge", "msedge.exe", "microsoft-edge",
]

# App Paths registry entries -- this is the same lookup `start chrome` uses
# internally, so it finds the browser regardless of drive letter, localized
# "Program Files" folder name, or per-machine vs. per-user install. No
# hardcoded filesystem paths needed.
_WINDOWS_APP_PATHS_EXES = ["chrome.exe", "msedge.exe"]

_MAC_PATH_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
]

_BROWSER_ENV_OVERRIDE = "MARKDOWN_TO_PDF_BROWSER"


def _find_via_windows_registry() -> str | None:
    try:
        import winreg
    except ImportError:
        return None  # not on Windows

    for exe_name in _WINDOWS_APP_PATHS_EXES:
        key_path = rf"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\{exe_name}"
        for hive in (winreg.HKEY_CURRENT_USER, winreg.HKEY_LOCAL_MACHINE):
            try:
                with winreg.OpenKey(hive, key_path) as key:
                    path, _ = winreg.QueryValueEx(key, None)  # default value
            except OSError:
                continue
            if path and os.path.isfile(path):
                return path
    return None


def find_chromium_browser(explicit_path: str | None = None) -> str | None:
    if explicit_path:
        return explicit_path if os.path.isfile(explicit_path) else None

    env_override = os.environ.get(_BROWSER_ENV_OVERRIDE)
    if env_override:
        return env_override if os.path.isfile(env_override) else None

    for name in _WHICH_CANDIDATES:
        found = shutil.which(name)
        if found:
            return found

    registry_match = _find_via_windows_registry()
    if registry_match:
        return registry_match

    if sys.platform == "darwin":
        for path in _MAC_PATH_CANDIDATES:
            if os.path.isfile(path):
                return path

    return None


def render_pdf(html_path: Path, pdf_path: Path, browser: str) -> None:
    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    command = [
        browser,
        "--headless",
        "--disable-gpu",
        "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_path}",
        html_path.as_uri(),
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    if not pdf_path.is_file() or pdf_path.stat().st_size == 0:
        # Chromium's headless mode can exit non-zero on a clean run, so the
        # only reliable success signal is the output file actually existing.
        raise RuntimeError(
            "PDF was not produced.\n"
            f"command: {' '.join(command)}\n"
            f"exit code: {result.returncode}\n"
            f"stdout: {result.stdout}\n"
            f"stderr: {result.stderr}"
        )


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def derive_title(markdown_text: str, fallback: str) -> str:
    for line in markdown_text.splitlines():
        heading = _HEADING_RE.match(line.strip())
        if heading and len(heading.group(1)) == 1:
            return heading.group(2)
    return fallback


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert a Markdown file to a print-styled PDF.")
    parser.add_argument("markdown_file", type=Path, help="Path to the source .md file")
    parser.add_argument("-o", "--output", type=Path, default=None, help="Output .pdf path (default: same name next to the source)")
    parser.add_argument("--title", default=None, help="Document title (default: first H1, else the file name)")
    parser.add_argument("--keep-html", action="store_true", help="Keep the intermediate HTML file next to the output PDF")
    parser.add_argument(
        "--browser",
        default=None,
        help=(
            "Path to a Chromium-based browser executable to use directly, "
            f"skipping auto-discovery (or set the {_BROWSER_ENV_OVERRIDE} env var)"
        ),
    )
    args = parser.parse_args()

    if not args.markdown_file.is_file():
        print(f"error: markdown file not found: {args.markdown_file}", file=sys.stderr)
        return 1

    markdown_text = args.markdown_file.read_text(encoding="utf-8")
    title = args.title or derive_title(markdown_text, args.markdown_file.stem)
    output_pdf = args.output or args.markdown_file.with_suffix(".pdf")

    browser = find_chromium_browser(explicit_path=args.browser)
    if not browser:
        print(
            "error: no Chromium-based browser found (checked PATH, the Windows "
            "App Paths registry, and common macOS install locations).\n"
            "Install one -- both are free -- then re-run this script, or point "
            f"at it directly with --browser <path> or the {_BROWSER_ENV_OVERRIDE} env var:\n"
            "  Chrome: https://www.google.com/chrome/\n"
            "  Edge:   https://www.microsoft.com/edge",
            file=sys.stderr,
        )
        return 2

    html_document = build_html_document(markdown_text, title)

    if args.keep_html:
        html_path = output_pdf.with_suffix(".html")
        html_path.write_text(html_document, encoding="utf-8")
    else:
        temp_handle = tempfile.NamedTemporaryFile(
            mode="w", suffix=".html", delete=False, encoding="utf-8"
        )
        temp_handle.write(html_document)
        temp_handle.close()
        html_path = Path(temp_handle.name)

    try:
        render_pdf(html_path, output_pdf, browser)
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        return 3
    finally:
        if not args.keep_html:
            html_path.unlink(missing_ok=True)

    print(f"OUTPUT_PDF={output_pdf}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
