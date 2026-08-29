# Book editorial TODO

From the full-book editorial pass (2026-08-29). Small fixes — filler, wordiness,
stale beat lines, misplaced paragraphs — were applied directly; everything here
was judged too big for a line edit. Grouped by theme, roughly most-urgent first.
Companion files: `BOOK-REVIEW-TODO.md`, `BOOK-CONTENT-TRIM.md`.

## Content gaps

- [ ] **Six of seven spine chapters are placeholders.** workshop/01, 02, 03, 05,
  06, 07 carry `status: placeholder` and a "presentation content to be written"
  banner; only 04 is drafted. The labs are polished — the narrative a
  participant reads *between* them is the largest remaining gap in the book.
- [ ] **`setup/frontpiece.md` is empty** — the first content page after the
  cover is just "# Welcome". Write a short welcome/epigraph, or drop the
  Welcome section from both POM editions.
- [ ] **workshop/04 has author-TODOs in participant view**: "*capture pending,
  see FACILITATOR.md*" in Steps 2 and 3. Capture the `workshop/evidence/`
  responses and delete the notes; verify `evidence/` holds the Scorecard
  capture the intro promises.
- [ ] **workshop/05 plans around "S06 (to be built)"** — decide: build the
  integrity lab or cut the reference before writing 05.
- [ ] **workshop/04's opening assumes 03 delivers the Ghostcat story**
  ("Part 3 ended with a CVE record that changed its answers over six years") —
  holds on paper, not yet on the page; keep in mind when writing 03.

## Stale cross-references (mostly fallout from removing CVE-tomcat-85 from the book)

- [ ] **reference/tools.md** points at "the *Prerequisites* chapter's verified
  baseline" — no chapter has that title, and the Verified Baseline lives in
  `setup/VERSIONS.md`, which is not in either book edition. Include
  VERSIONS.md or repoint the sentence.
- [ ] **reference/tools.md** references "the Tomcat investigation" three times
  (NVD change history, the four API captures, `evidence/`) plus the
  Ghostcat/KEV example — that chapter is now repo-only. Rephrase as repository
  references or trim.
- [ ] **workshop/03 (when written)** must point its guided web-investigation
  segment at the repo copy of `investigations/CVE-tomcat-85` (or the lab gets
  reinstated in the book).
