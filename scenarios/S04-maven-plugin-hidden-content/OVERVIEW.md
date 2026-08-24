---
id: s04-maven-plugin-hidden-content-overview
oneliner: "An application with an empty dependency tree whose JAR still gained a route: prerequisites and how to run it."
---

# S04 — Maven Plugin Hidden-Content Supply Chain Trace Lab: Overview

This scenario shows build-time software introducing runtime capability into a Java application.

The application has no third-party runtime dependencies. Its source creates a small HTTP server and loads optional `TraceRoute` implementations through Java's `ServiceLoader`.

The interesting route is not present in the application source.

Instead:

```text
application pom.xml
        |
        | Maven build plugin
        v
trace-injector-maven-plugin
        |
        | transitive plugin dependency
        v
trace-route-payload
        |
        | route definition
        v
plugin execution during generate-sources
        |
        +--> generates Java source
        |
        +--> generates META-INF/services provider metadata
        |
        +--> generates provenance metadata
        v
normal Maven compiler/resources lifecycle
        v
application JAR
        v
ServiceLoader discovers generated route
        v
GET /hidden/build-info
```

The key supply-chain distinction is:

```text
project dependency graph
        !=
Maven plugin execution realm
        !=
runtime bytes in the final JAR
```

## Requirements

- JDK 21+
- Maven 3.9+
- curl
- unzip
- jq optional
- Syft optional

The first build needs normal Maven Central access for Maven's own plugin/API dependencies.

## Build

```bash
./scripts/build.sh
```

The script first builds the workshop's local Maven plugin fixtures into a scenario-local Maven repository, then builds the application using that repository.

Application JAR:

```text
target/maven-plugin-hidden-content-1.0.0.jar
```

## Run

```bash
./scripts/run.sh
```

The application defaults to port `8082`.

Normal endpoint:

```bash
curl -sS http://localhost:8082/health | jq
```

Unexpected build-supplied endpoint:

```bash
curl -sS http://localhost:8082/hidden/build-info | jq
```

Stop:

```bash
./scripts/stop.sh
```

Return the scenario to a clean pre-build state:

```bash
./scripts/clean.sh
```

See `TRACE.md` for the evidence walkthrough.

## Trace helper

```bash
./scripts/trace-plugin.sh
```

`trace-plugin.sh` replays the core evidence sequence in one pass: the (empty) application dependency tree, the plugin declaration in `pom.xml`, the payload declaration in the plugin's own POM, the route definition carried by the payload, the generated application source and resources, and the relevant entries in the final JAR.

It needs the build output, so run `./scripts/build.sh` first.

## Proof check

After the walkthrough, verify the demonstrated invariants automatically:

```bash
./scripts/proof-check.sh
```

The proof uses an isolated runtime port (`18084` by default) and fails non-zero if a required claim no longer holds. Syft and `jq` checks are performed when those tools are installed.
