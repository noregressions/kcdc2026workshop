# The Workshop

This is the canonical attendee route. Follow it top to bottom. You do not
need to choose between scenarios, and you are not expected to complete
everything else in this repository. Material marked **Go deeper** is optional.

> Sections marked **⚠ PLACEHOLDER** depend on labs or presentations that are
> not built yet. The route is complete; some stops are still under
> construction.

## Before you arrive

From the repository root, on a good network:

```bash
./scripts/tools-check.sh    # what is installed, what is missing, how to get it
./scripts/build-all.sh      # every download, image pull and compile
```

Both must succeed before the workshop. `build-all.sh` is the difference
between starting on time and watching Maven download.

## The one question

Everything in this workshop is the same question asked at different places:

```text
What evidence do we have that this software is present,
what identifies it,
and what can this evidence not tell us?
```

When you are unsure why a step exists, re-ask that question about whatever is
in front of you.

## Terminology

These words are used precisely throughout:

| Term | Meaning here |
|---|---|
| declaration | what a manifest/POM *asks for* |
| resolution | the concrete versions a resolver *chose* |
| build-time software | code that executes during the build but is not an application dependency |
| transformation | anything the build does that changes structure or identity (shading, bundling, generation) |
| artefact | the bytes actually produced (JAR, WAR, tarball, wheel) |
| inventory | a list of software claimed to be present (SBOM, scan result) |
| identity | evidence that lets a component be *named* (coordinates, metadata, digests) |
| provenance | evidence of *how* an artefact came to exist |
| vulnerability | a claim that identified software matches a known defect record |
| lifecycle / EOL | who is expected to maintain and fix the software, and until when |

## The route

```text
Part 1   Supply-chain fundamentals               15 min   presentation
Part 2   Can we identify what we ship?           60 min   hands-on
Part 3   What does a CVE finding actually mean?  35 min   presentation + web

BREAK                                            15–20 min

Part 4   CVEs aren't enough                      25 min   guided web
Part 5   Exploiting the gaps                     25 min   presentation + hands-on
Part 6   AI and the supply chain                 20 min   presentation + demo
Part 7   Wrap-up                                 10 min
```

Roughly 205–210 minutes including the break.

---

# Part 1 — Supply-chain fundamentals (15 min)

**⚠ PLACEHOLDER** — presentation. Outline: [`workshop/01-supply-chain.md`](./workshop/01-supply-chain.md)

## While you listen — machine check (do this now)

Open a terminal at the repository root and run:

```bash
./scripts/tools-check.sh
```

Fix anything it reports missing: it prints install links. Then:

```bash
./scripts/build-all.sh
```

If you did this before arriving, both are fast re-verifications. If either
fails and you can't see why, flag an instructor **during this presentation**:
this is the cheapest moment in the whole workshop to fix a machine.

## The presentation

A software supply chain is more than dependencies, and every dependency brings
decisions made by other people. This part ends with the question the rest of
the workshop tries to answer:

```text
Can you tell me exactly what software this application contains?
```

**You should now know:** what counts as part of your supply chain, and why
"list the dependencies" is not the same question as "list the software".

**Transition:** if the question sounds easy, Part 2 is where it stops being
easy.

---

# Part 2 — Can we identify what we ship? (60 min, hands-on)

Four exercises and one demo: Java, npm and Python, so nobody's ecosystem is
someone else's problem. Each uses the same five-beat pattern; keep the one
question in mind throughout. The spare minutes are deliberate slack.

## Step 1 — Transformation destroys identity (~15 min)

Lab: [`scenarios/S01-spring-node`](./scenarios/S01-spring-node/OVERVIEW.md) · Go deeper: [`TRACE.md`](./scenarios/S01-spring-node/TRACE.md)

**Question:** does the software survive the build with its identity intact?

**What we're about to test:** three components take three different paths:
`jackson-databind` stays a normal dependency, `commons-codec` is shaded and
relocated into another JAR, `lodash` is bundled into frontend JavaScript.

