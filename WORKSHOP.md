# Workshop Execution Guide

Timed execution track for the Software Supply Chain Trace Lab. Follow modules sequentially from Part 1 through Part 7.

## Environment Initialization

Execute from the repository root:

```bash
./scripts/tools-check.sh    # Verify required tooling
./scripts/build-all.sh      # Pre-warm caches and compile targets
```

## Core Evaluation Framework

All modules evaluate three technical criteria across each supply chain boundary:

```text
1. Evidence: What evidence indicates that this component is present?
2. Identity: What attributes identify the component (coordinates, hashes, metadata)?
3. Boundary Limits: What transformations or components are omitted by this evidence source?
```

## Terminology

| Term | Technical Definition |
|---|---|
| declaration | Requested dependency specification in manifest/POM |
| resolution | Concrete versions resolved by dependency solver |
| build-time software | Executable code in build plugins and backends |
| transformation | Structural alteration (bytecode shading, relocation, JS bundling) |
| artifact | Packaged binary distribution (JAR, WAR, tarball, wheel) |
| inventory | List of components reported by an evidence producer (SBOM, scanner report) |
| identity | Unique component identifier (PURL, CPE, checksum) |
| provenance | Cryptographic record of build source and generation steps |
| vulnerability | Correlated security advisory record against an identified component |
| lifecycle / EOL | Upstream support commitment and maintenance state |

## Execution Route

```text
Part 1   Supply-Chain Fundamentals               15 min   Architecture Overview
Part 2   Software Identifiability Across Limits  60 min   Hands-on Build Traces
Part 3   Vulnerability Ingestion and CPE Data    35 min   Analysis & API Probes
Break                                            15 min
Part 4   Project Health & Lifecycle EOL Data     25 min   Scorecard & EOL Scanning
Part 5   Malicious Vectors & Defensive Controls  25 min   Provenance & Code Scanning
Part 6   AI Tooling & Dependency Ingress         20 min   Malware Dissection
Part 7   Synthesis & Implementation Framework    10 min   Operational Summary
```

---

# Part 1: Supply-Chain Fundamentals (15 min)

Session outline: [`workshop/01-supply-chain.md`](./workshop/01-supply-chain.md)

## Environment Validation Check

```bash
./scripts/tools-check.sh
./scripts/build-all.sh
```

## Core Concepts

- Expanding supply chain scope beyond declared dependencies to include build plugins, build tools, compiler runtimes, base images, and system packages.
- Technical distinction between *declared dependency trees* and *deployed runtime composition*.

---

# Part 2: Software Identifiability Across Boundaries (60 min)

Evaluation of component identifiability across build transformations, plugin execution, lifecycle hooks, and build backends.

## Step 1: Build Transformations and Metadata Stripping (15 min)

Lab reference: [`scenarios/S01-spring-node/TRACE.md`](./scenarios/S01-spring-node/TRACE.md)

**Objective:** Evaluate component detection across standard resolution, bytecode shading, and frontend bundling.

### 1.1 Control Baseline (jackson-databind)

```bash
cd scenarios/S01-spring-node
./scripts/build.sh
mvn -pl service dependency:tree -Dincludes=com.fasterxml.jackson.core:jackson-databind
syft service/target/service-1.0.0.jar | grep -i jackson
```

**Expected output:** Resolver outputs `jackson-databind:2.19.4`. Syft artifact scan of the packaged JAR identifies `jackson-databind:2.19.4`.

### 1.2 Bytecode Relocation & Metadata Stripping (commons-codec)

```bash
syft normalizer/target/normalizer-1.0.0.jar
./scripts/strip-codec-metadata.sh
```

**Expected output:** Initial scan reports `commons-codec:1.17.1`. After stripping `META-INF/maven/...` metadata from the shaded JAR without altering bytecode, Syft fails to detect `commons-codec`.

### 1.3 JavaScript Bundling (lodash)

