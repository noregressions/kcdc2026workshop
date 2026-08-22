# Software Supply Chain Trace Lab

A deliberately small, mixed-ecosystem application for tracing software through declaration, resolution, transformation, packaging, SBOM generation, and an OCI image.

The lab keeps three tracer components alive throughout the investigation:

- `jackson-databind`: a normal Maven dependency whose version is supplied by Spring Boot dependency management.
- `lodash`: an npm dependency that Vite bundles into static JavaScript before the files enter the Spring Boot JAR.
- `commons-codec`: a Maven dependency that the Shade Plugin relocates from `org.apache.commons.codec` to `com.acme.internal.codec` inside the `normalizer` module.

The point is not to find three components three times. It is to see which claims can still be proved after each transformation.

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

The first build uses `npm install` because this generated lab does not ship a pre-fabricated npm lockfile. That creates `frontend/package-lock.json`; from that point use it as normal evidence and, for a real repository, commit it.

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

Then open <http://localhost:8080/>.

## Follow the trace

`TRACE.md` is the annotated end-to-end investigation. The helper scripts perform the repetitive parts but the individual commands are left visible so the evidence is inspectable.

A useful first pass after the build is:

```bash
./scripts/trace.sh
```

It writes retained evidence into `trace-output/`.

The controlled metadata experiment is:

```bash
./scripts/strip-codec-metadata.sh
```

After generating the Maven/CycloneDX BOMs, compare the tracer components in the normalizer and service models with:

```bash
./scripts/compare-sboms.sh
```

The script copies the shaded `normalizer` JAR and removes only the original commons-codec Maven metadata. It does not remove the relocated codec bytecode. Scanning the before/after pair exposes how downstream identification depends on evidence that survives packaging.

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