`jackson-databind` is the **control**: it agrees in the POM, the resolved
tree, the JAR and every SBOM. That proves the tools work, so when the other
two vanish, the build is the suspect, not the scanner.

**Run — first the control:**

```bash
cd scenarios/S01-spring-node
./scripts/build.sh                                # skip if build-all.sh ran
mvn -pl service dependency:tree -Dincludes=com.fasterxml.jackson.core:jackson-databind
syft service/target/service-1.0.0.jar | grep -i jackson
```

**Expected observation:** the resolver says `jackson-databind 2.19.4`; the
artefact scanner, looking only at the finished JAR, says `2.19.4` too. Two
unrelated evidence sources, one answer. The tools work.

**Run — now break identity by shading:**

```bash
syft normalizer/target/normalizer-1.0.0.jar
./scripts/strip-codec-metadata.sh
```

**Expected observation:** the first scan finds `commons-codec 1.17.1` inside
the shaded JAR. The strip script copies the JAR and removes *only* the
identifying Maven metadata, not one byte of code, and the same scanner no
longer reports commons-codec at all.

**Run — now break identity by bundling:**

```bash
npm --prefix frontend ls lodash
grep -oE "__lodash_hash_undefined__|4\.17\.21" frontend/dist/assets/*.js | sort | uniq -c
syft frontend/dist
```

**Expected observation:** the lockfile pinned `lodash@4.17.21`; the minified
bundle still contains lodash's version string and its internal
`__lodash_hash_undefined__` sentinel: the code demonstrably went in. Syft,
given only the built bundle, reports **no packages discovered**.

**What this proves:** the scanners were identifying *metadata*, not code. Two
different builds destroyed that metadata two different ways: shading stripped
it, bundling never carried it. The code itself shipped both times.

**What this does NOT prove:** that the scanners are bad. Each analysed the
evidence available at its boundary; the build destroyed the evidence. A human
with `grep` found lodash's fingerprints, but a fingerprint is not a package
identity you can match a CVE against.

**Checkpoint before continuing:**

- [ ] You saw one component (jackson-databind) agree in every evidence source.
- [ ] You watched another vanish from a scan while its code stayed put.
- [ ] You can state the conclusion: `software presence != software identifiability`

## Step 2 — The dependency graph is not the supply chain (~15 min)

Lab: [`scenarios/S04-maven-plugin-hidden-content`](./scenarios/S04-maven-plugin-hidden-content/OVERVIEW.md) · Go deeper: [`TRACE.md`](./scenarios/S04-maven-plugin-hidden-content/TRACE.md)

**Question:** can an application gain runtime behaviour from software that is
not in its dependency tree?

**What we're about to test:** an application whose Maven dependency tree is
completely empty, and which serves an endpoint nobody wrote.

**Run:**

```bash
cd scenarios/S04-maven-plugin-hidden-content
./scripts/build.sh                                # skip if build-all.sh ran
mvn -Dmaven.repo.local="$PWD/.maven-repo" dependency:tree
./scripts/run.sh
curl -sS http://localhost:8082/hidden/build-info | jq
unzip -l target/maven-plugin-hidden-content-1.0.0.jar | grep -E 'Generated|services'
./scripts/stop.sh
```

**Expected observation:** the tree shows the root artefact and nothing else.
The running application answers on `/hidden/build-info` and names the software
responsible: `trace-route-payload`, introduced by `trace-injector-maven-plugin`,
a *transitive dependency of a build plugin*, executed during
`generate-sources`, compiled into the JAR as ordinary application code.

**What this proves:** Maven has multiple dependency domains. An empty
application dependency tree does not mean no third-party software shaped the
application.

**What this does NOT prove:** that anything malicious happened. Everything
here is legitimate, documented Maven behaviour, which is exactly why it
matters.

**Checkpoint before continuing:**

