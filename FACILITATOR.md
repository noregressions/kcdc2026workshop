# Facilitator Guide

Operational delivery guide for instructors leading the Software Supply Chain Trace Lab.

The route is a sequence. Work through the parts in order and let each lab run until the room has it; the compression list at the foot says what to give up first if you have to.

---

## Pre-Workshop Environment Verification

Execute verification on the presenter machine prior to delivery:

```bash
./scripts/tools-check.sh                                         # Must exit 0
./scripts/build-all.sh                                           # Must report 0 failed
snyk whoami                                                      # Verify active authentication
printenv NVD_API_KEY                                             # Verify key export for elevated rate limits
cd investigations/T10-cve-tomcat-85 && ./scripts/proof-check.sh       # Must pass 14/14 checks
cd ../..
```

### Fallback Container Deployment

If an attendee environment cannot be resolved locally, deploy the preconfigured container environment (Docker required):

```bash
./container/run.sh
```

This pulls the published image `noregressions/ydnwys-workshop:0.0.1` from Docker Hub (about 2.6 GB). Ask attendees to pull it on the venue network ahead of time.

Before the workshop, republish so the vulnerability databases are fresh: `./container/publish.sh <version>` rebuilds both images for amd64 and arm64 and pushes them (requires a Docker Hub login with write access to the `noregressions` namespace; the amd64 half is slow on Apple silicon). Bump the tag in `container/run.sh` to match.

### Live Network Dependencies and Offline Fallbacks

| Workshop Section | Target Resource | Fallback Strategy |
|---|---|---|
| Part 1 Machine Validation | Image pulls & vulnerability DBs | Resolve during introductory lecture |
| Part 2 Step 5 (Snyk SCA) | Snyk API (~37s execution) | Inspect pre-captured outputs in `results/` |
| Part 3 Tomcat Investigation | CVE.org and NVD APIs | Query pre-captured JSON payloads in `evidence/` |
| Part 4 Guided Web Inspection | Scorecard, OSS Index, EOL data | Scorecard PDF in `workshop/evidence/`; the EOL scan has no capture |
| Part 6 `ship-check.sh` | npx / registry for the EOL step | The script skips that section and continues |

Note: Instruct attendees to query local `evidence/` files with `jq` in Part 3 to prevent unauthenticated NVD API rate-limiting (5 requests per 30 seconds).

---

## Session Order

```text
                                                     ACT
Part 1   What is actually in our software?            1
Part 2   Can we identify what we ship?                1
Part 3   What does a CVE finding actually mean?       2
Break                                                 —
Part 4   CVEs aren't enough                           2
Part 5   Someone is counting on that                  3
Part 6   The minimum that keeps you honest            4
```

The AI strand is parked: the notes survive as
`workshop/appendix-ai-dependencies.md` and are not on the route. S02 and S08
became core route on 2026-09-08; nothing in Parts 1 to 6 is optional.

### Progress Checkpoints

Points where you should confirm the room is with you before moving on.

- **After S01 and S04:** everyone has seen a named dependency vanish from its own SBOM, and an endpoint that no source file defines. If either did not land, re-run it; everything after this is built on those two.
- **After S08:** the 0-versus-171 contrast. Short, and the only good news in Part 2 — never cut it.
- **After S02:** the composite case. Longest single lab; the `mvn -X | grep lodash-es` reveal is the part that must happen.
- **End of Part 2:** the Evidence Boundary Taxonomy table, including the S08 row. Every later part refers back to it.
- **Part 3:** Tomcat investigation steps 1–6 before moving on to steps 7–8 (the EOL comparisons).
- **End of Part 4:** the three-failure-modes synthesis (tool gap / CVE process / EOL, all on Tomcat 8.5). This is the hinge into Act 3 — never cut it.
- **After S07:** provenance complete, and Part 6 still ahead of you. Part 6 is the only part attendees run against their own work afterwards; protect it.

---

# Part 1: What Is Actually in Our Software?

Outline: [`workshop/01-supply-chain.md`](./workshop/01-supply-chain.md)

Direct attendees to initialize environment verification immediately:

```bash
./scripts/tools-check.sh
./scripts/build-all.sh
```

