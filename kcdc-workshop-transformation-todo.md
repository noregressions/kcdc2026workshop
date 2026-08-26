# KCDC 2026 Workshop Transformation TODO

## Target workshop shape

The canonical attendee route will be:

```text
1. What is in our software?
        ↓
2. Can we actually identify it?
        ↓
3. What does a vulnerability finding really mean?
        ↓
4. What else should we know about a dependency?
        ↓
5. Can we trust how the software got here?
        ↓
6. What should we do differently?
```

Target duration:

```text
Part 1   Supply-chain fundamentals              15 min
Part 2   Dependency discovery + hidden software 55 min
Part 3   CVE/CPE/vulnerability process          35 min

BREAK                                           15–20 min

Part 4   Project health + EOL                   25 min
Part 5   Attacks, integrity + provenance        35 min
Part 6   Wrap-up                                10 min
```

This gives roughly **175–180 minutes including the break**, with a little flexibility for questions and lab slippage.

---

# P0 — Establish the canonical workshop

These are the things that need doing before adding any more demonstrations.

- [x] Create `WORKSHOP.md` as the single canonical attendee walkthrough. *(Done 2026-08-24: complete six-part route; S00/Tomcat/S06/S07 stops marked ⚠ PLACEHOLDER.)*
- [x] Make `README.md` describe the repository and direct workshop attendees to `WORKSHOP.md`.
- [x] Stop presenting S01–S05 and T01–T07 as a sequence attendees are expected to complete. *(WORKSHOP.md is the route; track tags + visible lines mark everything else optional/reference.)*
- [x] Mark every existing scenario as one of:
  - `CORE`
  - `INSTRUCTOR-DEMO`
  - `OPTIONAL`
  - `REFERENCE`

  **Done 2026-08-24** as a `track:` frontmatter key (lowercase values: `core`,
  `instructor-demo`, `optional`, `reference`) on all 34 cards, plus a visible
  "Workshop track:" line under each OVERVIEW title. Assignments: S01/S04/S05
  and setup → core; S02/S03 → optional (Jakarta EE / Python pointers); T01
  main + ground truth → instructor-demo; T01 sub-traces and T02–T07 →
  reference. Machine-usable via paperband select. A core-only attendee book:

  ```bash
  mvn paperband:build -Dpaperband.output=target/book-core.pdf -Dpaperband.select=track=core
  ```

  Presentation placeholders exist under `workshop/01…06` (frontmatter, target
  durations, planned outline; `status: placeholder`). Deliberately not in the
  pom yet: placeholder pages in a shareable PDF would be worse than absence.
- [ ] Add expected duration to every core workshop section.
- [ ] Add a clear "you should now know..." statement at the end of every section.
- [ ] Add a clear transition from each section to the next.
- [x] Define one recurring question used throughout the workshop: *(in WORKSHOP.md, "The one question")*

```text
What evidence do we have that this software is present,
what identifies it,
and what can this evidence not tell us?
```

- [x] Define one shared terminology set and use it consistently: *(defined in WORKSHOP.md; a consistency sweep of existing TRACE files is still pending)*
  - declaration
  - resolution
  - build-time software
  - transformation
  - artefact
  - inventory
  - identity
  - provenance
  - vulnerability
  - lifecycle / EOL

---

# P0 — Part 1: Software supply-chain fundamentals

**Target: 15 minutes presentation**

## Content

- [ ] Create the opening presentation section.
- [x] Include the live machine check: attendees run `./scripts/tools-check.sh`
      (fix what it reports) then `./scripts/build-all.sh` during this
      presentation. *(Written into WORKSHOP.md Part 1, 2026-08-24.)*
- [ ] Define a software supply chain as more than dependencies.
- [ ] Show the supply chain covering:
  - development
  - dependency selection
  - testing
  - integration
  - build
  - repositories
  - deployment
  - maintenance
  - security
  - support
  - EOL
- [ ] Explicitly show that every dependency brings decisions made by other people.
- [ ] Create a single application diagram showing:

```text
our source
Maven dependencies
transitive dependencies
npm packages
build plugins
build tools
JDK/runtime
container base
OS packages
```

- [ ] Ask the opening workshop question:

```text
Can you tell me exactly what software this application contains?
```

- [ ] Explain why we care:
  - vulnerability matching
  - remediation/support
  - compliance
  - audit
  - customer evidence
  - cyber insurance / business assurance
