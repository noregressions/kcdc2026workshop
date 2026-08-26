# Facilitator Notes

Instructor-side companion to [`WORKSHOP.md`](./WORKSHOP.md). Attendees never
need this file.

Every timing marked **measured** comes from a verified run on the
reference machine (2026-08-24, warm caches). Machine time is a floor; the
budgets are dominated by narration, typing and reading.

> Parts 1, 3 (presentation half), 4, 5, 6 and 7 still have placeholder
> presentation content. Their notes below cover what exists and hold the
> timing structure for what doesn't.

---

## Before the day

On the machine you will present from, the night before, on a good network:

```bash
./scripts/tools-check.sh          # must exit 0
./scripts/build-all.sh            # must report 0 failed
snyk whoami                       # must print your account — T01 demo needs it
printenv NVD_API_KEY              # should be set — raises NVD rate limits
cd investigations/CVE-tomcat-85 && ./scripts/proof-check.sh   # must pass 14/14
```

**The container escape hatch:** an attendee whose machine resists all
fixing can run everything from the workshop container — only Docker needed:
`./container/build.sh && ./container/run.sh` (or pre-pulled images).
Two images: the big tools/base one and the small code one on top. Publish
both to a registry before the workshop so the fallback is a pull, not a
build — and **rebuild the base close to workshop day**
(`./container/build.sh --base`): the scanner databases are baked into it
and age with it.

Then run the T01 demo once end-to-end (`baseline.sh`, `run-snyk.sh`,
`compare.sh`) so the results are fresh in `results/`: that is your fallback
if Snyk or the venue network dies mid-demo.

**Live-network dependencies during the workshop** (everything else runs
offline after prewarm):

| Moment | Needs network | Fallback |
|---|---|---|
| Part 1 machine check (stragglers) | image pulls + scanner DBs | that is the point — it fails during talk time |
| Part 2 Step 4: `run-snyk.sh` | Snyk API (~37s, **measured**) | yesterday's `results/` output |
| Part 3 Tomcat `curl`s | CVE.org + NVD APIs | `evidence/` captures — attendees should use these anyway |
| Part 4 guided web | Scorecard, OSS Index, EOL sites | `evidence/` — Scorecard report captured; **OSS Index + EOL report TODO** |

**Room advice for Part 3:** tell attendees to run the `jq` against the
captured `evidence/` files, not the live `curl`s. Forty people hitting NVD
without API keys meets a 5-requests-per-30-seconds rate limit.

---

## The clock

Nominal start 0:00. Write the actual wall-clock equivalents on a slide or
whiteboard at the start and update at the break.

```text
0:00        Part 1  Supply-chain fundamentals        15 min
0:15        Part 2  Can we identify what we ship?    60 min
1:15        Part 3  What does a CVE finding mean?    35 min
1:50        BREAK                                    15–20 min
2:10        Part 4  CVEs aren't enough               25 min
2:35        Part 5  Exploiting the gaps              25 min
3:00        Part 6  AI and the supply chain          20 min
3:20        Part 7  Wrap-up                          10 min
3:30        end
```

**Announce the restart time before the break starts, twice, and put it on
screen.** Nominal 15 minutes; treat 20 as the hard limit and restart with
whoever is present.

Checkpoints for "are we on time":

```text
by 0:45   S01 and S04 both done          if not: S05 and S03 become demos
by 1:15   Part 2 closed with the table   if not: compress the table talk-through
by 1:45   Tomcat steps 1–6 done          if not: jump to steps 7–8 (never cut those)
```

---

# Part 1 — Supply-chain fundamentals (0:00–0:15)

**Status: presentation is a placeholder.** [`workshop/01-supply-chain.md`](./workshop/01-supply-chain.md)
holds the outline. The machine check below works today.

**First slide / first words:** get them typing before you start talking.

```bash
./scripts/tools-check.sh     # fix what it flags — it prints install links
./scripts/build-all.sh
```

- Prewarmed machine: both re-verify in ~1–2 minutes (**measured:** warm
  `build-all` 1m12s).
