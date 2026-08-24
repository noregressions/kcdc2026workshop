#!/usr/bin/env bash
#
# generate-toc.sh — (re)generate the book's table of contents.
#
# Paperband has no native book-level TOC, so this script builds one:
#
#   1. builds the book (mvn package)
#   2. extracts each part's and card's REAL start page from the rendered
#      PDF itself (pdftotext + sequential title matching) — the plugin's
#      reportPages table was observed to drift from the rendered truth
#   3. writes "setup/000 contents.md" (the book's first card)
#   4. repeats — inserting/updating the TOC shifts every later page, so it
#      iterates until the numbers stop moving (normally 2 passes)
#
# Run this after any change that adds, removes or resizes book content.
# The page numbers are valid for the FULL book only; the card carries no
# `track:` so the core-only filtered build excludes it.

set -euo pipefail
cd "$(dirname "$0")/.."

TOC_FILE="setup/000 contents.md"
MAX_PASSES=4

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
command -v pdftotext >/dev/null || { echo "pdftotext (poppler) is required" >&2; exit 1; }

# Seed a stub so pass 1 paginates with a TOC card of roughly the right size.
if [[ ! -f "$TOC_FILE" ]]; then
  printf -- '---\nid: book-contents\noneliner: "Where everything is."\n---\n\n# Contents\n\n(generating)\n' > "$TOC_FILE"
  echo "Seeded $TOC_FILE"
fi

echo "== Reading book structure =="
mvn paperband:structure > /tmp/toc-structure.log 2>&1 || {
  echo "paperband:structure failed:" >&2; tail -5 /tmp/toc-structure.log >&2; exit 1; }

pass=1
while [[ $pass -le $MAX_PASSES ]]; do
  echo "== Pass $pass: building =="
  mvn package > /tmp/toc-build.log 2>&1 || {
    echo "build failed:" >&2; tail -10 /tmp/toc-build.log >&2; exit 1; }
  pdftotext -layout target/book.pdf /tmp/toc-book.txt

  cp "$TOC_FILE" /tmp/toc-previous.md

  python3 - "$TOC_FILE" <<'PY'
import io, re, sys

toc_file = sys.argv[1]

# --- titles + order, from paperband:structure -------------------------------
sections = []                     # [(part_title, [(card_id, card_title)])]
for line in io.open('/tmp/toc-structure.log', encoding='utf-8'):
    m = re.match(r'\[INFO\]\s+SECTION\s+\S+\s+"(.+)"\s+\[', line)
    if m:
        sections.append((m.group(1), []))
        continue
    # greedy up to the closing quote before the (file) — titles may contain quotes
    m = re.match(r'\[INFO\]\s+CARD\s+(\S+)\s+"(.+)"\s+\(', line)
    if m and sections:
        sections[-1][1].append((m.group(1), m.group(2)))

# --- page numbers, measured from the rendered PDF ---------------------------
# Sequential title matching: walk the pages once, advancing through the
# expected sequence of (divider title, card titles...). Running header and
# footer lines are filtered out before matching.

def norm(t):
    return re.sub(r'\s+', ' ', t).strip().casefold()

# header/footer lines to ignore when reading a page's opening lines
book_title = None
for line in io.open('/tmp/toc-structure.log', encoding='utf-8'):
    m = re.search(r'BOOK\s+"(.+)"\s+\[', line)
    if m: book_title = norm(m.group(1)); break
pom = io.open('pom.xml', encoding='utf-8').read()
m = re.search(r'<subtitle>(.*?)</subtitle>', pom)
subtitle = norm(m.group(1)) if m else None

expected = []                     # [('divider'|card_id, title)] in book order
for part_title, cards in sections:
    expected.append(('divider', part_title))
    for cid, ctitle in cards:
        expected.append((cid, ctitle))

pages = io.open('/tmp/toc-book.txt', encoding='utf-8', errors='replace').read().split('\f')
found = {}                        # index into expected -> page number
idx = 0
for pageno, page in enumerate(pages, 1):
    if idx >= len(expected):
        break
    lines = [norm(l) for l in page.split('\n') if l.strip()]
    header_line = f"{book_title} {subtitle}" if subtitle else book_title
    lines = [l for l in lines
             if l not in (book_title, subtitle, header_line)
             and not re.fullmatch(r'page \d+ of \d+', l)]
    head = ' '.join(lines[:3])
    want = norm(expected[idx][1])
    # a long title may wrap; match on a generous prefix of the joined head
    probe = want if len(want) <= 60 else want[:60]
    if head.startswith(probe) or (lines and lines[0] == want):
        found[idx] = pageno
        idx += 1
        # a divider and its same-titled first card sit on consecutive pages;
        # loop continues so the card matches on the next page

missing = [expected[i][1] for i in range(len(expected)) if i not in found
           and expected[i][0] != 'book-contents']
if missing:
    sys.exit("could not locate in the rendered PDF: " + "; ".join(missing[:5]))

divider_pages = []
card_page = {}
for i, (kind, title) in enumerate(expected):
    if kind == 'divider':
        divider_pages.append(found[i])
    else:
        card_page[kind] = found[i]

# --- render ------------------------------------------------------------------
WIDTH = 74
def entry(title, page, indent):
    page_s = str(page)
    room = WIDTH - indent - len(page_s) - 2
    if len(title) > room:
        title = title[:room - 1] + '…'
    dots = '.' * (WIDTH - indent - len(title) - len(page_s) - 2)
    return f"{' ' * indent}{title} {dots} {page_s}"

lines = []
for (part_title, cards), div_page in zip(sections, divider_pages):
    lines.append(entry(part_title, div_page, 0))
    for cid, ctitle in cards:
        if cid == 'book-contents':
            continue                       # the TOC does not list itself
        if cid not in card_page:
            sys.exit(f"card {cid} missing from page report")
        lines.append(entry(ctitle, card_page[cid], 2))
    lines.append('')

body = "\n".join(lines).rstrip()

out = f"""---
id: book-contents
oneliner: "Every part and chapter of the book, with its page."
---

# Contents

Page numbers are for the complete book
(regenerate after content changes: `./scripts/generate-toc.sh`).

```text
{body}
```
"""
io.open(toc_file, 'w', encoding='utf-8').write(out)
print(f"   wrote {toc_file}: {sum(len(c) for _, c in sections)} cards in {len(sections)} parts")
PY

  if cmp -s "$TOC_FILE" /tmp/toc-previous.md; then
    echo "== Stable after pass $pass =="
    echo "Final book: $(ls -la target/book.pdf | awk '{print $5}') bytes"
    exit 0
  fi
  pass=$((pass + 1))
done

echo "WARNING: page numbers did not stabilise in $MAX_PASSES passes" >&2
exit 1