Key concept: The distinction between declared dependency manifests and actual deployed runtime composition. The chapter also lays out the four acts — worth putting on screen, because it is the only orientation attendees get.

---

# Part 2: Can We Identify What We Ship?

Seven stops, six of them hands-on. S08 and S02 joined the core route on
2026-09-08; nothing in this part is optional.

## Step 1: S01 Transformation

| Command | Expected Verification Output |
|---|---|
| `mvn -pl service dependency:tree -Dincludes=...jackson-databind` | `jackson-databind:jar:2.19.4:compile` |
| `syft service/target/service-1.0.0.jar \| grep -i jackson` | Package inventory matches resolver output |
| `syft normalizer/target/normalizer-1.0.0.jar` | `commons-codec:1.17.1` detected in shaded JAR |
| `./scripts/strip-codec-metadata.sh` | Metadata removed: `commons-codec` omitted from scan output |
| `npm --prefix frontend ls lodash` | `lodash@4.17.21` |
| `grep -oE "__lodash_hash..." dist/assets/*.js` | Bytecode sentinels and version strings confirmed in bundle |
| `syft frontend/dist` | `No packages discovered` |

Technical conclusion: Static scanners rely on metadata rather than code syntax. Build transformations can destroy identity evidence while preserving executable logic.

## Step 2: S04 Hidden Build Content

| Command | Expected Verification Output |
|---|---|
| `mvn -Dmaven.repo.local=... dependency:tree` | Root artifact only; zero application dependencies |
| `./scripts/run.sh` | Runtime listening on port 8082 |
| `curl -sS http://localhost:8082/hidden/build-info \| jq` | Injected endpoint confirms `trace-route-payload` execution |
| `unzip -l ... \| grep -E 'Generated\|services'` | `GeneratedTraceRoute.class` and service provider configuration |
| `./scripts/stop.sh` | Process terminated |

Technical conclusion: Dependency resolvers evaluate the application dependency tree, omitting transitive dependencies inside build plugin execution realms.

## Step 3: S08 Extended SBOM

Lab reference: [`scenarios/S08-extended-sbom/LESSON.md`](./scenarios/S08-extended-sbom/LESSON.md)

| Command | Expected Verification Output |
|---|---|
| `./scripts/seed-plugin.sh` | Offline machines only; installs SBOM+ into `~/.m2` |
| `./scripts/scan-s04.sh` | standard: 0 components. extended: 171, all `excluded`, including `trace-injector-maven-plugin` and `trace-route-payload` |
| `./scripts/scan-s01.sh` | standard: 38. extended: 265 (230 `excluded`), including `maven-shade-plugin` |

Technical conclusion: the S04 gap is a property of the evidence source, not of the artefact. The information existed at build time; nothing recorded it. This is the setup for Part 6.

Presenter note: on a packaged-but-not-installed checkout, SBOM+ warns that it cannot resolve S01's `normalizer` sibling. Show the warning, then `(cd ../S01-spring-node && mvn -q install -DskipTests)` and re-run — "could not resolve" and "not present" look different and mean different things.

## Step 4: S05 npm Lifecycle Hooks

- Verify execution of `npm notice run ... prepack`.
- Confirm tarball contains generated `dist/` files absent from repository source.
- Port: 8083.

## Step 5: S03 Python PEP 517 Build Backends

- Tarball contains only `pyproject.toml` and `tracehook_backend.py`.
- Verify `site-packages` receives generated `__init__.py` created during `pip install`.
- Port: 8081.

## Step 6: S02 Payara + mvnpm

Lab reference: [`scenarios/S02-payara-mvnpm/LESSON.md`](./scenarios/S02-payara-mvnpm/LESSON.md)

The realistic composite: WAR packaging, mvnpm registry translation, and a plugin execution realm in one Jakarta EE build. Longest lab on the route.

| Command | Expected Verification Output |
|---|---|
| `./scripts/build.sh` | esbuild bundles `lodash-es` into `assets/app.js`, then the WAR is assembled |
| `mvn dependency:tree -Dincludes=org.apache.commons:commons-lang3` | `commons-lang3:jar:3.18.0:compile` — the control behaves |
| `mvn dependency:tree -Dincludes=org.mvnpm:lodash-es` | Nothing. Not a project dependency. |
| `mvn dependency:resolve-plugins -DincludeArtifactIds=esbuild-maven-plugin` | Plugin listed; its own dependencies still not |
| `mvn -X generate-resources 2>&1 \| grep 'org.mvnpm:lodash-es'` | `[DEBUG] org.mvnpm:lodash-es:jar:4.17.21:runtime` — the only place it is ever named |