- Skipped-homework machine: image pulls plus scanner DBs, several minutes on
  conference wifi. **That is by design**: the failure is absorbed during talk
  time. Circulate; fix machines while you present.

**Question to the room** (end of the part):

> Can you tell me exactly what software this application contains?

Take two or three answers. Do not correct them: write them down and return
to them in Part 7.

**Intended conclusion:** "list the dependencies" and "list the software" are
different questions.

**Transition:** "If that question sounds easy, the next 55 minutes is where
it stops being easy."

**If running late:** compress the why-we-care list. Never cut the machine
check.

---

# Part 2 — Can we identify what we ship? (0:15–1:15)

Four attendee exercises + one instructor demo, covering Java, npm and
Python. The slack is thinner now (~5 min): protect it for questions.

## Step 1 — S01 transformation (0:15–0:30) — everyone types

**Measured:** build 7s warm; all commands ~8s. The 15 minutes is narration.

| Command | Expect |
|---|---|
| `mvn -pl service dependency:tree -Dincludes=...jackson-databind` | one line: `jackson-databind:jar:2.19.4:compile` |
| `syft service/target/service-1.0.0.jar \| grep -i jackson` | six `jackson-* 2.19.4` rows |
| `syft normalizer/target/normalizer-1.0.0.jar` | `commons-codec 1.17.1` + `normalizer 1.0.0` |
| `./scripts/strip-codec-metadata.sh` | Before/After — codec **gone** from the After scan |
| `npm --prefix frontend ls lodash` | `lodash@4.17.21` |
| `grep -oE "__lodash_hash..." dist/assets/*.js` | `1 4.17.21`, `1 __lodash_hash_undefined__` |
| `syft frontend/dist` | `No packages discovered` |

**Questions to the room:**

- after the strip: *"Not one byte of code changed. Who deleted commons-codec?"*
- after the lodash leg: *"I can grep the fingerprints. Why can't the scanner
  say 'lodash'?"* (fingerprint ≠ matchable package identity)

**Intended conclusion:** `software presence != software identifiability`.
Make the room say it, not you.

**Failure watch:** attendee adds `-q` to the mvn command → tree output
vanishes entirely (it prints at INFO). Tell them to drop `-q`.

**If running late:** drop the lodash leg to just `syft frontend/dist`
(saves ~3 min). Never cut the strip experiment.

## Step 2 — S04 hidden build content (0:30–0:45) — everyone types

**Measured:** build 5s warm; commands ~2s.

| Command | Expect |
|---|---|
| `mvn -Dmaven.repo.local=... dependency:tree` | root artefact, **zero** dependencies |
| `./scripts/run.sh` | `Runtime started as PID …` on **8082** |
| `curl …/hidden/build-info \| jq` | JSON naming `trace-route-payload` and `trace-injector-maven-plugin` |
| `unzip -l … \| grep -E 'Generated\|services'` | `GeneratedTraceRoute.class` + `META-INF/services/…` |
| `./scripts/stop.sh` | `Stopped runtime PID …` |

**Theatre tip:** pause after the empty tree. Ask *"so this application has no
dependencies, agreed?"* Get nods. Then curl the endpoint.

**Question to the room:** *"The endpoint told you where it came from. What in
the dependency tree would have told you?"* (nothing)

**Intended conclusion:** an empty dependency tree does not mean no
third-party software shaped the application.

**Failure watch:** port 8082 busy → `run.sh` refuses with a clear message;
usually a neighbour's undead runtime: see the failure playbook. Remind the
room to run `stop.sh`; the next exercise's `run.sh` will police it anyway.

**Never cut this step.**

## Step 3 — S05 npm prepack (0:45–0:53) — everyone types *(demo if late)*

**Measured:** build 1s; commands ~1s. Port **8083**.

Expect: two `npm notice run` lines in the build output (the prepack
executing), three files in the tarball including generated `dist/`, and the
endpoint returning `"event": "npm-prepack-generated"`.

**Intended conclusion:** same pattern, different ecosystem: this is a
property of build systems, not of Maven.

**If running late: this is the first cut in the whole workshop.** Run it
yourself on the projector in ~3 minutes instead of 8. S03 (next) is the
second cut, the same way.

