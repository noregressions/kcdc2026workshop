# Book content trim — tracking list

The book renders at **308 letter pages for ~45,000 words (~150 words/page;
a normal technical page holds 350–450)**. The theme is not the problem —
pages flow continuously, type is already tight. The length comes from what
is included and how the trace files are written. This list tracks which
markdown files to **drop from the book** (pom.xml excludes — the files stay
in the repo/site) and which to **amend significantly**.

Companion to `BOOK-REVIEW-TODO.md` (which covers rendering/theme); this file
covers content selection and writing style only.

Page numbers reference the 2026-08-25 308-page letter build of `target/book.pdf`.

## Where the pages go today

| Section | Pages | Share |
|---|---|---|
| Front matter + Introduction and Setup | 33 | 11% |
| Parts 1–7 (timed workshop route) | 139 | 45% |
| Appendix — Optional Labs (S02) | 29 | 9% |
| Appendix — The Tools | 5 | 2% |
| Appendix — Reference Investigations | 102 | 33% |

The appendices are 44% of the book. The Reference Investigations appendix is
also the sparsest content in it (T07's trace: 1,515 words over 18 pages).

---

## A. Drop from the book (pom.xml `<include>` removals)

Certain wins — duplication or wrong audience. **~24 pages.**
**Done 2026-08-26** — all five includes removed from the shared book.

- [x] `investigations/T01-snyk-beyond-sbom/S01-TRACE.md` (pp. 207–213, 7pp)
  — long-form re-run of the S01 section already inside
  `investigations/T01-snyk-beyond-sbom/TRACE.md` (Part 2). Same ground
  truth, same Snyk runs, same conclusions.
- [x] `investigations/T01-snyk-beyond-sbom/S02-TRACE.md` (pp. 214–219, 6pp)
  — duplicates T01 TRACE.md § "S02 — Payara + mvnpm".
- [x] `investigations/T01-snyk-beyond-sbom/S03-TRACE.md` (pp. 220–226, 7pp)
  — duplicates T01 TRACE.md § "S03 — Python + PEP 517".
- [x] `investigations/T01-snyk-beyond-sbom/S05-TRACE.md` (p. 227, 1pp)
  — an unfinished stub: diagram + the three harness commands, no
  Observe/Establish, no findings. Drop from the book either way; separately
  decide whether to finish or delete the file.
- [x] `investigations/T01-snyk-beyond-sbom/KNOWN-GROUND-TRUTH.md`
  (pp. 126–128, 3pp) — frontmatter says `track: instructor-demo`, yet it
  ships in the attendee book. It restates S04 results the reader has just
  produced two chapters earlier. Fold a two-line pointer into the T01
  OVERVIEW instead.

## B. Decide: Reference Investigations appendix (the big one)

`T02`–`T07` OVERVIEW + TRACE pairs, pp. 228–308. **~81 pages, 26% of the
book**, and the lowest-density writing in it (84–130 words/page). Nothing
here is on the timed route; `reference/tools.md` already summarises what
each tool can and cannot see.

Options, pick one:

- [x] **Site-only** (recommended): keep them in `mvn site`, exclude from the
  PDF. Saves ~81pp with zero writing effort. The PDF keeps
  `reference/tools.md` as the appendix summary.
  **Done 2026-08-26** — the `pdf` execution now carries its own
  `<book combine.self="override">` without this section (and without
  Optional Labs); the shared `<book>` remains the site edition.
- [ ] **Overviews only**: keep each `OVERVIEW.md` (~1–2pp each), drop the six
  `TRACE.md` files from the PDF. Saves ~68pp.
- [ ] **Keep but rewrite** each TRACE to a 2–3 page findings summary
  (what the tool saw / missed / why), pointing at the repo for the
  step-by-step. Most work, saves ~55pp.

Files affected:

- `investigations/T02-docker-scout/{OVERVIEW,TRACE}.md` (10pp)
- `investigations/T03-trivy-s01/{OVERVIEW,TRACE}.md` (13pp)
- `investigations/T04-grype-s02/{OVERVIEW,TRACE}.md` (13pp)
- `investigations/T05-pip-audit-s03/{OVERVIEW,TRACE}.md` (13pp)
- `investigations/T06-owasp-dependency-check-s04/{OVERVIEW,TRACE}.md` (14pp)
- `investigations/T07-npm-audit-s05/{OVERVIEW,TRACE}.md` (18pp)

## C. Decide: Appendix — Optional Labs (S02)

- [x] `scenarios/S02-payara-mvnpm/{OVERVIEW,TRACE}.md` (pp. 173–201,
  **29pp**) — the longest single chapter in the book and explicitly off the
  timed route. If the PDF is the workshop handout, make it site-only; if the
  book is meant as the take-home reference, keep it but apply the section D
  amendments.
  **Done 2026-08-26** — site-only, via the same pdf-execution book override
  as section B.

## D. Amend significantly (kept files)

### D1. ~~Fill or remove the empty `Observed output` blocks~~ — RETRACTED

**Correction 2026-08-26:** the "81 empty fences" figure was a measurement
error — the regex matched a closing fence + blank line + the next opening
fence, i.e. ordinary adjacent blocks. A proper fence parser finds exactly
**two** empty fences (`S03-python-pep517/TRACE.md:239`,
`S04-maven-plugin-hidden-content/TRACE.md:595`), and both are deliberate:
the empty output *is* the finding ("There is no matching output"). No
action taken; nothing to fix.

### D2. De-fence the concept lists — biggest density win

**Done 2026-08-26** for every TRACE kept in the PDF: 81 fences converted
(S01 17, S03 11, S04 9, S05 7, T01 31, CVE-tomcat-85 6). Command blocks,
captured output, and alignment/arrow diagrams untouched. Not applied to the
now site-only S02 and T02–T07 traces — do those if they ever return to the
PDF.

Across the trace files, 42% of all lines sit inside code fences (802
blocks), and many fences hold *concept word-lists*, not commands or output
— e.g. a ```` ```text ```` block containing only
`package metadata / generator code / generator input`, or
`dependency graph != complete physical software inventory` as a one-line
fence. Each costs a bordered panel + padding + margins. Convert these to
bullets or bold prose. Applies to every TRACE file kept in the book;
worst: `scenarios/S01-spring-node/TRACE.md` (88 blocks),
`scenarios/S02-payara-mvnpm/TRACE.md` (89),
`investigations/T01-snyk-beyond-sbom/TRACE.md` (72).
Estimated saving across kept chapters: **15–25pp**.

### D3. Merge the duplicate setup entry points

- [x] `setup/01 getting-started.md` + `setup/01 intro.md` — two files both
  numbered `01`, overlapping (both cover "how to get ready", tool list vs
  container-vs-local). Merge into one `01 getting-started.md`; move the
  version table into `02 tools.md`. Saves ~3pp and removes a confusing
  double chapter.
  **Done 2026-08-26** — `01 intro.md` deleted; its minimum-environment
  table and Podman note moved into `02 tools.md`; its verified-baseline /
  pinned-versions / drift material moved to new repo-only
  `setup/VERSIONS.md`; its quick-verification list was a duplicate of
  `tools-check.sh` and was dropped. README pointer updated.

### D4. Condense the setup long-tail (book copies only)

- [x] `setup/02 tools.md` (7pp) — three full per-OS install walkthroughs
  plus a Podman section. The book needs the requirements table +
  `./scripts/tools-check.sh`; per-OS `brew`/`apt` transcripts can live in
  the repo/site.
  **Done 2026-08-26** — rewritten around `tools-check.sh` + the
  minimum-environment table + a one-block Homebrew shortcut; full per-OS
  transcripts, Podman install and manual verification moved to new
  repo-only `setup/INSTALL.md`.
- [x] `setup/04 PREPULL-PREWARM.md` (7pp) — 12 numbered warm-up steps, but
  its own §0 says `./scripts/build-all.sh` does everything. Lead with the
  one-command route and cut the per-step transcripts to a checklist.
  Together: **~8–10pp**.
  **Done 2026-08-26** — rewritten as the one-command route + a what-it-does
  table + the two steps it can't do for you (Snyk auth, T06/NVD warm); the
  full manual walkthrough moved to new repo-only `setup/PREWARM-MANUAL.md`.

## E. Fine as-is (checked, no action)

- `setup/frontpiece.md`, `setup/00 about.md`, `setup/03 ACCOUNTS-AND-KEYS.md`
- `workshop/01…07` part placeholders (2pp each — thin, but that's the
  presentation slot design; note `04-project-health-eol.md` is the only
  fleshed-out one at 6pp, an inconsistency to resolve in content-todo, not
  a length problem)
- `reference/tools.md` (5pp — earns its place; becomes the whole appendix
  if section B goes site-only)
- All scenario `OVERVIEW.md` files — short, distinct role (route pointer +
  prerequisites), no significant overlap with their TRACEs

## Expected outcome

| Action | Saving |
|---|---|
| A — drop T01 duplicates/stub/instructor file | ~24pp |
| B — Reference Investigations site-only | ~81pp |
| C — S02 optional lab site-only | ~29pp |
| D — style amendments on kept files | ~25–35pp |

A alone: **~284pp**. A+B: **~203pp**. A+B+C: **~174pp**.
A+B+C+D: **~140–150pp** — right-sized for ~45k words.

**Actual result 2026-08-26:** all sections applied (D1 retracted as a
measurement error), rebuilt with `mvn process-resources`:
**308 → 168 pages.** The PDF is the timed route + The Tools appendix; the
site keeps Optional Labs (S02) and Reference Investigations (T02–T07).