- [ ] `dependency:tree` was empty and the endpoint existed anyway.
- [ ] You can name where the behaviour came from without looking it up.

## Step 3 — It's not a Maven quirk (~8 min)

Lab: [`scenarios/S05-node-prepack`](./scenarios/S05-node-prepack/OVERVIEW.md) · Go deeper: [`TRACE.md`](./scenarios/S05-node-prepack/TRACE.md)

*Instructor may run this as a demo if time is short.*

**Question:** does the same pattern exist in a completely different ecosystem?

**What we're about to test:** an npm package whose `prepack` lifecycle script
generates its runtime code while the tarball is being created.

**Run:**

```bash
cd scenarios/S05-node-prepack
./scripts/build.sh
tar -tzf npm-repo/trace-route-package-1.0.0.tgz
./scripts/run.sh
curl -sS http://localhost:8083/hidden/prepack-info | jq
./scripts/stop.sh
```

**Expected observation:** the build log shows `npm notice run … prepack`
executing `generate-dist.js`; the tarball contains `dist/` files that do not
exist in the package source; the running application serves the generated
route and says so.

**What this proves:** package-owned code can execute before the distributable
artefact exists, in npm exactly as in Maven. This is an ecosystem-independent
property of build systems.

**What this does NOT prove:** that install-time scripts ran: this lab
deliberately disables those (`--ignore-scripts`) so `prepack` is the only
execution boundary.

**Checkpoint before continuing:**

- [ ] You can point at the moment package code executed, in the build log.

## Step 4 — And not a JavaScript quirk either (~8 min)

Lab: [`scenarios/S03-python-pep517`](./scenarios/S03-python-pep517/OVERVIEW.md) · Go deeper: [`TRACE.md`](./scenarios/S03-python-pep517/TRACE.md)

*Instructor may run this as a demo if time is short.*

**Question:** does Python have the same execution boundary?

**What we're about to test:** a transitive dependency that arrives as a
source distribution and, under PEP 517, runs its own build backend during
`pip install`, generating the package that actually gets imported.

**Run:**

```bash
cd scenarios/S03-python-pep517
./scripts/build.sh
tar -tzf python-repo/tracehook_demo-1.0.0.tar.gz
ls .venv/lib/python*/site-packages/tracehook_demo/
./scripts/run.sh
curl -sS http://localhost:8081/trace | jq
./scripts/stop.sh
```

**Expected observation:** the build log shows pip running the backend
(`Getting requirements to build wheel`, `Building wheel for tracehook-demo`).
The sdist contains exactly **two files**, `pyproject.toml` and the backend,
and neither is the package you end up importing. `site-packages` contains the
generated `__init__.py` and its provenance marker, and the running app's
`/trace` endpoint says so: `"event": "pep517-build-backend-executed"`.

**What this proves:** Maven plugins, npm lifecycle hooks, PEP 517 backends.
Three ecosystems, one property: *the thing being installed can run code that
creates the thing you actually ship*.

**What this does NOT prove:** that any of it is malicious. Every mechanism
here is standards-documented behaviour, which is Part 5's opening line.

**Checkpoint before continuing:**

- [ ] You saw the two-file sdist, and the package it generated at install time.

## Step 5 — Can a better scanner recover what's missing? (instructor demo, ~5 min)

Demo: [`investigations/T01-snyk-beyond-sbom`](./investigations/T01-snyk-beyond-sbom/OVERVIEW.md), shown live against the S04 ground truth. You don't run this one.

A commercial SCA tool analyses S04 with everything it has. It genuinely knows
more than a plain SBOM, and still cannot name the plugin or its payload,
because no evidence of them survives in the artefact.

```text
better analysis of available evidence
does not create missing evidence
```

## Part 2 conclusion — the evidence table

| Evidence source | What it sees | What it may miss |
|---|---|---|
| Manifest/POM | declared model | generated/transformed software |
| Resolver | resolved graph | build plugin execution unless queried |
| SBOM | producer-specific view | anything outside producer evidence |
| Artefact scanner | recognisable packaged software | transformed/unidentified code |
| Image scanner | final filesystem/packages | source/build history |