## Step 4 — S03 Python PEP 517 (0:53–1:01) — everyone types *(demo if late)*

**Measured:** build 3s from clean (the venv is rebuilt every time, so the
pip evidence always shows); commands ~1s. Port **8081**.

| Command | Expect |
|---|---|
| `./scripts/build.sh` | `Getting requirements to build wheel` + `Building wheel for tracehook-demo` in the pip output |
| `tar -tzf python-repo/tracehook_demo-1.0.0.tar.gz` | **two files** — `pyproject.toml` and `tracehook_backend.py`; no package code |
| `ls .venv/lib/python*/site-packages/tracehook_demo/` | generated `__init__.py` + `build-hook.json` |
| `./scripts/run.sh` … `curl …:8081/trace \| jq` | `"event": "pep517-build-backend-executed"` |
| `./scripts/stop.sh` | `Stopped runtime PID …` |

**Theatre tip:** the tar listing is the moment: hold on it. *"Two files.
Which one is the package you import?"* (neither)

**Intended conclusion:** Maven plugins, npm hooks, PEP 517 backends. Three
ecosystems, one property. This is not a quirk of anything.

**If running late:** demo it in ~3 minutes; the tar listing and the curl are
the two commands that must be seen.

## Step 5 — T01 scanner demo (1:01–1:06) — **instructor only**

```bash
cd investigations/T01-snyk-beyond-sbom
./scripts/baseline.sh     # measured: 9s — syft sees only the app archive
./scripts/run-snyk.sh     # measured: 37s — LIVE NETWORK, narrate over it
./scripts/compare.sh      # instant — ends on five interpretation questions
```

Narrate during the 37 seconds: *"Snyk knows more than the SBOM did. Watch
whether more analysis produces the two names we know are missing."* It
doesn't.

**Intended conclusion:** better analysis of available evidence does not
create missing evidence.

**Fallback:** venue network or Snyk auth fails → walk through yesterday's
`results/` files; the compare output is identical.

## Close of Part 2 (1:06–1:15)

Talk through the evidence table in WORKSHOP.md: each row is something they
just did, so point backwards, not forwards. Then the transition:

> "So far we asked *what is present*. Now: what happens when an inventory
> entry meets a vulnerability database?"

---

# Part 3 — What does a CVE finding mean? (1:15–1:50)