- [ ] Verify and source the "10% own code / 90% dependencies" claim before using it.
- [ ] Verify and source the "150 dependencies per application" claim before using it.
- [ ] Remove those numbers if they cannot be defended cleanly.

## Repository

- [x] Add presentation source/content under a predictable location such as:

```text
workshop/
  01-supply-chain-fundamentals.md
```

  *(Done 2026-08-24 as `workshop/01-supply-chain.md` … `06-wrap-up.md`.
  Placeholders with outlines and durations, now also in the book: one part per
  workshop part, appendices for optional/reference material. Content itself is
  still to be written.)*

- [x] Add links from `WORKSHOP.md`.

---

# P0 — Part 2: Can we identify what we ship?

**Target: 55 minutes hands-on**

This is the main practical section.

## ~~Build S00 — the boring baseline~~ **[DROPPED — decision 2026-08-24]**

**S00 will not be built.** Its two jobs are covered elsewhere:

- *Machine check / failure absorber* → moved into Part 1: attendees run
  `tools-check.sh` and `build-all.sh` live during the opening presentation,
  where a broken machine is cheapest to fix.
- *The control (all evidence sources agree)* → folded into S01's exercise:
  `jackson-databind` is the agreement baseline, sitting next to the two
  components that lose identity.

Part 2 keeps ~10 minutes of deliberate slack as a result.

Original checklist kept for the record:

- [ ] Create `scenarios/S00-baseline`.
- [ ] Keep it deliberately simple.
- [ ] Use a small Maven application with 2–3 obvious dependencies.
- [ ] Make the same dependencies visible in:
  - `pom.xml`
  - `mvn dependency:tree`
  - packaged JAR
  - CycloneDX SBOM
  - Syft artefact scan
  - container scan if useful
- [ ] Make everything agree.
- [ ] Add `OVERVIEW.md`.
- [ ] Add `TRACE.md`.
- [ ] Add `scripts/build.sh`.
- [ ] Add `scripts/clean.sh`.
- [ ] Add `scripts/proof-check.sh`.
- [ ] Keep the attendee exercise below 10 minutes.

## Curate S01

- [x] Stop treating all of S01 as mandatory. *(track tags + WORKSHOP.md route, 2026-08-24)*
- [x] Open with `jackson-databind` as the agreement baseline: the control
      formerly assigned to S00. Show it agreeing in POM, tree, JAR and SBOM
      before breaking the other two tracers. *(resolver + artefact scanner agreement, WORKSHOP.md Step 1)*
- [x] Extract one canonical exercise contrasting:
  - normal dependency
  - shaded/relocated dependency
  - bundled JavaScript
- [x] Decide exactly which commands attendees run. *(final set in WORKSHOP.md Part 2 Step 1; every command verified from clean state 2026-08-24)*
- [x] Move secondary experiments into an "Explore later" section. *(OVERVIEW.md links to TRACE steps 4–6, 17–18, 19–22, 23)*
- [x] Make the central conclusion explicit:

```text
software presence != software identifiability
``` *(Step 1 checkpoint)*

- [x] Target attendee time: 15 minutes. *(measured machine time: 7s build + ~8s commands; the budget is reading/typing)*

## Curate S04

- [x] Make S04 the principal "dependency graph is not the supply chain" lab. *(WORKSHOP.md Step 2)*
- [x] Start by showing the application's empty/uninteresting dependency tree.
- [x] Run the application.
- [x] Discover `/hidden/build-info`.
- [x] Trace the behaviour backwards through:
  - plugin declaration
  - plugin dependency
  - generated source
  - generated service metadata
  - final JAR *(compressed in the workshop step: the endpoint names its own chain and the JAR grep shows the generated class + ServiceLoader entry; full backward trace stays in TRACE.md as go-deeper)*
- [x] Reduce the participant instructions to the shortest sequence that proves the point. *(six commands, verified end-to-end)*
- [x] Target attendee time: 15 minutes. *(measured machine time: 5s build + ~2s commands)*

## Curate S05

- [x] Use S05 to establish that this behaviour is not Maven-specific. *(WORKSHOP.md Step 3)*
- [x] Decide whether S05 is:
  - a 10-minute attendee exercise, or
  - a 5-minute instructor demo. *(decided: attendee exercise; instructor demo is the time-pressure escape hatch)*