This table comes back in every remaining part.

**You should now know:** every inventory is an observation from one evidence
source at one boundary; no single boundary sees everything; and a build can
legitimately destroy identity while preserving behaviour.

**Transition:** so far we asked *what is present*. Part 3 asks what happens
when an inventory entry meets a vulnerability database.

---

# Part 3 — What does a CVE finding actually mean? (35 min)

**⚠ PLACEHOLDER**: the presentation is not written yet
([outline](./workshop/03-vulnerabilities.md)). **The worked example is built**
and is the guided part of this section.

The pipeline every scanner finding travels, and every arrow a failure point:

```text
software → identity → package/product mapping → CVE record
        → affected versions → scanner matching → finding
```

## The worked example — Ghostcat, read as evidence

Investigation: [`investigations/CVE-tomcat-85`](./investigations/CVE-tomcat-85/OVERVIEW.md) · Walkthrough: [`TRACE.md`](./investigations/CVE-tomcat-85/TRACE.md) · Frame: [the companion foojay.io article](https://foojay.io/today/the-real-mechanics-of-vulnerabilities-in-an-upstream-downstream-topsy-turvy-eol-world/)

**Question:** would a scanner have given you the same answer about this CVE
in 2020, 2022 and 2026?

One real record (CVE-2020-1938, Tomcat 8.5.0–8.5.50) read from four public
API responses: the CNA claim, NVD's enrichment, six years of edit history,
and the KEV entry. Needs only `curl` and `jq`; the repository carries
captured responses in `evidence/` so it works without conference wifi.

What it surfaces, each verified against the captured records:

- three severity claims for one defect (Apache "Important", CVSS v2 7.5,
  v3.1 9.8 CRITICAL)
- what a CPE is, and the three conditions a finding silently depends on
- embedding products (20 Oracle CPEs among 38) added **26 months** after
  publication. Scan an Oracle product in March 2022: nothing; in May 2022:
  CRITICAL
- KEV addition two years after publication, with public exploits circulating
  within days: catalogue dates are not exploitation dates
- EOL Tomcat 6.x absent from the record entirely, while 2025's
  CVE-2025-24813 names EOL 8.5 in prose and sweeps it into an unbounded CPE
  range: two conventions, opposite scanner outcomes

The section's conclusion:

```text
A CVE is not a point-in-time fact.
It is a record of an event that continues to evolve.
```

**Checkpoint before the break:**

- [ ] You can name the three conditions a CPE match depends on.
- [ ] You can explain why the same scan gave different answers in March and
      May 2022 without the software changing.
- [ ] You can say what scanner silence about EOL software actually means.

**You should now know:** exactly what had to be true for a scanner to produce
a finding, and how many of those things Part 2 showed can be false without
warning.

---

# ☕ BREAK (15–20 min)

The boundary between **discovering problems** and **deciding what to do about
them**. We will announce the restart time before the break starts.

---

# Part 4 — CVEs aren't enough (25 min, guided web)

Guided investigation: [`workshop/04-project-health-eol.md`](./workshop/04-project-health-eol.md) carries the full route with expected observations.

**Question:** when the next vulnerability lands in a dependency, who is
expected to fix it? No CVE database answers that.

One dependency, `lodash` (Part 2's bundling tracer: ~71 million downloads a
week, last stable release 2021), read through two lenses, then an EOL sweep
of this workshop's own dependencies:

1. **OpenSSF Scorecard** —
   <https://scorecard.dev/viewer/?uri=github.com/lodash/lodash> (captured
   report in `workshop/evidence/`). When captured: aggregate **7.2**, Maintained
   **10** against a release from 2021 (activity and shipping are different
   acts), Vulnerabilities **0** (park it for step 2), Token-Permissions 0,
   Pinned-Dependencies 4, and three checks answering **?** — an honest
   "can't see" most dashboards would have papered over with a number.
   Scorecard measures repository *practice*: it says nothing about whether
   the code is good, or whether your shipped version is vulnerable. The
   aggregate is somebody's chosen checks under somebody's chosen weights.
   Use the pieces; be suspicious of the summary.