```bash
npm --prefix frontend ls lodash
grep -oE "__lodash_hash_undefined__|4\.17\.21" frontend/dist/assets/*.js | sort | uniq -c
syft frontend/dist
```

**Expected output:** `npm ls` reports `lodash@4.17.21`. Grep confirms version strings and sentinel functions exist in the minified bundle. Syft returns `No packages discovered`.

**Technical Finding:** Static scanners rely on embedded package metadata rather than code syntax. When builds omit or strip metadata, software presence diverges from software identifiability.

---

## Step 2: Build Plugin Execution Realms (15 min)

Lab reference: [`scenarios/S04-maven-plugin-hidden-content/TRACE.md`](./scenarios/S04-maven-plugin-hidden-content/TRACE.md)

**Objective:** Measure visibility of code injected via Maven plugin execution where the project dependency graph is empty.

```bash
cd scenarios/S04-maven-plugin-hidden-content
./scripts/build.sh
mvn -Dmaven.repo.local="$PWD/.maven-repo" dependency:tree
./scripts/run.sh
curl -sS http://localhost:8082/hidden/build-info | jq
unzip -l target/maven-plugin-hidden-content-1.0.0.jar | grep -E 'Generated|services'
./scripts/stop.sh
```

**Expected output:** `dependency:tree` outputs only the root artifact. The running application serves `/hidden/build-info` injected by `trace-injector-maven-plugin` via build-phase code generation.

**Technical Finding:** Dependency resolvers evaluate the application dependency graph; they do not index transitive dependencies inside plugin execution ClassRealms.

---

## Step 3: Package Lifecycle Hooks (8 min)

Lab reference: [`scenarios/S05-node-prepack/TRACE.md`](./scenarios/S05-node-prepack/TRACE.md)

**Objective:** Inspect runtime artifact generation occurring during package creation hooks (`prepack`).

```bash
cd scenarios/S05-node-prepack
./scripts/build.sh
tar -tzf npm-repo/trace-route-package-1.0.0.tgz
./scripts/run.sh
curl -sS http://localhost:8083/hidden/prepack-info | jq
./scripts/stop.sh
```

**Expected output:** Build output logs `npm notice run ... prepack` executing `generate-dist.js`. Tarball contains generated `dist/` files absent from repository source.

**Technical Finding:** Package creation hooks allow package code to execute before the distributable tarball is created.

---

## Step 4: Python PEP 517 Build Backends (8 min)

Lab reference: [`scenarios/S03-python-pep517/TRACE.md`](./scenarios/S03-python-pep517/TRACE.md)

**Objective:** Evaluate package generation executed during `pip install` by source distribution build backends.

```bash
cd scenarios/S03-python-pep517
./scripts/build.sh
tar -tzf python-repo/tracehook_demo-1.0.0.tar.gz
ls .venv/lib/python*/site-packages/tracehook_demo/
./scripts/run.sh
curl -sS http://localhost:8081/trace | jq
./scripts/stop.sh
```

**Expected output:** The sdist archive contains only `pyproject.toml` and `tracehook_backend.py`. During `pip install`, the build backend generates the imported package files in `site-packages`.

**Technical Finding:** Package managers supporting build backends delegate artifact construction to executable code in the package distribution.

---

## Step 5: Commercial SCA Boundary Evaluation (5 min)

Investigation reference: [`investigations/T01-snyk-beyond-sbom/TRACE.md`](./investigations/T01-snyk-beyond-sbom/TRACE.md)

**Analysis against S04 ground truth:** Static analysis across SBOMs and binary hashes cannot identify components when no coordinate or signature evidence is preserved in the target artifact:

```text
Algorithmic analysis cannot reconstruct evidence omitted during build transformations.
```

## Part 2 Evidence Boundary Taxonomy

