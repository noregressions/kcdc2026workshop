# Facilitator Guide

Operational delivery guide and timing benchmarks for instructors leading the Software Supply Chain Trace Lab.

Reference benchmarks were measured on Apple Silicon (2026-08-24, warm caches). Execution durations represent machine execution baselines; section budgets account for narration and analysis.

---

## Pre-Workshop Environment Verification

Execute verification on the presenter machine prior to delivery:

```bash
./scripts/tools-check.sh                                         # Must exit 0
./scripts/build-all.sh                                           # Must report 0 failed
snyk whoami                                                      # Verify active authentication
printenv NVD_API_KEY                                             # Verify key export for elevated rate limits
cd investigations/CVE-tomcat-85 && ./scripts/proof-check.sh       # Must pass 14/14 checks
cd ../..
```

### Fallback Container Deployment

If an attendee environment cannot be resolved locally, deploy the preconfigured container environment (Docker required):

```bash
./container/build.sh && ./container/run.sh
```

Pre-warm the container base image (`./container/build.sh --base`) to ensure vulnerability databases are initialized.

### Live Network Dependencies and Offline Fallbacks

| Workshop Section | Target Resource | Fallback Strategy |
|---|---|---|
| Part 1 Machine Validation | Image pulls & vulnerability DBs | Resolve during introductory lecture |
| Part 2 Step 5 (Snyk SCA) | Snyk API (~37s execution) | Inspect pre-captured outputs in `results/` |
| Part 3 Tomcat Investigation | CVE.org and NVD APIs | Query pre-captured JSON payloads in `evidence/` |
| Part 4 Guided Web Inspection | Scorecard, OSS Index, EOL data | Reference pre-captured reports in `evidence/` |

Note: Instruct attendees to query local `evidence/` files with `jq` in Part 3 to prevent unauthenticated NVD API rate-limiting (5 requests per 30 seconds).

---

## Session Timetable

```text
0:00 - 0:15   Part 1: Supply-Chain Fundamentals               15 min
0:15 - 1:15   Part 2: Software Identifiability Boundaries     60 min
1:15 - 1:50   Part 3: Vulnerability Ingestion & CPE Matching  35 min
1:50 - 2:10   Break                                           20 min
2:10 - 2:35   Part 4: Project Health & Lifecycle EOL Data     25 min
2:35 - 3:00   Part 5: Malicious Vectors & Defensive Controls  25 min
3:00 - 3:20   Part 6: AI Tooling & Dependency Ingress         20 min
3:20 - 3:30   Part 7: Synthesis & Implementation Summary      10 min
```

### Schedule Verification Checkpoints

- **0:45:** S01 and S04 completed. If behind schedule, convert S05 and S03 into instructor demonstrations.
- **1:15:** Part 2 concluded with the Evidence Boundary Taxonomy table.
- **1:45:** Tomcat investigation steps 1–6 completed; proceed to steps 7–8 (EOL comparisons).

---

# Part 1: Supply-Chain Fundamentals (0:00–0:15)

Outline: [`workshop/01-supply-chain.md`](./workshop/01-supply-chain.md)

Direct attendees to initialize environment verification immediately:

```bash
./scripts/tools-check.sh
./scripts/build-all.sh
```

Key concept: The distinction between declared dependency manifests and actual deployed runtime composition.

---

# Part 2: Software Identifiability Across Boundaries (0:15–1:15)

## Step 1: S01 Transformation (0:15–0:30)

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

## Step 2: S04 Hidden Build Content (0:30–0:45)

| Command | Expected Verification Output |
|---|---|
| `mvn -Dmaven.repo.local=... dependency:tree` | Root artifact only; zero application dependencies |
| `./scripts/run.sh` | Runtime listening on port 8082 |
| `curl -sS http://localhost:8082/hidden/build-info \| jq` | Injected endpoint confirms `trace-route-payload` execution |
| `unzip -l ... \| grep -E 'Generated\|services'` | `GeneratedTraceRoute.class` and service provider configuration |
| `./scripts/stop.sh` | Process terminated |

Technical conclusion: Dependency resolvers evaluate the application dependency tree, omitting transitive dependencies inside build plugin execution realms.

## Step 3: S05 npm Lifecycle Hooks (0:45–0:53)

- Verify execution of `npm notice run ... prepack`.
- Confirm tarball contains generated `dist/` files absent from repository source.
- Port: 8083.