**Status: presentation half is a placeholder**
([outline](./workshop/03-vulnerabilities.md), framed by
[the foojay.io article](https://foojay.io/today/the-real-mechanics-of-vulnerabilities-in-an-upstream-downstream-topsy-turvy-eol-world/)).
The guided investigation is built and verified.

Guided part: [`investigations/CVE-tomcat-85/TRACE.md`](./investigations/CVE-tomcat-85/TRACE.md).
Attendees follow on their machines **using the captured `evidence/`
files**; you optionally run the live `curl`s on the projector. All `jq`
steps are sub-second (**measured**).

Suggested pacing over 35 minutes:

```text
~8 min    presentation: the delta model, the finding pipeline
~5 min    steps 1–2   CNA record; Important vs 7.5 vs 9.8
~5 min    steps 3–4   what a CPE is; the 38 entries (20 Oracle)
~6 min    steps 5–6   57 edits; Oracle CPEs +26 months; KEV two years late
~8 min    steps 7–8   the EOL double exhibit (6.x absent; 8.5 named-but-unbounded)
~3 min    checkpoint questions
```

**Questions to the room:**

- after step 2: *"Which severity is correct?"* (trick: they're different
  producers' claims)
- after step 5: *"You scanned an Oracle product in March 2022 and again in
  May 2022. The software never changed. What did?"*
- after step 7: *"Your scanner says nothing about your Tomcat 6 box. What do
  you actually know?"* (that nobody looked)

**Intended conclusion:** *A CVE is a record of an event that continues to
evolve, not a point-in-time fact.*

**If running late:** compress steps 5–6 into the timeline table (section 9).
**Never cut steps 7–8**: the EOL distinction is on the never-cut list.

**Set up the break:** "We've spent two hours discovering problems. After the
break, we decide what to do about them. Back at **[time on screen]**."

---

# BREAK (1:50–2:10)

Restart time on screen before anyone stands up. Restart with whoever is
back. Use the break to fix any machine still broken from Part 1.

---

# Part 4 — CVEs aren't enough (2:10–2:35)

**Status: scripted (draft).** [`workshop/04-project-health-eol.md`](./workshop/04-project-health-eol.md)
carries the full guided route (lodash through Scorecard and OSS Index, then
the EOL sweep, OpenEoX, three-question model). WORKSHOP.md carries the
compact attendee version. Cloudsmith was dropped from the workshop entirely
(2026-08-24): Scorecard covers the health lens.

Before the room:

- **Fallback captures** (the drill: this section is all live web): the
  Scorecard lodash report is captured
  (`workshop/evidence/openssf-scorecard-lodash-2026-08-18.pdf`; the doc
  quotes its numbers). Still to capture into `workshop/evidence/`: an OSS
  Index response for `pkg:npm/lodash@4.17.21`, and a fresh
  `herodevs.report.json` from the repo root. Re-capture near the workshop
  date: the drift between the doc's
  quoted numbers and the live pages is a teaching beat, not a bug.
- **Auth:** `hd scan eol` needs a HeroDevs login. Do `npx @herodevs/cli auth
  login` on the presenter machine beforehand; attendees without accounts
  read the captured report. Don't spend room time on sign-ups.
- **The gift in the data:** S01 runs on Spring Boot 3.5, past OSS EOL since
  30 June 2026. Land that line looking at the room: *the thing you built
  this morning is the case study*.
- **Declared interest:** say the HeroDevs line out loud before the sweep
  (it's in the doc). It buys credibility for everything after it.

Timing and cuts:

- **Intended conclusion:** *CVE data tells us what is known to be broken
  now. Lifecycle data helps tell us who is expected to fix what breaks
  next.* End on the three-question model.
- **If running late:** the detailed Scorecard exploration is the cut (keep
  Maintained + Vulnerabilities only). Never cut the EOL distinction.

---

# Part 5 — Exploiting the gaps (2:35–3:00)

**Status: PARTLY BUILT** — [`workshop/05-integrity-provenance.md`](./workshop/05-integrity-provenance.md).
The **S07 reverse-provenance lab is built** (`scenarios/S07-provenance-s01`,
evidence captured, proof-check 7/7). The S06 cache-integrity lab is still
deferred until after the first rehearsal.

Running notes:

- Reframe S04/S05 verbally: *"Everything you did before the break was
  legitimate. Now imagine each mechanism used on purpose."*
- **GuardDog** demo (investigation `T08-guarddog`, evidence captured): two
  clean results for opposite reasons plus a malicious positive control. Frame
  it as reading code, not dynamic execution. Ties back to Part 2's strip
  experiment.
- **S07 reverse-provenance lab** (~10–12 min): start from S01's finished image
  and fail to trace it, then add git → OCI labels → SBOM → attestation. Two
  presenter cautions: it needs **Docker plus a throwaway local registry** (the
  script starts `registry:2`), and it installs `syft`/`cosign` — do this
  before the room, not live. (Inside the workshop container, syft/cosign and
  a registry can be pre-baked.) Landing line: provenance is a ladder and only
  the signed attestation is *verifiable* by someone who does not trust your
  build.
- **Intended conclusion:** control what comes in; verify the bytes you
  receive; preserve evidence of how they were produced.
- **If running late:** the S07 lab is the cut (talk through its evidence
  captures instead of running it). Never cut the three controls.

---

# Part 6 — AI and the supply chain (3:00–3:20)

**Status: PLACEHOLDER** — [`workshop/06-ai-dependencies.md`](./workshop/06-ai-dependencies.md).
The malware sample and the hallucination evidence are not chosen yet.

Holds until built:

- **Safety rule, non-negotiable:** the AI-generated malware dissection runs
  only on the instructor machine, isolated: never distributed, never on
  attendee machines.
- **Intended conclusions:** an AI-suggested dependency enters the same
  supply chain with less human scrutiny; a hallucinated package name is
  free attack surface.
- **If running late:** this segment compresses to the two conclusions plus
  one slide of hallucination evidence: the dissection is the cut, painful
  as that is. Never cut the slopsquatting warning; it is the single most
  actionable minute in the segment.

---

# Part 7 — Wrap-up (3:20–3:30)

Return to the Part 1 answers you wrote down. Read them back. Ask the room
what they would answer now.

Walk the final evidence model (in WORKSHOP.md), the "when you get home"
checklist, then land the operating model. **Never cut the final model**: if
everything has gone wrong, this is the ten minutes that must survive.

Point at the appendices, S02 (Jakarta EE), S03 (Python) and T02–T07: "same
lessons, your ecosystem, self-study."

---

## Escape hatches — the ordered cut list

Cut in this order, never the reverse:

```text
1. S05 attendee exercise  →  3-minute instructor demo        saves ~5 min
2. S03 attendee exercise  →  3-minute instructor demo        saves ~5 min
3. S01 lodash leg         →  syft dist only                  saves ~3 min
4. Part 3 steps 5–6       →  compressed into the timeline    saves ~5 min
5. Part 4 Scorecard depth                                    saves ~5 min
6. Part 5 attack taxonomy breadth                            saves ~5 min
```

**Never cut:** the Part 1 machine check · S01's strip experiment · S04 ·
Tomcat steps 7–8 (EOL) · the EOL distinction in Part 4 · the slopsquatting
warning in Part 6 · the final evidence model in Part 7.

---

## Failure playbook

**Port already in use (8082/8083/8080/8081).** `run.sh` refuses and says so.
Fix: `./scripts/stop.sh` in that scenario. If the PID file is gone but the
process lives (it happens: a clean deleted the file first):

```bash
lsof -nP -iTCP:8082 -sTCP:LISTEN     # find the PID
kill <pid>
```

**"permission denied" running a script.** Exec bits lost (zip download
instead of git clone, odd filesystems). Fix: `chmod +x scripts/*.sh` in that
directory, or `bash scripts/whatever.sh`.

**`mvn -q dependency:tree` shows nothing.** `-q` suppresses INFO and the
tree prints at INFO. Drop the `-q`.

**`build-all` failing on one phase.** It never aborts: it records the
failure and continues, and the summary names every problem. Read the
summary, not the scrollback. Exit non-zero means something needs attention.

**Docker not running.** `build-all` says so and skips image phases;
scenario `run.sh` for S02 needs it, S04/S05 do not. Docker Desktop takes a
minute to start: set it going and continue talking.

**Snyk demo fails.** `snyk whoami` errors → not authenticated; `snyk auth`
needs a browser round-trip: do not attempt it live. Use yesterday's
`results/` output.

**NVD curls hang or 403.** Rate limit (5 req/30s without a key). The
investigation is designed for this: use `evidence/` files.

**Docker suddenly read-only / builds die with I/O errors.** The host disk
is full — Docker Desktop's VM remounts read-only when the host runs out.
Fix: free host space, fully quit and restart Docker Desktop, then
`docker system prune`. `tools-check.sh` warns below 20GB free for exactly
this reason.

**An attendee's machine is unrecoverable.** Pair them with a neighbour
(every exercise reads fine over a shoulder) and fix it at the break.

**Everything is on fire.** The book (`target/book.pdf`) contains every
observed output. You can run the entire workshop as a guided read of real
captured evidence without executing anything. It is worse, but it works.

---

## After the workshop

Health checks you can run to see what state the room left the repo in:

```bash
for p in 8080 8081 8082 8083; do lsof -nP -iTCP:$p -sTCP:LISTEN; done
docker ps
./scripts/build-all.sh --list
```

Per-lab `proof-check.sh` scripts assert each walkthrough's claims still
hold. T06's asserts exact NVD-derived counts and is *expected* to drift as
the database moves. The Tomcat investigation's `proof-check.sh` will
likewise eventually fail on the history lower bound when NVD edits the
record again: both by design. A failure there means "refresh the recorded
numbers", not "the lesson broke".
