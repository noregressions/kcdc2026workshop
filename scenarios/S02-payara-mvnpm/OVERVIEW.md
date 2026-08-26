---
id: s02-payara-mvnpm-overview
oneliner: "Four kinds of software into one WAR and one Payara container: prerequisites and how to run it."
track: optional
---

# S02 — Payara + mvnpm Supply Chain Trace Lab: Overview

> **Workshop track: OPTIONAL**, not part of the timed route. Visit this lab if you use Jakarta EE: it shows the same identification problems crossing into a WAR and an application server.

A deliberately small mixed-stack application for tracing software through a different set of supply-chain boundaries:

- a Jakarta EE 11 Web Profile application packaged as a WAR;
- Payara Server Web Profile as the runtime, supplied by the container image;
- `commons-lang3` as an ordinary Java application dependency packaged in `WEB-INF/lib`;
- `lodash-es` as npm-origin JavaScript obtained through mvnpm as a Maven **plugin dependency**;
- `esbuild-maven-plugin` transforms that mvnpm package into browser code in `assets/app.js`;
- a final Payara container contains both the application WAR and the much larger server/JDK/OS software universe.

## Why mvnpm is interesting here

mvnpm makes npm packages available as Maven artifacts. In this project `org.mvnpm:lodash-es:4.17.21` is attached to the esbuild Maven plugin, so it is build-time software rather than a conventional application dependency. Maven resolves the package, esbuild uses it to build the browser bundle, and then its original package boundary is absent from the WAR.

That gives the trace a useful distinction:

```text
Maven project dependency       -> commons-lang3 -> WEB-INF/lib/*.jar
Maven plugin dependency (mvnpm)-> lodash-es     -> esbuild -> assets/app.js
Provided runtime API           -> Jakarta EE    -> supplied by Payara
Container base                 -> Payara/JDK/OS  -> final image only
```

## Build

Requirements:

- JDK 21+
- Maven
- Docker for the container stage
- Syft and jq for the optional SBOM/image trace

```bash
./scripts/build.sh
```

The WAR is:

```text
target/payara-mvnpm-trace-lab-1.0.0.war
```

## Run on Payara

```bash
./scripts/run.sh
```

Then open:

```text
http://localhost:8080/trace/
```

Stop it with:

```bash
./scripts/stop.sh
```

## Trace helpers

```bash
./scripts/trace-mvnpm.sh
./scripts/image-trace.sh
```

`trace-mvnpm.sh` replays the core evidence sequence in one pass: `commons-lang3` in the project dependency tree, `lodash-es` absent from it, `lodash-es` present in the plugin execution realm, the generated browser assets, the lodash sources named in the source map, and the relevant WAR entries.

`image-trace.sh` builds the project image, prints its identity, and writes a Syft CycloneDX image SBOM to `trace-output/image.cdx.json`.

See `TRACE.md` for the intended evidence path.

## Start clean

```bash
./scripts/clean.sh
```

Removes `target/` and `trace-output/`. Source configuration is untouched. `TRACE.md` step 1 does the same thing with `rm -rf trace-output && mvn clean`, shown explicitly there so the two Maven domains stay visible.

## Verify the lab still holds

```bash
./scripts/proof-check.sh
```

`proof-check.sh` re-runs the lab and asserts that it still produces the outcomes `TRACE.md` describes. Use it after changing dependencies or tooling versions to find out whether the walkthrough text needs updating.

It takes `--skip-build`, `--skip-runtime`, `--skip-image` and `--quick` (equivalent to `--skip-runtime --skip-image`) when you only need part of the check. Run `./scripts/proof-check.sh --help` for the full list.