Technical conclusion: three identity losses in one ordinary enterprise build — packaging, plugin realm, and registry translation between npm and Maven.

Compression: run only the four `mvn` lines above as a demo and skip the WAR, exploded-deployment and image steps.

## Step 7: T01 Commercial SCA Evaluation

Execute on presenter screen:

```bash
cd investigations/T01-snyk-beyond-sbom
./scripts/baseline.sh
./scripts/run-snyk.sh
./scripts/compare.sh
cd ../..
```

Technical conclusion: Algorithmic analysis cannot reconstruct component identity when evidence was destroyed during build transformations.

---

# Part 3: What Does a CVE Finding Actually Mean?

Guided analysis: T10 — [`investigations/T10-cve-tomcat-85/LESSON.md`](./investigations/T10-cve-tomcat-85/LESSON.md)

1. **Severity Classification:** Compare Apache CNA ("Important") against CVSS v2 (7.5) and CVSS v3.1 (9.8 CRITICAL).
2. **CPE Configurations:** 38 matching entries; 20 Oracle embedding CPEs added 26 months post-disclosure.
3. **Exploitation Latency:** CISA KEV listing occurred March 2022 (public exploits available February 2020).
4. **EOL Omission:** EOL Tomcat 6.x omitted from structured CPE matching in CVE-2020-1938 vs unbounded matching in CVE-2025-24813 (`* < 9.0.99`).

5. **Three scanners, one target (T09):** results are captured (2026-09-08); put `results/s01/compare/matrix.txt` on screen rather than running three scanners live. Two things to land: the ten identifiers at `service-jar` that are five defects both tools agree on, and the `service-pom` row where all three tools come back differently — one of them because OSV-Scanner identified `jackson-databind` with no version and so had nothing to join against.

Technical conclusion: Vulnerability records are evolving documents. Scanner findings reflect point-in-time joins against mutable upstream databases.

---

# Break

---

# Part 4: CVEs Aren't Enough

Guide: [`workshop/04-project-health-eol.md`](./workshop/04-project-health-eol.md)

1. **OpenSSF Scorecard:** Evaluate `lodash` repository hygiene metrics (Maintained: 10 vs Vulnerabilities: 0).
2. **Coordinate Indexing:** Query deps.dev for `lodash@4.17.21` — three advisory IDs, two distinct defects after alias resolution. Then the two beats that carry the part: the artefact has not changed since February 2021 and the answer has, and the OSS Index query that produced this repository's original zero now 401s behind a redirect to a commercial product. Evidence for both is in `workshop/evidence/` (see `CAPTURED.md`); do not depend on live services here.
3. **Lifecycle EOL Sweep:** Run `npx @herodevs/cli scan eol --dir .`. There is no captured fallback in the repository — if the network is down, read the table in the chapter and say so.
   - `spring-boot:3.5.12`: Open-source support ended 30 June 2026.
   - `apache-tomcat:8.5`: EOL 31 March 2024.
4. **Close Act 2:** the three-failure-modes synthesis on Tomcat 8.5 — tool capability gap (Part 2), CVE process failure (Part 3), EOL blind spot (Part 4), one component, all three at once. This is the payoff for Acts 1 and 2.

Technical conclusion: A clean vulnerability query indicates the absence of indexed CVEs at query execution time. Scanner silence on EOL components indicates lack of upstream triage rather than verified security.

Note: the Scorecard capture in the repository is `workshop/evidence/openssf-scorecard-lodash-2026-08-18.pdf` (a PDF, not JSON) — open it directly if scorecard.dev is slow.

---

# Part 5: Someone Is Counting on That

Chapter: [`workshop/05-attacks-and-provenance.md`](./workshop/05-attacks-and-provenance.md)

Open with the ingress mechanisms — dependency confusion, typosquatting, maintainer compromise — and land the xz-utils point: the backdoor was in the release tarball and not in the git repository, which is the mechanism attendees built themselves in S05. That callback is the spine of the part.