- [ ] **S01 TRACE closing line** ("A separate reverse-provenance exercise
  should examine…") should point at S07, which now exists and reuses S01's
  image — wording depends on the S07-in-book decision below.
- [ ] **S03 TRACE step 13** justifies port 8081 by pointing at S02, which
  core-route readers meet only in the optional appendix. Reword to "alongside
  the other scenarios' runtimes".
- [ ] **T01 OVERVIEW**: opens as "an investigation over S04" though the TRACE
  spans all five scenarios (reframe with S04 as the live-demo centrepiece);
  status fence still says `S05 … next` though the S05 section is complete;
  "See `S02-TRACE.md` / `S03-TRACE.md`" are repo-only pointers for book
  readers; the Snyk CLI version (1.1305.2) is recorded here but missing from
  the TRACE's "The instrument".

## Open inclusion decisions

- [ ] **T08 (GuardDog) has never been in the book** — the site edition's
  Reference Investigations appendix lists T02–T07 only; looks like an
  oversight. One include pair adds it.
- [ ] **S07 (reverse provenance) is in neither edition.** Decide; the S01
  closing pointer above depends on it.
- [ ] **setup/VERSIONS.md** — include in the book or stop referencing it
  (see tools.md item).

## Beat-grammar consistency (decide the policy once, then apply)

- [ ] **The five-beat promise vs practice**: setup/00 says every scenario step
  has five beats, but S05 steps 7–11/13/14 have no `Why`, many S04/S05 steps
  put output directly under `Run` with no `Observed output` heading, and
  S02/S03 step 1 use a one-line short form. Either soften the promise
  ("beats appear as needed") or add the missing headings.
- [ ] **S02 TRACE step 2 has inverted heading hierarchy** (`### tracer` above
  `## Run`), which the book renderer may group oddly; steps 13/14/16 have two
  `## Run` beats each. Restructure or bless the pattern.
- [ ] **T05 probes 5–6 have no Run beat** where probes 1–4 do — a one-line
  pointer to `run-pip-audit-s03.sh` evens it out.

## OVERVIEW ↔ TRACE duplication and spoilers

- [ ] **T05/T06/T07 OVERVIEWs restate the TRACE scorecards in detail**
  ("Canonical results" / "Core result") — the numbers now live in two places
  and will drift. Trim each OVERVIEW to scenario/tool/question/run plus a
  one-line headline. Related: decide the spoiler policy — T04's OVERVIEW gives
  away 169/169/169 up front while T08's deliberately keeps results last.
- [ ] **T06 duplicates the NVD-key sign-up walkthrough** from setup/03 (which
  the book includes earlier). Keep only "Using the key with T06" and point at
  setup/03. Also: T06 claims the key "changes which tool version runs" but the
  12.2.2 no-key fallback is documented only in README/setup — add the fact or
  soften the claim.
- [ ] **S04 OVERVIEW's large ASCII flow** repeats the TRACE's conceptual
  section back-to-back in the book; slim it (and see the diagram item below).

## Evidence recaptures (need a re-run, not an edit)

- [ ] **T02**: no Docker Scout version recorded — capture `docker scout version`
  and pin it in "The instrument" (T03/T04 both pin theirs).
- [ ] **T02**: both probes present Syft's output before Docker Scout's, though
  Scout is the instrument under test — reorder the observed blocks on recapture.
- [ ] **S03 step 7**: the `Observed output` beat has prose but no captured
  output — capture the actual `build_wheel()` grep lines.
- [ ] **T05 probes 3–4**: the Run fences show abbreviated, non-runnable
  commands (`pip-audit --no-deps ...`) — show the harness invocation or note
  the elision.
- [ ] **T07 Finding 1's fence** reads as a broken sentence ("installed files /
  did not change / vulnerability result") — authored fence, needs a rewrite.
- [ ] **S05 step 3's captured output includes `.DS_Store`** — recapture clean.
- [ ] **T01, S03 "package artefact boundaries" probe**: the Expectation
  restates the Question instead of predicting — state what was actually
  expected (standalone Python artefact scans unsupported for lack of an
  anchoring manifest?). Needs the author.
- [ ] **setup/01**: the container fence contains the placeholder
  "or: docker pull <published image, when available>" — supply the real image
  name or remove before the workshop.

## Setup-section structure

- [ ] **setup/03 heading levels are mixed**: "## Snyk" vs its four h1 siblings
  ("# NVD API key for T06", "# Docker account", …) — pick one level.
- [ ] **setup/01's numbered steps are h2**, rendering at the same level as the
  Option A/B headings they belong under — consider h3.
- [ ] **setup/01 vs 02 ownership overlap**: both narrate tools-check + install;
  decide the owner (02 could become the reference table, "Tools and
  Versions"). The Podman/Scout caveat still appears in both 02 and 03 — pick
  one canonical home.

## Polish / consistency niggles

- [ ] S04 verifies control endpoint before the hidden one; S05 does the
  reverse — S04's control-first order argues better; match them.
- [ ] S04 vs S05 OVERVIEW requirements phrasing drift ("jq optional" vs "jq
  for the manual walkthrough formatting") — one style.
- [ ] T07 OVERVIEW says "Observed tooling" where T05/T06 say "Tool" — one
  heading.
- [ ] S01 OVERVIEW: "### Compare service SBOM viewpoints" is stranded under
  "## Repository shape"; move it to "## Follow the trace".
- [ ] S01 OVERVIEW prerequisites list omits `unzip`, which the TRACE uses.
- [ ] Two more text chains are convertible to mermaid like their siblings:
  S04 OVERVIEW's flow (clean three-way fan-out) and S05 TRACE's closing
  evidence chain (~line 648).
- [ ] The mermaid label fix in `src/main/paperband/styles/diagrams.css`
  (mermaid's `class="label"` collides with the theme's uppercase
  eyebrow/label rule) belongs upstream in the paperband `noregressions`
  theme eventually.