| Evidence Source | Data Inputs Observed | Systematic Blind Spots |
|---|---|---|
| Manifest / POM | Declared project model | Dynamically generated or transformed components |
| Resolver | Resolved dependency tree | Transitive dependencies inside plugin execution realms |
| SBOM | Producer-specific inspection | Components outside producer's evidence domain |
| Artifact Scanner | Packaged archives & file metadata | Shaded/relocated bytecode lacking metadata |
| Image Scanner | Filesystem layers and OS packages | Build-time compilation and source provenance |

---

# Part 3: Vulnerability Records and CPE Matching Mechanics (35 min)

Analysis of the vulnerability ingestion pipeline and empirical evaluation of record mutability.

Outline: [`workshop/03-vulnerabilities.md`](./workshop/03-vulnerabilities.md)

```text
software -> identity -> package/product mapping -> CVE record -> affected versions -> scanner matching -> finding
```

## Case Study: Apache Tomcat 8.5 (Ghostcat / CVE-2020-1938)

Investigation reference: [`investigations/CVE-tomcat-85/TRACE.md`](./investigations/CVE-tomcat-85/TRACE.md)

Data source: `evidence/cve-org.json`, `evidence/nvd.json`, `evidence/nvd-history.json`.

### Technical Findings

1. **Severity Scoring Divergence:** Apache CNA ("Important") vs NVD CVSS v2 (7.5) vs NVD CVSS v3.1 (9.8 CRITICAL).
2. **CPE Matching Dependencies:** Scanner match requires exact vendor (`apache`), product (`tomcat`), and version criteria (`8.5.0` to `< 8.5.51`).
3. **Embedded Dependency Latency:** 20 Oracle embedding CPE configurations were added to NVD 26 months post-initial publication.
4. **CISA KEV Addition:** Cataloged March 2022 despite public exploit availability in February 2020.
5. **End-of-Life Boundary Handling:**
   - CVE-2020-1938 omits EOL Tomcat 6.x from structured CPE ranges.
   - CVE-2025-24813 documents EOL 8.5 in prose and applies unbounded CPE matching (`* < 9.0.99`).

```text
A CVE is an evolving, versioned event record rather than an immutable static fact.
```

---

# Break (15 min)

---

# Part 4: Project Health Metrics and Software Lifecycle EOL (25 min)

Investigation reference: [`workshop/04-project-health-eol.md`](./workshop/04-project-health-eol.md)

Evaluation of repository engineering hygiene and upstream component maintenance horizons.

## 1. OpenSSF Scorecard Analysis (lodash)

- Evaluate: `https://scorecard.dev/viewer/?uri=github.com/lodash/lodash` (Reference capture in `evidence/scorecard.json`).
- Maintained (10/10) reflects commit frequency; does not guarantee release generation.
- Vulnerabilities (0/10) reflects repository issue tracking; coordinate queries reflect published release artifacts.

## 2. Package Coordinate Vulnerability Index (Sonatype OSS Index)

- Query: `pkg:npm/lodash@4.17.21` (0 vulnerability records).
- Technical definition: Clean query confirms no matching vulnerability record exists at the evaluated coordinates at query execution time.

## 3. Dependency Lifecycle and EOL Sweep

Execute lifecycle scan:

```bash
npx @herodevs/cli scan eol --dir .
```

(Fallback data: `evidence/herodevs.report.json`)

| Component | Target Role | Lifecycle Status |
|---|---|---|
| `jackson-databind:2.19.4` | Direct dependency | Supported |
| `commons-codec:1.17.1` | Shaded dependency | Supported |
| `lodash:4.17.21` | Bundled dependency | Dormant / no formal policy |
| `spring-boot:3.5.12` | Runtime framework | **OSS support ended 30 June 2026** |
| `apache-tomcat:8.5` | S02 runtime container | **EOL 31 March 2024** |

### Lifecycle State Model

```text
vulnerable:            Active security advisory matched and indexed
not known vulnerable:  No active security advisory matched in queried database
unsupported / EOL:     Upstream maintenance ceased; scanner silence indicates absence of active triage
```