## Step 4: S03 Python PEP 517 Build Backends (0:53–1:01)

- Tarball contains only `pyproject.toml` and `tracehook_backend.py`.
- Verify `site-packages` receives generated `__init__.py` created during `pip install`.
- Port: 8081.

## Step 5: T01 Commercial SCA Evaluation (1:01–1:06)

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

# Part 3: Vulnerability Ingestion and CPE Matching (1:15–1:50)

Guided analysis: [`investigations/CVE-tomcat-85/TRACE.md`](./investigations/CVE-tomcat-85/TRACE.md)

1. **Severity Classification:** Compare Apache CNA ("Important") against CVSS v2 (7.5) and CVSS v3.1 (9.8 CRITICAL).
2. **CPE Configurations:** 38 matching entries; 20 Oracle embedding CPEs added 26 months post-disclosure.
3. **Exploitation Latency:** CISA KEV listing occurred March 2022 (public exploits available February 2020).
4. **EOL Omission:** EOL Tomcat 6.x omitted from structured CPE matching in CVE-2020-1938 vs unbounded matching in CVE-2025-24813 (`* < 9.0.99`).

Technical conclusion: Vulnerability records are evolving documents. Scanner findings reflect point-in-time joins against mutable upstream databases.

---

# Break (1:50–2:10)

---

# Part 4: Project Health and Software Lifecycle EOL (2:10–2:35)

Guide: [`workshop/04-project-health-eol.md`](./workshop/04-project-health-eol.md)

1. **OpenSSF Scorecard:** Evaluate `lodash` repository hygiene metrics (Maintained: 10 vs Vulnerabilities: 0).
2. **Coordinate Indexing:** Compare Scorecard findings against Sonatype OSS Index query for `pkg:npm/lodash@4.17.21`.
3. **Lifecycle EOL Sweep:** Run `npx @herodevs/cli scan eol --dir .` or inspect `evidence/herodevs.report.json`.
   - `spring-boot:3.5.12`: Open-source support ended 30 June 2026.
   - `apache-tomcat:8.5`: EOL 31 March 2024.

Technical conclusion: A clean vulnerability query indicates the absence of indexed CVEs at query execution time. Scanner silence on EOL components indicates lack of upstream triage rather than verified security.

---

# Part 5: Malicious Execution Vectors and Defensive Controls (2:35–3:00)

1. **Static AST Analysis (T08 / GuardDog):** AST code inspection across package archives vs metadata analysis.
2. **Layered Reverse Provenance (S07):**
   - Layer 1: Embedded build metadata (`git.properties`).
   - Layer 2: OCI image annotations.
   - Layer 3: Cryptographic CycloneDX SBOM.
   - Layer 4: Cosign digital signatures and in-toto attestations.

Technical conclusion: Defensive architecture requires controlled ingress, cryptographic cache integrity verification, and cryptographically verifiable provenance attestations.

---

# Part 6: AI Tooling and Automated Ingress (3:00–3:20)

Outline: [`workshop/06-ai-dependencies.md`](./workshop/06-ai-dependencies.md)

- Analysis of dependency profile expansion under automated generation.
- Package name hallucinations and preemptive namespace registration attacks.
- Dissection of AI malware patterns (restricted to isolated instructor environments).

---

# Part 7: Synthesis and Wrap-Up (3:20–3:30)

Review the complete boundary transition model and deliver the operational implementation checklist.

---

## Timing Contingency Plans

If behind schedule, apply adjustments in the following order:
1. S05 (npm prepack): Transition to 3-minute instructor demonstration (saves 5 min).
2. S03 (PEP 517): Transition to 3-minute instructor demonstration (saves 5 min).
3. S01 lodash step: Limit inspection to `syft frontend/dist` (saves 3 min).
4. Part 3 steps 5–6: Summarize via timeline comparison table (saves 5 min).
5. Part 4 Scorecard: Restrict inspection to Maintained and Vulnerability checks (saves 5 min).

Critical milestones that must not be omitted:
- Part 1 environment validation.
- S01 metadata stripping experiment.
- S04 hidden build content demonstration.
- Part 3 EOL comparison steps (Tomcat 6.x vs 8.5).
- Part 4 lifecycle EOL distinction.
- Part 7 complete evidence architecture model.

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
