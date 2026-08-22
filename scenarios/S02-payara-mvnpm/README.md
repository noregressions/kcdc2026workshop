# Payara + mvnpm Supply Chain Trace Lab

A deliberately small mixed-stack application for tracing software through a different set of supply-chain boundaries:

- a Jakarta EE 11 Web Profile application packaged as a WAR;
- Payara Server Web Profile as the runtime, supplied by the container image;
- `commons-lang3` as an ordinary Java application dependency packaged in `WEB-INF/lib`;
- `lodash-es` as npm-origin JavaScript obtained through mvnpm as a Maven **plugin dependency**;
- `esbuild-maven-plugin` transforms that mvnpm package into browser code in `assets/app.js`;
- a final Payara container contains both the application WAR and the much larger server/JDK/OS software universe.

## Why mvnpm is interesting here

mvnpm makes npm packages available as Maven artifacts. In this project `org.mvnpm:lodash-es:4.17.21` is attached to the esbuild Maven plugin, so it is build-time software rather than a conventional application dependency. The package is resolved by Maven, used to build the browser bundle, and then its original package boundary is absent from the WAR.

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

See `TRACE.md` for the intended evidence path.