---

# Part 5: Malicious Execution Vectors and Defensive Controls (25 min)

Outline: [`workshop/05-integrity-provenance.md`](./workshop/05-integrity-provenance.md)

Evaluation of build execution attack surfaces and layered provenance architectures.

## Layered Reverse Provenance (S07)

Lab reference: [`scenarios/S07-provenance-s01/TRACE.md`](./scenarios/S07-provenance-s01/TRACE.md)

Execution steps:

```bash
cd scenarios/S07-provenance-s01
./scripts/build-baseline.sh
./scripts/add-provenance.sh
```

Audit layers:
1. **Git Commit Metadata:** `git-commit-id-maven-plugin` writes `git.properties` into the JAR (Internal claim).
2. **OCI Annotations:** `org.opencontainers.image.revision` stamped on container image (Unsigned image claim).
3. **Cryptographic SBOM:** Syft generates CycloneDX SBOM keyed to immutable image digest (Content claim).
4. **Digital Signatures / Attestations:** Cosign signs digest and generates in-toto attestation (Cryptographically verifiable proof).

## Code AST Analysis (GuardDog / T08)

Investigation reference: [`investigations/T08-guarddog/TRACE.md`](./investigations/T08-guarddog/TRACE.md)

Static AST analysis of package archives (S05, S03) demonstrating detection capability when source code is packaged vs omitted.

---

# Part 6: AI Tooling and Automated Dependency Ingress (20 min)

Outline: [`workshop/06-ai-dependencies.md`](./workshop/06-ai-dependencies.md)

Analysis of AI code generation risks:
- Transitive dependency expansion.
- Package name hallucinations in generated code.
- Preemptive namespace registration attacks.
- Safe analysis of AI malware fixtures within sandboxed environments.

---

# Part 7: Synthesis and Implementation Framework (10 min)

Outline: [`workshop/07-wrap-up.md`](./workshop/07-wrap-up.md)

## Complete Boundary Transition Model

```text
1. Source Declaration        (Manifests, POMs)
         |
2. Dependency Resolution      (Lockfiles, dependency trees)
         |
3. Build Execution           (Plugin realms, build backends)
         |
4. Artifact Packaging        (Shaded JARs, bundles)
         |
5. Containerization          (Base images, OS packages)
         |
6. Cryptographic Provenance  (Digests, signed attestations)
```

## Implementation Checklist

1. **Differential SBOM Audit:** Diff resolver-generated SBOMs against binary artifact SBOMs.
2. **CPE Syntax Validation:** Trace scanner findings back to exact vendor/product CPE parameters.
3. **Lifecycle Horizon Audit:** Map application frameworks against published EOL dates.
4. **Practice Metrics Assessment:** Run OpenSSF Scorecard against primary dependencies.
5. **Lockfile Hash Verification:** Validate package lockfiles against upstream registry digests.

---

# Reference Labs and Investigations

- [S02: Payara + mvnpm](./scenarios/S02-payara-mvnpm/TRACE.md)
- [T01: Snyk Cross-Scenario Matrix](./investigations/T01-snyk-beyond-sbom/TRACE.md)
- [T02: Docker Scout](./investigations/T02-docker-scout/TRACE.md)
- [T03: Trivy](./investigations/T03-trivy-s01/TRACE.md)
- [T04: Grype](./investigations/T04-grype-s02/TRACE.md)
- [T05: pip-audit](./investigations/T05-pip-audit-s03/TRACE.md)
- [T06: OWASP Dependency-Check](./investigations/T06-owasp-dependency-check-s04/TRACE.md)
- [T07: npm audit](./investigations/T07-npm-audit-s05/TRACE.md)
- [T08: GuardDog](./investigations/T08-guarddog/TRACE.md)
- [Tooling Reference](./reference/tools.md)
