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

The workshop is the manual: seven chapters under [`workshop/`](./workshop),
each opening with its commands and followed by the labs it uses. Build it with
`mvn package`, or read the markdown directly.

[`WORKSHOP.md`](./WORKSHOP.md) is the one-page route card — running order,
every command in sequence, and where each chapter lives.

```text
Act 1  You can't see what you ship            Parts 1-2
Act 2  The scanner can't either               Parts 3-4
Act 3  Someone is counting on that            Part 5
Act 4  The minimum that keeps you honest      Part 6
```

## Environment Setup

Requirements: JDK 21+, Maven 3.9+, Node.js 20+, Python 3.11+, and Docker. See [`setup/`](./setup) for complete configuration instructions.

### 1. Preconfigured Container Environment

Pulls the published image `noregressions/ydnwys-workshop:0.0.1` on first run:

```bash
./container/run.sh
```

To build the image locally instead, see [`container/build.sh`](./container/build.sh).

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
| [`Extended SBOM`](./scenarios/S08-extended-sbom) | **S08** | CycloneDX vs SBOM+ over one POM: what shipped against what built it. |

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
| [`CVE-2020-1938 Ghostcat`](./investigations/T10-cve-tomcat-85) (**T10**) | — | One CVE record read end to end across four public APIs, over the six years it kept changing. |
| [`Three scanners`](./investigations/T09-three-scanners-s01) (**T09**) | S01 | Grype, Trivy and OSV-Scanner across the same seven boundaries: identity gaps vs database gaps. |

## Script Interface Conventions

| Script | Function |
|---|---|
| `./scripts/build.sh` | Compiles targets and packages artifacts |
| `./scripts/run.sh` | Starts background service runtime |
| `./scripts/stop.sh` | Stops running background service |
| `./scripts/clean.sh` | Cleans target directories and generated artifacts |
| `./scripts/proof-check.sh` | Validates structural assertion rules against current output |
| `./scripts/ship-check.sh` | The Part 6 drill: declared vs shipped inventory, the gap, lifecycle, provenance |

### Configured Service Ports

```text
S02: 8080    S04: 8082
S03: 8081    S05: 8083
```

## Repository Structure

```text
FACILITATOR.md    Instruction timings, expected outputs, and troubleshooting
setup/            Prerequisites, authentication configuration, and pre-warm guides
workshop/         The seven chapters that are the workshop, plus
                  cve-propagation/ — the research note behind Parts 3 and 4 —
                  and appendix-ai-dependencies.md, parked off the route
cheatsheet/       The route-ordered cheat sheet: every command, in run order,
                  with the output it should produce
scenarios/        Scenario definitions and LESSON.md walkthroughs (S01-S05, S07, S08)
investigations/   Tool evaluations and LESSON.md reports (T01-T08)
reference/        Tooling taxonomy appendix
scripts/          Environment validation and build orchestration scripts
pom.xml           Book configuration: the manual and cheat-sheet editions
```

## Document Generation

```bash
mvn package
# -> target/book.pdf              the manual: the whole route plus appendices
# -> target/site/                 the same manual as a static site, with the
#                                 reference investigations the PDF leaves out
# -> target/cheatsheets.pdf       the cheat sheet alone: every command of the
#                                 route in route order, with expected output
# -> target/cheatsheets-site/     the cheat sheet as a static site
```

The cheat-sheet edition is the one to print and keep beside the keyboard: it
follows the route stop by stop — S01, S04, S08, S05, S03, S02, T01, then
Ghostcat and T09, and so on — rather than cataloguing the labs by identifier.
The manual is what explains why each command is there.

## Setup and Configuration Reference

- [`setup/00 about.md`](./setup/00%20about.md) — Workshop architecture and evaluation methodology.
- [`setup/02 tools.md`](./setup/02%20tools.md) — Tool specifications and version minimums.
- [`setup/03 ACCOUNTS-AND-KEYS.md`](./setup/03%20ACCOUNTS-AND-KEYS.md) — Snyk authentication and NVD API key configuration.
- [`setup/04 PREPULL-PREWARM.md`](./setup/04%20PREPULL-PREWARM.md) — Pre-warm procedures and cache initialization.
- [`setup/INSTALL.md`](./setup/INSTALL.md) — OS-specific installation transcripts.
- [`setup/VERSIONS.md`](./setup/VERSIONS.md) — Baseline verified versions and dependency pins.

## License

Apache License 2.0. See [`LICENSE`](./LICENSE).