1. **Static AST Analysis (T08 / GuardDog):** AST code inspection across package archives vs metadata analysis. Probes 3 and 4 (the malicious variant) are the ones to run live; 1 and 2 can be summarised.
2. **Layered Reverse Provenance (S07):**
   - Layer 1: Embedded build metadata (`git.properties`).
   - Layer 2: OCI image annotations.
   - Layer 3: Cryptographic CycloneDX SBOM.
   - Layer 4: Cosign digital signatures and in-toto attestations.

Technical conclusion: Defensive architecture requires controlled ingress, cryptographic cache integrity verification, and cryptographically verifiable provenance attestations.

---

# Part 6: The Minimum That Keeps You Honest

Chapter: [`workshop/06-minimum-practice.md`](./workshop/06-minimum-practice.md)

Hands-on, and the only part attendees will use on Monday. Give it the full budget.

```bash
./scripts/ship-check.sh scenarios/S01-spring-node
```

- Section 3 of the output is the whole point: declared-but-not-identifiable (S01's shading and bundling) and in-artefact-but-not-declared (point it at S04 to show this half).
- The script skips loudly when a tool is missing. If `syft` is absent on attendee machines, the second inventory is empty and the diff cannot run — flag this during the Part 1 tools check, not here.
- Close on the four decisions (upgrade / patch in-house / accept with a date / buy support) and the take-home card.

---

## Compression Order

If you need to move faster, give ground in this order — roughly most room recovered first, and each one keeps the finding while dropping the walkthrough.

1. **S02:** run the four `mvn` lines as a demo; skip the WAR, exploded-deployment and image steps.
2. **S07:** present layers 1–3 from the chapter table; run only layer 4.
3. **S05** and **S03**: instructor demonstration rather than hands-on. They repeat S04's mechanism in other ecosystems, so the room has already met the idea.
4. **S08:** run `scan-s04.sh` only; skip the S01 comparison.
5. **T08:** run the malicious-payload probe only; summarise the other three.
6. **Part 3 steps 5–6:** summarise via the timeline comparison table.
7. **Part 4 Scorecard:** restrict inspection to the Maintained and Vulnerabilities checks.
8. **S01 lodash step:** limit inspection to `syft frontend/dist`.

Never omitted, whatever else goes:
- Part 1 environment validation.
- S01 metadata stripping experiment.
- S04 hidden build content demonstration.
- S08 `scan-s04.sh` — the 0-vs-171 contrast is what makes Part 6 land.
- Part 3 EOL comparison steps (Tomcat 6.x vs 8.5).
- Part 4 lifecycle EOL distinction, and the Act 2 synthesis that closes it.
- Part 5 ingress mechanisms (they carry objective 1's second half; the labs do not).
- Part 6 `ship-check.sh` run and the take-home card.

---

## Diagnostics and Troubleshooting

### Port Conflicts (8080, 8081, 8082, 8083)

`run.sh` halts if target ports are active. Terminate background processes:

```bash
./scripts/stop.sh
# If PID file is missing:
lsof -nP -iTCP:8082 -sTCP:LISTEN
kill <PID>
```

### Script Permission Errors

Restore executable bits:

```bash
chmod +x scripts/*.sh scenarios/*/scripts/*.sh investigations/*/scripts/*.sh
```

### Maven Dependency Tree Omission

`mvn -q dependency:tree` suppresses INFO-level logging. Remove `-q` flag to display tree output.

### Build Failures During `build-all.sh`

`build-all.sh` continues execution across failed phases. Inspect the final summary report to identify specific module failures.

### Snyk Authentication Failures

If `snyk whoami` returns non-zero, do not run interactive authentication during presentations. Use pre-captured outputs in `results/`.

### NVD API Rate Limiting (HTTP 403 / Hangs)

Unauthenticated requests to NVD are subject to rate limits (5 requests per 30 seconds). Direct attendees to inspect pre-captured records in `evidence/`.

### Docker Engine Out of Disk Space

Docker Desktop disk exhaustion causes runtime mounts to switch to read-only mode.
Resolution: Reclaim host disk space, restart Docker Desktop, and execute `docker system prune -f`.