- [x] Show:

```text
source
 ↓
prepack
 ↓
generated dist/
 ↓
published package
 ↓
installed runtime code
```

- [x] Explicitly connect npm lifecycle execution to the Maven plugin example. *(step title and 'what this proves')*

## Reclassify S02 and S03

- [x] Make S02 optional/reference material.
- [x] Make S03 optional/reference material.
- [x] Add "If you use Jakarta EE..." and "If you use Python..." pointers from the workshop.
- [x] Do not remove them; they are valuable evidence that the same issue crosses ecosystems.

## Scanner experiment

- [x] Curate T01 down to one live comparison. *(WORKSHOP.md Step 4; per-scenario traces moved to the reference appendix)*
- [x] Use known S04 ground truth.
- [x] Ask whether the scanner can recover plugin/payload identity.
- [x] Establish:

```text
better analysis of available evidence
does not create missing evidence
```

- [x] Move the rest of T01 cross-scenario testing to optional/reference content.

## Section conclusion

- [x] End Part 2 with a shared evidence table: *(in WORKSHOP.md)*

| Evidence source | What it sees | What it may miss |
|---|---|---|
| Manifest/POM | declared model | generated/transformed software |
| Resolver | resolved graph | build plugin execution unless queried |
| SBOM | producer-specific view | anything outside producer evidence |
| Artefact scanner | recognisable packaged software | transformed/unidentified code |
| Image scanner | final filesystem/packages | source/build history |

- [ ] Carry this table into later sections.

---

# P0 — Part 3: What does a CVE finding actually mean?

**Target: 35 minutes presentation + guided web investigation**

## Create the vulnerability pipeline

- [ ] Add a diagram:

```text
software
   ↓
identity
   ↓
package/product mapping
   ↓
CVE record
   ↓
affected versions
   ↓
scanner matching
   ↓
finding
```

- [ ] Explain that every arrow is a possible failure point.
- [ ] Tie this explicitly back to Part 2.

## Build the Tomcat worked example

- [x] Create `investigations/CVE-tomcat-85`.
- [x] Select one canonical Tomcat CVE. *(CVE-2020-1938 Ghostcat: 8.5.0–8.5.50, KEV, 57 edits over six years)*
- [x] Capture:
  - initial disclosure
  - CNA record
  - affected versions
  - NVD analysis
  - CPE configuration
  - subsequent edits
  - exploit information if relevant
  - KEV addition if relevant *(all captured as raw API responses in evidence/, dated 2026-08-24)*
- [x] Build a chronological timeline. *(TRACE.md section 9)*
- [x] Preserve timestamps and source links. *(every date traced to a captured file or linked page)*
- [x] Show at least one material change to the record over time. *(Oracle/embedding CPEs added 2022-04-29, +26 months; also CWE remaps, 2026-06-17 edit)*
- [x] Explain what changed and why a scanner could produce different results at different dates. *(TRACE step 5: March vs May 2022 Oracle scan)*

## Teach CPE properly

- [x] Explain what a CPE is. *(TRACE step 3)*
- [x] Show an actual Tomcat CPE.
- [x] Explain version ranges.
- [x] Explain why forks/embeddings/repackaging complicate matching. *(TRACE steps 4 and 8)*
- [x] Show concrete examples such as:

