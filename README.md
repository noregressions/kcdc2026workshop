# Software Supply Chain Trace Lab

Empirical benchmarks and analysis of software component identifiability, build transformations, and vulnerability scanner visibility across supply chain boundaries.

## Core Technical Architecture

Component tracking across the software lifecycle encounters multiple representation transformations:

```text
source configuration
        |
resolver model
        |
build transformation
        |
application artifact
        |
SBOM producer
        |
container image
```

Technical finding: **Software presence does not equal software identifiability.** Build-time transformations (bytecode relocation, shading, frontend bundling, and build-time code generation) frequently preserve runtime logic while stripping the package metadata required by static scanners.

## Workshop Execution Guide

The timed execution route is documented in [`WORKSHOP.md`](./WORKSHOP.md).

## Environment Setup

Requirements: JDK 21+, Maven 3.9+, Node.js 20+, Python 3.11+, and Docker. See [`setup/`](./setup) for complete configuration instructions.

### 1. Preconfigured Container Environment

```bash
./container/build.sh
./container/run.sh
```

### 2. Host Prerequisites Verification

```bash
./scripts/tools-check.sh
```

### 3. Pre-Warm Caches and Build Targets

```bash
./scripts/build-all.sh
```

Append `--with-investigations` to execute baseline scans across T01–T08.

## Scenarios Reference

| Lab | Identifier | Tracked Transformations |
|---|---|---|
| [`Spring + Node`](./scenarios/S01-spring-node) | **S01** | Standard dependency resolution, shaded bytecode relocation, and bundled frontend JavaScript. |
| [`Payara + mvnpm`](./scenarios/S02-payara-mvnpm) | **S02** | WAR packaging, mvnpm client dependencies, and Maven plugin execution realms. |
| [`Python PEP 517`](./scenarios/S03-python-pep517) | **S03** | Source distribution build backends generating runtime modules during `pip install`. |
| [`Maven plugin hidden content`](./scenarios/S04-maven-plugin-hidden-content) | **S04** | Runtime code generation via Maven plugin execution where the application dependency graph is empty. |
| [`Node npm prepack`](./scenarios/S05-node-prepack) | **S05** | Dynamic artifact generation during npm `prepack` lifecycle hook execution. |
| [`Reverse provenance`](./scenarios/S07-provenance-s01) | **S07** | Layered provenance verification (Git commit properties, OCI labels, CycloneDX SBOM, Cosign attestations). |

## Investigations Reference

| Tool Evaluation | Target Scenario | Focus Area |
|---|---|---|
| [`Snyk`](./investigations/T01-snyk-beyond-sbom) (**T01**) | S01–S05 | Commercial SCA analysis across shaded, bundled, and plugin-generated artifacts. |
| [`Docker Scout`](./investigations/T02-docker-scout) (**T02**) | S01, S02 | Final container image layer analysis vs upstream build provenance. |
| [`Trivy`](./investigations/T03-trivy-s01) (**T03**) | S01 | Finding divergence across manifests, JARs, bundles, and container images. |
| [`Grype`](./investigations/T04-grype-s02) (**T04**) | S02 | Static cataloging and CVE matching against WAR and container targets. |
| [`pip-audit`](./investigations/T05-pip-audit-s03) (**T05**) | S03 | Evaluation of installed virtual environments against PEP 517 build execution. |
| [`OWASP Dependency-Check`](./investigations/T06-owasp-dependency-check-s04) (**T06**) | S04 | CPE matching against plugin-generated application bytecode. |
| [`npm audit`](./investigations/T07-npm-audit-s05) (**T07**) | S05 | Manifest dependency evaluation vs physical package contents. |
| [`GuardDog`](./investigations/T08-guarddog) (**T08**) | S05, S03 | Static AST code scanning of package archives vs metadata analysis. |

## Script Interface Conventions

| Script | Function |
|---|---|
| `./scripts/build.sh` | Compiles targets and packages artifacts |
| `./scripts/run.sh` | Starts background service runtime |
| `./scripts/stop.sh` | Stops running background service |
| `./scripts/clean.sh` | Cleans target directories and generated artifacts |
| `./scripts/proof-check.sh` | Validates structural assertion rules against current output |

### Configured Service Ports

```text
S02: 8080    S04: 8082
S03: 8081    S05: 8083
```

## Repository Structure

```text
FACILITATOR.md    Instruction timings, expected outputs, and troubleshooting
setup/            Prerequisites, authentication configuration, and pre-warm guides
scenarios/        Scenario definitions and TRACE.md walkthroughs (S01-S05, S07)
investigations/   Tool evaluations and TRACE.md reports (T01-T08)
scripts/          Environment validation and build orchestration scripts
pom.xml           Build configuration for aggregated manual PDF compilation
```

## PDF Document Generation

```bash
mvn package
# -> target/book.pdf
```
## Setup and Configuration Reference

- [`setup/00 about.md`](./setup/00%20about.md) — Workshop architecture and evaluation methodology.
- [`setup/02 tools.md`](./setup/02%20tools.md) — Tool specifications and version minimums.
- [`setup/03 ACCOUNTS-AND-KEYS.md`](./setup/03%20ACCOUNTS-AND-KEYS.md) — Snyk authentication and NVD API key configuration.
- [`setup/04 PREPULL-PREWARM.md`](./setup/04%20PREPULL-PREWARM.md) — Pre-warm procedures and cache initialization.
- [`setup/INSTALL.md`](./setup/INSTALL.md) — OS-specific installation transcripts.
- [`setup/VERSIONS.md`](./setup/VERSIONS.md) — Baseline verified versions and dependency pins.

## License

Apache License 2.0. See [`LICENSE`](./LICENSE).
