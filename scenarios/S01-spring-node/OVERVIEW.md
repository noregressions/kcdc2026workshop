---
id: s01-spring-node-overview
oneliner: "Three tracer components through Maven, Vite and Shade: prerequisites, build sequence and the scripts that drive it."
track: core
---

# S01 — Software Supply Chain Trace Lab: Overview

> **Workshop track: CORE** — part of the timed workshop route (Part 2: identification).

A deliberately small, mixed-ecosystem application for tracing software through declaration, resolution, transformation, packaging, SBOM generation, and an OCI image.

The lab keeps three tracer components alive throughout the investigation:

- `jackson-databind`: a normal Maven dependency whose version is supplied by Spring Boot dependency management.
- `lodash`: an npm dependency that Vite bundles into static JavaScript before the files enter the Spring Boot JAR.
- `commons-codec`: a Maven dependency that the Shade Plugin relocates from `org.apache.commons.codec` to `com.acme.internal.codec` inside the `normalizer` module.

The point is to see which claims can still be proved after each transformation, rather than to find three components three times.

## The workshop exercise (15 minutes)

The canonical exercise lives in [`WORKSHOP.md`](../../WORKSHOP.md) Part 2,
Step 1. Three legs, one conclusion:

```text
control          jackson-databind agrees in resolver and artefact scan
shading          commons-codec identified — until only its metadata is removed
bundling         lodash's fingerprints are in the bundle; no package identified
```

Everything below and in [`TRACE.md`](./TRACE.md) is the full investigation
behind those fifteen minutes.

### Explore later

The TRACE steps the exercise deliberately skips:

- steps 4–6 — how each of the three components was resolved
- steps 17–18 — why *two versions* of commons-codec legitimately coexist in
  the shipped JAR
- steps 19–22 — the Maven-model vs artefact-derived SBOM comparison
- step 23 — crossing the container-image boundary

## Prerequisites

For the basic build:

- JDK 21
- Maven 3.9+
- Node.js 20+ / npm

For the full trace:

- `jq`
- `syft`
- `zip`
- Docker

## Build

```bash
./scripts/clean.sh
./scripts/build.sh
```

The first build uses `npm install` because the lab does not ship an npm lockfile. That creates `frontend/package-lock.json`; later runs use it as normal evidence (a real repository would commit it).

The build sequence intentionally matches the scenario:

```text
npm dependency resolution
        ↓
Vite frontend bundle
        ↓
Maven reactor
        ├── normalizer → shade/relocate commons-codec
        └── service    → copy frontend/dist → Spring Boot executable JAR
```

Run the application:

```bash
java -jar service/target/service-1.0.0.jar
curl 'http://localhost:8080/api/trace?value=Hello%20Supply%20Chain'
```

Then open <http://localhost:8080/>. Ctrl-C stops the service when you are done.

## Follow the trace

`TRACE.md` is the annotated end-to-end investigation. The helper scripts perform the repetitive parts but the individual commands remain visible so the evidence is inspectable.

A useful first pass after the build is:

```bash
./scripts/trace.sh
```

It replays the walkthrough's evidence commands — the source-declaration greps, both dependency trees, the plugin resolutions, and the archive listings — in one pass, and writes retained evidence into `trace-output/`. It introduces nothing the step-by-step trace does not show.

The controlled metadata experiment is:

```bash
./scripts/strip-codec-metadata.sh
```

The script copies the shaded `normalizer` JAR and removes only the original commons-codec Maven metadata — not the relocated codec bytecode. Scanning the before/after pair exposes how downstream identification depends on evidence that survives packaging.

After generating the Maven/CycloneDX BOMs, compare the tracer components in the normalizer and service models with:

```bash
./scripts/compare-sboms.sh
```

## Container image

Build and scan the image:

```bash
./scripts/image-trace.sh
```

The main lab ends at the container-image boundary. The `k8s/` directory is retained only as optional example material and is not part of the walkthrough in `TRACE.md`.

## Repository shape

```text
.
├── frontend/      React + lodash + Vite
├── normalizer/    commons-codec + Maven Shade relocation
├── service/       Spring Boot executable application
├── k8s/           optional example deployment files (not used in the main lab)
├── scripts/       evidence collection and controlled experiment
├── Dockerfile
├── TRACE.md
└── pom.xml
```

### Compare service SBOM viewpoints

After generating both the Maven/CycloneDX service BOM and the Syft CycloneDX BOM for the finished service JAR, compare the tracer components with:

```bash
./scripts/compare-service-sboms.sh
```

This highlights differences between the Maven dependency-model SBOM and the finished-artifact SBOM.

## Verify the lab still holds

```bash
./scripts/proof-check.sh
```

`proof-check.sh` re-runs the lab and asserts that it still produces the outcomes `TRACE.md` describes: the embedded `commons-codec` at `1.17.1`, the service's `1.18.0`, `jackson-databind` at `2.19.4`, `lodash` at `4.17.21`, and the normalizer at `1.0.0`. Use it after changing dependencies or tooling versions to find out whether the walkthrough text needs updating.

It takes `--skip-build`, `--skip-runtime`, `--skip-image` and `--quick` (the last being equivalent to `--skip-runtime --skip-image`) when you only need part of the check. Run `./scripts/proof-check.sh --help` for the full list.

## Optional: runtime image identity

```bash
./scripts/runtime-trace.sh
```

`runtime-trace.sh` requires `kubectl` and a cluster with the `checkout-service` deployment from `k8s/` applied. It prints the image reference requested by the deployment spec alongside the image and resolved `imageID` actually running in each pod: the difference between what was asked for and what is running. In essence:

```bash
kubectl get deployment checkout-service \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get pods -l app=checkout-service \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].imageID}{"\n"}{end}'
```

Like `k8s/`, this is optional example material and is not part of the walkthrough in `TRACE.md`.