2. **Sonatype OSS Index** — look up `pkg:npm/lodash@4.17.21` (captured
   response in `workshop/evidence/` if the service or the wifi is having a
   bad day).
   Expect a clean result against Scorecard's Vulnerabilities 0. Both are
   honest: different databases, different boundaries (project vs published
   coordinates). A clean lookup means *not known vulnerable*, in that
   database, at those coordinates, today.
3. **The EOL sweep** — `npx @herodevs/cli scan eol --dir .` (or read the
   captured `workshop/evidence/herodevs.report.json`). Against this
   repository:
   jackson-databind 2.19.4 supported; lodash with no lifecycle statement at
   all; **Spring Boot 3.5, which S01 runs on, past OSS EOL since 30 June
   2026**; Tomcat 8.5, Part 3's subject, EOL since March 2024.

```text
vulnerable            a known defect exists, recorded, matchable
not known vulnerable  the ONLY thing a clean scan means
unsupported           whatever is found next, nobody upstream is expected to fix it
```

After EOL the reporting pipeline winds down, so scanner green stops meaning
"nothing is wrong" and starts meaning "nobody is watching". Spring Boot 2.7
is the precedent: CVE-2024-38807 arrived after EOL, and no open-source patch
ever did.

Plus **OpenEoX** in brief: the OASIS effort to make lifecycle status
machine-readable (Core Schema 1.0 in public comment, July 2026), so the
question in step 4 stops needing a hand-curated dataset.

```text
CVE data tells us what is known to be broken now.
Lifecycle data helps tell us who is expected to fix what breaks next.
```

**Checkpoint before continuing:**

- [ ] You can state the difference between "not known vulnerable" and "safe".
- [ ] You can say what scanner silence means for software past EOL.
- [ ] You know which of this workshop's own dependencies are past EOL.

**You should now know:** the three-question model: what is present, what is
known vulnerable, who is expected to maintain it.

**Transition:** everything so far has been legitimate behaviour honestly
observed. Part 5 is what happens when someone uses the same machinery on
purpose.

---

# Part 5 — What if someone deliberately exploits the gaps? (25 min)

**⚠ PLACEHOLDER** — presentation not written; the S06 cache-integrity lab is
still to build. The reverse-provenance lab **is built** (S07, below). Outline:
[`workshop/05-integrity-provenance.md`](./workshop/05-integrity-provenance.md)

Everything demonstrated in Part 2 was *legitimate*. The same mechanisms
(plugin execution, lifecycle scripts, build backends, generated files) are
also attack surface, alongside dependency confusion, typosquatting and
compromised releases.

## The reverse-provenance lab (S07, ~10–12 min)

Lab: [`scenarios/S07-provenance-s01`](./scenarios/S07-provenance-s01/OVERVIEW.md). Reuses S01's image, so there is no new app to build.

Start from S01's finished Docker image and try to trace it home. The baseline
answers nothing: the only label present is the base image's inherited
`22.04`, the JAR names no commit, there is no SBOM, and nothing is signed.

Then record provenance in four layers, re-auditing after each:

```text
1. git commit    git-commit-id plugin writes git.properties INTO the JAR
2. OCI labels    org.opencontainers.image.revision / .source on the image
3. SBOM          syft builds a CycloneDX inventory keyed to the image digest
4. attestation   cosign signs the digest and attests the SBOM to it
```

The point is the ladder: an embedded commit is a claim anyone can fake, an OCI
label is the same trust tier (an unsigned claim, just easier for tools to
find), an SBOM is a claim about contents, and only the signed attestation can
be **verified** by someone who does not trust your build. With the public key
alone: `signature: VERIFIED`, `attestation: VERIFIED`. In practice a lot of
pipelines never climb past the unsigned rungs.