```text
official Tomcat
commercially maintained Tomcat build
vendor product embedding Tomcat
internally patched Tomcat
renamed/repackaged Tomcat
fork
``` *(TRACE step 4's six-variant table, each mapped to in/not-in the record)*

- [x] Ask which of those the original CVE/CPE relationship actually describes.

## OpenSSL supporting example

- [ ] Pick one short OpenSSL example showing a different CVE/CPE/product-identification problem.
- [ ] Keep it under 5 minutes.
- [ ] Do not create another full investigation unless it adds a genuinely different lesson.

## CVE lifecycle

- [ ] Create a slide showing:

```text
discovery
 ↓
triage
 ↓
fix
 ↓
CVE publication
 ↓
database enrichment
 ↓
CPE/version refinement
 ↓
exploit evidence
 ↓
KEV
 ↓
continued updates
```

- [ ] Establish explicitly:

```text
A CVE is not a point-in-time fact.
It is a record of an event that continues to evolve.
```

## Section conclusion

- [ ] Have attendees interpret one scanner finding using:
  - identity
  - mapping
  - affected range
  - evidence date
- [ ] Give them the question:

```text
What exactly had to be true for this scanner to produce this finding?
```

---

# P0 — Break

- [x] Put the break explicitly in `WORKSHOP.md`.
- [x] Put the expected restart time in facilitator notes.
- [ ] Use the break as the boundary between:
  - discovering problems
  - deciding what to do about them

---

# P1 — Part 4: CVEs aren't enough

**Target: 25 minutes guided web investigation**

## Project health

- [x] Choose one well-known dependency to investigate throughout this section. **Decided 2026-08-24: lodash** (already Part 2's bundling tracer; ~71M weekly downloads against a 2021 last release).
- [x] ~~Open it in Cloudsmith Navigator. Identify the signals Navigator provides.~~ **Dropped 2026-08-24: Cloudsmith removed from the workshop entirely; Scorecard covers the health lens.**
- [x] Avoid presenting any aggregate score as objective truth. *(Done: the aggregate-7.2-summarises-a-10-and-a-0 beat in the drafted module.)*
- [x] Follow selected signals back to their underlying evidence.

## OpenSSF Scorecard

- [ ] Run/view Scorecard for the selected project.
- [ ] Explain 4–6 checks that developers can understand quickly.
- [ ] Focus on actionable signals rather than every Scorecard check.
- [ ] Explain what Scorecard does **not** tell us.

## Repository/project inspection

- [ ] Look at:
  - release recency
  - contributor activity
  - issue response
  - security policy
  - automated dependency updates
  - release practices
  - supported versions
- [ ] Make clear these are signals, not guarantees.

## EOL

- [ ] Run the HeroDevs EOL tooling against selected workshop dependencies.
- [ ] Include at least one dependency that is:
  - supported
  - approaching EOL
  - already EOL
- [ ] Explain the difference between:
  - vulnerable
  - not known vulnerable
  - unsupported
- [ ] Establish:

```text
CVE data tells us what is known to be broken now.
Lifecycle data helps tell us who is expected to fix what breaks next.
```

## OpenEOX

- [ ] Add a short explanation of OpenEOX.
- [ ] Explain why lifecycle status needs machine-readable standardisation.
- [ ] Keep detailed standards material in an appendix/reference section.

## Section conclusion

- [ ] Add the three-question model:

```text
What is present?
What is known to be vulnerable?
Who is expected to maintain/fix it?
```

---

# P1 — Part 5: What if someone deliberately exploits the gaps?

**Target: 35 minutes presentation + hands-on**

## Reframe previous labs

- [ ] Revisit S03/S04/S05 briefly.
- [ ] Point out that everything demonstrated so far can occur legitimately.
- [ ] Show how the same mechanisms can be used maliciously:
  - plugin execution
  - lifecycle scripts
  - build backends
  - generated files
  - dependency confusion
  - typosquatting
  - compromised package releases
- [ ] Avoid adding a separate demo for every attack class.

## Control 1 — Controlled ingress

- [ ] Add explanation of repository managers/internal registries.
- [ ] Explain the desired production model:

```text
public ecosystem
      ↓
controlled ingress
      ↓
internal repository
      ↓
build
```

- [ ] Cover:
  - namespace control
  - approved repositories
  - immutability
  - quarantine/scanning
  - retention
  - policy

## New lab: local cache corruption / artefact integrity

- [ ] Create a small integrity lab.
- [ ] Use an existing Maven artefact to minimise setup.
- [ ] Download/store a known artefact in the controlled repository or fixture.
- [ ] Record its expected digest.
- [ ] Corrupt or replace the local cached copy.
- [ ] Show what the normal build does.
- [ ] Show a verification mechanism that detects the mismatch.
- [ ] Make clear what Maven checks automatically and what it does not.
- [ ] Add `proof-check.sh`.
- [ ] Target participant time: 10 minutes.

## Control 2 — Provenance / reverse trace

**Built 2026-08-25 as `scenarios/S07-provenance-s01`** (reuses S01's image and
JAR, so no new app). Baseline reverse audit + four provenance layers, all run
for real (docker + local registry + syft + cosign), evidence captured,
proof-check 7/7.

- [x] Create a small reverse-provenance exercise. *(S07, built on S01 per Steve's steer.)*
- [x] Start with an already-built container or JAR. *(S01's Spring Boot image.)*
- [x] Ask which repository / commit / build / dependencies / who produced this.
- [x] Attempt to recover these from the artefact. *(Baseline: only the base image's inherited `22.04` label; nothing of ours.)*
- [x] Demonstrate where ordinary metadata stops. *(Baseline audit section.)*
- [x] Add provenance incrementally:
  - [x] Git commit metadata *(git-commit-id plugin → git.properties in the JAR)*
  - [x] OCI labels *(org.opencontainers.image.revision/source/created)*
  - [x] SBOM *(syft CycloneDX, keyed to the image digest)*
  - [x] build identity / attestation *(cosign sign + attest by digest, verified with the public key)*
- [x] Introduce SLSA/provenance conceptually. *(Keyless Fulcio/Rekor named as the production form; not implemented.)*
- [x] Avoid turning this into a complete Sigstore/SLSA workshop. *(Local key pair, one registry, four commands.)*
- [x] Target participant time: 10–12 minutes.
- [ ] **Rehearse the S07 run before the room:** needs Docker + a throwaway `registry:2`, and installs syft/cosign (pre-bake in the workshop container).

## Section conclusion

- [ ] Establish the three defensive controls:

```text
Control what comes in.
Verify the bytes you receive.
Preserve evidence of how they were produced.
```

---

# P0 — Part 6: Wrap-up

**Target: 10 minutes**

- [ ] Return to the opening question:

```text
Can you tell me exactly what software this application contains?
```

- [ ] Show why no single tool can answer every interpretation of that question.
- [ ] Create the final evidence model:

```text
What did we request?
        ↓
What did the resolver choose?
        ↓
What executed during the build?
        ↓
What bytes did we produce?
        ↓
What did we deploy?
        ↓
What is running?
        ↓
Can we trace it back?
```

- [ ] Overlay:
  - vulnerability data
  - exploit data
  - project health
  - lifecycle/EOL
- [ ] End with the operating model:

```text
Know what you requested.
Observe what the build actually did.
Inventory what you shipped.
Preserve how it got there.
Continuously reassess vulnerability and support state.
```

- [ ] Point attendees at optional S02/S03/tool investigations for self-study.

---

# P0 — Workshop usability

These are necessary for a conference workshop rather than a repository of experiments.

## One-command readiness

- [ ] Update `scripts/tools-check.sh` for every tool required by the canonical route.
- [ ] Separate tools into:
  - REQUIRED
  - OPTIONAL
  - INSTRUCTOR ONLY
- [ ] Ensure attendees do not need credentials for any mandatory exercise if avoidable.
- [ ] If credentials are unavoidable, create a fallback path.
- [ ] Update `scripts/build-all.sh` to build only the canonical path by default.
- [ ] Add:

```bash
./scripts/build-all.sh --everything
```

for all reference labs.

## Workshop preflight

- [ ] Add `scripts/workshop-check.sh`.
- [ ] Verify:
  - Java
  - Maven
  - Node/npm
  - Docker
  - jq
  - curl
  - Syft
  - required ports
  - required downloaded images
  - required fixtures
- [ ] Make it return non-zero for anything that would block an attendee.
- [ ] Print simple remediation instructions.

## Containerised workshop (added 2026-08-25)

- [x] Build a workshop container so attendees install only Docker.
  **Split into two images (2026-08-25):**
  - `shipping-workshop-base` (`container/Dockerfile.base`) — the tools:
    Ubuntu 24.04, Temurin 21, Maven 3.9.9, Node 22, Python 3.12,
    syft/grype/trivy/snyk/pip-audit/docker-scout CLI, **plus the Grype and
    Trivy databases**. Big, rebuilt rarely — and rebuilt deliberately near
    workshop day, because DB freshness lives here
    (`./container/build.sh --base`).
  - `shipping-workshop` (`container/Dockerfile`) — FROM the base, the
    workshop code plus the scenario prewarm (Maven/npm/venv caches).
    Rebuilt on every content change; attendees who have the base pull only
    these layers.
  Docker itself is NOT inside — the container drives the host daemon via a
  mounted socket, so S01/S02 images land on the host and stay
  browser-reachable.
- [ ] Publish BOTH images to a registry (name/registry TBD) so attendees
  pull instead of build; the code image's `BASE_IMAGE` build-arg already
  supports a registry-qualified base. Decide multi-arch (arm64 + amd64)
  via buildx.
- [ ] Note in WORKSHOP.md per-step whether the step is container-friendly
  (all of Parts 2–3 are; S03/S04/S05 browser hints don't apply inside).

## Network resilience

- [ ] Identify every live internet dependency during the workshop.
- [ ] Remove unnecessary live downloads.
- [ ] Cache Maven/npm/container dependencies where practical.
- [ ] Capture screenshots/static evidence for web investigations as fallback.
- [ ] Prepare an instructor copy of important NVD/CVE/CPE pages in case internet access fails.
- [ ] Ensure labs themselves can largely run offline after prewarm.

## Resetability

- [ ] Every core lab must have:
  - `build.sh`
  - `clean.sh`
  - `proof-check.sh`
- [ ] Runtime labs also need:
  - `run.sh`
  - `stop.sh`
- [ ] Verify labs can be restarted after attendees make mistakes.

---

# P0 — Facilitator material

- [x] Create `FACILITATOR.md`.
- [x] Include exact timings. *(measured, not estimated: wall-clock offsets plus per-step machine floors)*
- [x] Include "skip this if running late" points. *(per part, plus on-time checkpoints at 0:45/1:10/1:40)*
- [x] Include expected output for each live command. *(one-line expectations; TRACEs hold the full form)*
- [x] Include likely attendee failures and fixes. *(failure playbook: every entry actually hit during verification)*
- [x] Include transitions between sections.
- [x] Include questions to ask the room.
- [x] Include the intended conclusion from every exercise.
- [x] Mark which operations should be instructor demos rather than everyone typing. *(T01 demo instructor-only; S05 demo-if-late; Tomcat live curls instructor-optional, room uses evidence/)*

## Time-pressure escape hatches

- [x] Define the first thing to cut from each section. *(ordered five-item cut list with minutes saved)*
- [x] Suggested cuts:
  - S05 participant exercise → instructor demo
  - OpenSSL example
  - detailed Scorecard exploration
  - extended attack taxonomy
  - provenance implementation detail *(ordered with minutes saved in FACILITATOR.md)*
- [x] Never cut:
  - the Part 1 live machine check (absorbed S00's job)
  - S01 transformation
  - S04 hidden build content
  - Tomcat CVE/CPE walkthrough
  - EOL distinction
  - final evidence/provenance model *(restated at each relevant point in FACILITATOR.md)*

---

# P1 — Participant material

- [ ] Make `WORKSHOP.md` usable without the presenter.
- [ ] Use numbered workshop steps rather than scenario numbers as the primary navigation.
- [ ] At each hands-on section include:

```text
Question
What we're about to test
Commands to run
Expected observation
What this proves
What this does NOT prove
```

- [ ] Keep detailed technical explanation in scenario `TRACE.md` files.
- [ ] Link to those as "Go deeper".
- [ ] Add checkpoints such as:

```text
Before continuing you should have established:
[ ] ...
[ ] ...
```

- [ ] Include expected elapsed time next to each exercise.

---

# P1 — Repository restructure

Suggested shape:

```text
README.md
WORKSHOP.md
FACILITATOR.md

workshop/
  01-supply-chain.md
  02-identification.md
  03-vulnerabilities.md
  04-project-health-eol.md
  05-integrity-provenance.md
  06-wrap-up.md

scenarios/
  S00-baseline/
  S01-spring-node/
  S02-payara-mvnpm/
  S03-python-pep517/
  S04-maven-plugin-hidden-content/
  S05-node-prepack/
  S06-cache-integrity/       (still to build)
  S07-provenance-s01/        (built — reverse provenance on S01)

investigations/
  CVE-tomcat-85/
  ...

reference/
  tools/
  cve-process/
  cpe/
  open-eox/
  attacks/
```

- [ ] Do not reorganise existing scenario directories until the canonical route works.
- [ ] Prefer links over moving files unnecessarily.
- [ ] Only perform the larger restructure once the workshop has been run end-to-end once.

---

# P1 — Tool/reference catalogue

The existing idea of covering many tools is useful, but it should be a reference rather than live workshop content.

- [x] Create `reference/tools.md`. *(in the book as 'Appendix — The Tools')*
- [x] Categorise tools by the evidence boundary they inspect:
  - source/dependency graph
  - repository
  - package
  - filesystem
  - container
  - vulnerability database
  - project health
  - lifecycle/EOL
  - provenance *(grouped as resolvers / inventory producers / matchers / data sources / utilities / health+lifecycle)*
- [x] Include existing tools:
  - Snyk
  - Trivy
  - Grype
  - Docker Scout
  - OWASP Dependency-Check
  - npm audit
  - pip-audit
  - Syft
  - Dependency-Track
  - OSV
  - OpenSSF Scorecard
  - EOL tooling
- [x] Explicitly state that the catalogue is not a product ranking. *(first paragraph, bolded)*

---

# P1 — Proof and regression

- [ ] Add a top-level workshop proof script:

```bash
./scripts/proof-check-all.sh
```

- [ ] Run only canonical exercises by default.
- [ ] Add `--everything` for the entire repo.
- [ ] Distinguish:
  - structural assertions that must never change
  - vulnerability counts/data that can legitimately drift
- [ ] Avoid hard failures on expected CVE database drift unless the lesson itself changed.
- [ ] Add CI that executes all deterministic core lab proof checks.
- [ ] Avoid CI steps requiring paid accounts or interactive auth.

---

# P2 — Presentation deck

Do this **after the workshop route is stable**.

- [ ] Build slides for Part 1.
- [ ] Build transition slides for Part 2.
- [ ] Build CVE/CPE lifecycle visuals for Part 3.
- [ ] Build health/EOL slides for Part 4.
- [ ] Build attack/control model for Part 5.
- [ ] Build final evidence model for Part 6.
- [ ] Keep command-heavy material in `WORKSHOP.md`, not duplicated on slides.
- [ ] Use slides primarily for:
  - concepts
  - diagrams
  - conclusions
  - transitions

---

# Definition of done

The workshop is ready when a fresh attendee can:

- [ ] Clone the repository.
- [ ] Run one preflight command.
- [ ] Follow `WORKSHOP.md` from top to bottom without choosing between scenarios.
- [ ] Finish the canonical route in under 2h40 of active workshop time.
- [ ] Recover cleanly if an individual exercise fails.
- [ ] Explain why a dependency tree, SBOM and artefact scan can legitimately disagree.
- [ ] Explain why a scanner can miss software that is genuinely present.
- [ ] Explain how software identity connects to CVE matching.
- [ ] Explain why CVE/CPE information changes over time.
- [ ] Distinguish known vulnerability from lifecycle/EOL risk.
- [ ] Explain why build mechanisms can become attack mechanisms.
- [ ] Explain the roles of controlled ingress, integrity checking and provenance.
- [ ] Answer the final question:

```text
What evidence would I need to prove what software I shipped,
where it came from,
and whether I should still trust it?
```

# Working abstract (revised draft, 2026-08-24)

Kept in sync with the route. Changes from the published version: signature
labs lead the middle; "SBOM" appears; the Tomcat teaser uses the captured
numbers; ReversingLabs → Cloudsmith → dropped entirely (2026-08-24);
bring-a-laptop + take-home added;
tagline typo fixed. Python stays in the ecosystems line: S03 is now core.

> **You Don't Know What You're Shipping**
>
> Every project has dependencies it knows about. Most have dependencies it
> doesn't.
>
> This is a hands-on tour of the modern dependency problem, using free and
> free-tier tools and public data. You'll work with applications built to
> lie to you: an app whose dependency tree is empty but which serves an
> endpoint nobody wrote; a JAR that drops out of your scanner's results
> when we remove nothing but metadata; packages that write their own code
> while being packaged or installed. Along the way you'll see why a
> dependency tree, an SBOM and a scanner report can all disagree, and all
> be right.
>
> Java, Node, Python, Docker: the techniques apply regardless of what
> you're building.
>
> We'll take one famous Tomcat CVE apart using the public record: six years
> of edits, three severity scores that disagree, a two-month window where
> the same scan flips from clean to critical, and the end-of-life versions
> the record silently ignores. You'll learn to read a CVE as an evolving
> event rather than a fact, and to use in-support vulnerability data as a
> searchlight on the versions your scanners aren't covering.
>
> We'll use Snyk's free tier and the HeroDevs EOL database to map what you
> have and flag what's past safe support, and OSS Index and OpenSSF
> Scorecard to judge whether the project behind a library will still be
> fixing it next year. And we'll go beyond metadata to see what analysing
> actual binary behaviour turns up.
>
> Then the sharp end: dependencies hidden by someone who means you harm, a
> dissection of AI-generated malware, and how AI coding assistants are
> quietly growing your dependency trees, picking poor libraries, and
> hallucinating packages that don't exist, while attackers have learned to
> publish the hallucinations for real.
>
> Bring a laptop. One command the night before sets everything up, and you
> leave with the complete lab manual: every command, every capture, ready
> to run against your own projects the moment you get home.

---

# Abstract alignment (added 2026-08-24)

The published abstract ("You Don't Know What You're Shipping") was reviewed
against the book/route. Decisions and remaining work:

**Decided:**

- [x] **All AI material becomes its own segment: Part 6 — AI and the Supply
  Chain (20 min).** Wrap-up renumbered to Part 7. Part 5 drops to 25 min
  (the malware dissection moved to Part 6). Route total now ~200–205 min
  including the break.
- [x] The binary-behaviour-analysis segment is **Cloudsmith** (abstract's
  ReversingLabs mention was wrong): tools appendix rewritten, planned into
  Part 5. **Superseded 2026-08-24: Cloudsmith dropped from the workshop
  entirely; the segment stays, tool to be chosen.**
- [x] "In-support data as a signal for uncovered versions" is now taught
  explicitly: the **searchlight technique** section in the Tomcat
  investigation (step 8).
- [x] Book bridges to the public title: the About card opens with
  "the manual for *You Don't Know What You're Shipping*" plus the
  abstract's tagline.
- [x] OSS Index added to the Part 4 plan and the tools appendix.
- [x] "Snyk free tier is sufficient" stated in Accounts and Keys.
- [x] "When you get home" checklist added to the wrap-up (Part 7): the
  abstract's closing promise made literal.

**Open (needs content decisions):**

- [ ] **Part 6 asset: the AI-generated malware sample** — what gets
  dissected, and the safe-handling story (instructor machine only,
  isolated, never distributed).
- [ ] **Part 6 evidence: hallucination/slopsquatting data** — verify and
  source every claim (tree growth, poor picks, hallucination rates,
  registered-hallucination incidents) before presenting.
- [x] **Part 5 binary-behaviour demo** — tool chosen 2026-08-24: **GuardDog** (investigation `T08-guarddog`, built with evidence + passing proof-check). Static code heuristics, not dynamic execution; no Maven ecosystem (S04 JAR out of reach). Remaining: scope live-vs-screenshot for the room.
- [x] Decide whether the book itself is retitled to the public workshop
  title. **Decided 2026-08-24: yes.** Book title is now "You Don't Know
  What You're Shipping", subtitle "The Software Supply Chain Trace Lab"
  (the old title survives as the subtitle, so the lab identity is kept).
  README retitled to match; running headers pick it up automatically.
- [x] Reconsider S03 (Python) being optional. **Decided 2026-08-24: S03 is
  core.** Part 2 Step 4 ("And not a JavaScript quirk either", ~8 min,
  demo-if-late). Part 2 is now 60 min, route total ~205–210 incl. break.
  Commands verified from clean: build 3s, two-file sdist, generated
  site-packages, /trace endpoint on 8081. This reverses the earlier
  "Make S03 optional/reference material" tick above.
- [x] Cloudsmith free-tier concern resolved: **Navigator is free, no
  sign-in** (confirmed by Steve, 2026-08-24). **Superseded later the same
  day: Cloudsmith dropped from the workshop entirely.**

---

# Immediate next five tasks

If we want to work through this efficiently, do these first:

- [x] **Create `WORKSHOP.md` with the timed six-part route.**
- [x] ~~**Build S00 — the boring baseline dependency trace.**~~ *(Dropped 2026-08-24: machine check moved to Part 1 presentation; control folded into S01.)*
- [x] **Cut S01 and S04 down to their canonical live exercises.** *(done 2026-08-24; demo timings: T01 baseline 9s, snyk probes 37s, compare instant. Also fixed: all T01/T02 scripts lacked the execute bit and failed with 'permission denied')*
- [x] **Build the Tomcat CVE/CPE investigation and timeline.** *(done 2026-08-24; proof-check 14/14 against captured evidence)*
- [ ] **Run the first complete timed rehearsal before adding S06/S07 or slides.**

That first rehearsal will tell us much more about what is genuinely missing than adding another five scenarios now.