## The other Part 5 threads

Planned still-to-build lab: corrupt a cached Maven artefact and see what the
build does and doesn't check (S06, ~10 min).

Also planned here: what a scanner finds once it **reads the code** instead of
the metadata. [`investigations/T08-guarddog`](./investigations/T08-guarddog/OVERVIEW.md)
runs GuardDog against S05 and S03 and gets two clean results for opposite
reasons: the mechanism excluded from the artefact (S05), and the mechanism
present but benign (S03). A malicious positive control proves the scanner
fires. Reading code beats reading metadata, and a clean score still is not a
safety proof. (True dynamic behaviour analysis, running the package and
watching it, is the heavier tool named but not run here.)

The section's conclusion is already fixed:

```text
Control what comes in.
Verify the bytes you receive.
Preserve evidence of how they were produced.
```

---

# Part 6 — AI and the supply chain (20 min)

**⚠ PLACEHOLDER** — presentation and demo not built yet. Outline:
[`workshop/06-ai-dependencies.md`](./workshop/06-ai-dependencies.md)

AI coding tools are changing who chooses your dependencies: larger trees,
poorer picks, and packages that never existed, until an attacker registers
the hallucinated name and your next `install` makes it real. Planned
centrepiece: dissecting a real piece of AI-generated malware.

The section's conclusions are already fixed:

```text
An AI-suggested dependency enters the same supply chain
with less human scrutiny.

A hallucinated package name is free attack surface.
```

**You should now know:** why the volume and provenance of AI-suggested
dependencies changes the risk model, even though every technique from
Parts 2–5 still applies unchanged.

---

# Part 7 — Wrap-up (10 min)

Back to the opening question: *can you tell me exactly what software this
application contains?* No single tool answers every reading of it, because
each tool observes one boundary:

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

Overlaid on that: vulnerability data, exploit data, project health,
lifecycle/EOL.

## When you get home

Five things to run against **your own** project this week:

```text
1. Generate an SBOM two ways — build model and artefact scan — and diff them.
2. Take one scanner finding and trace what had to be true: identity, CPE
   range, record date.
3. Check the EOL status of everything in your stack, not just the vulnerable.
4. Run OpenSSF Scorecard on the dependency you'd miss most.
5. Verify every name in your lockfiles exists upstream and is the package
   you think it is.
```

The operating model to take home:

```text
Know what you requested.
Observe what the build actually did.
Inventory what you shipped.
Preserve how it got there.
Continuously reassess vulnerability and support state.
```

---

# Going deeper

Nothing below is part of the timed route.

**Optional lab** — same lessons, another ecosystem:

- [S02 — Payara + mvnpm](./scenarios/S02-payara-mvnpm/OVERVIEW.md), if you use Jakarta EE

**Reference investigations** — one tool at a time, in depth:

- [T01 per-scenario Snyk traces](./investigations/T01-snyk-beyond-sbom/OVERVIEW.md)
- [T02 — Docker Scout](./investigations/T02-docker-scout/OVERVIEW.md)
- [T03 — Trivy](./investigations/T03-trivy-s01/OVERVIEW.md)
- [T04 — Grype](./investigations/T04-grype-s02/OVERVIEW.md)
- [T05 — pip-audit](./investigations/T05-pip-audit-s03/OVERVIEW.md)
- [T06 — OWASP Dependency-Check](./investigations/T06-owasp-dependency-check-s04/OVERVIEW.md)
- [T07 — npm audit](./investigations/T07-npm-audit-s05/OVERVIEW.md)

**Tool reference:** [`reference/tools.md`](./reference/tools.md): every
tool the workshop touches, grouped by the evidence boundary it observes,
with the blind spot each lab demonstrated.

Every lab's `TRACE.md` is the full annotated walkthrough behind the short
exercise you did here.
