# Maven Plugin Hidden-Content Supply Chain Trace Lab

This lab follows runtime capability that enters a Java application through **Maven plugin execution**, rather than through the application's normal dependency graph.

The tracers are:

- `trace-injector-maven-plugin` — executable build-time software attached to the Maven lifecycle.
- `trace-route-payload` — a transitive dependency of that plugin.
- `/hidden/build-info` — a route definition carried by the plugin dependency.
- `GeneratedTraceRoute` — Java source generated during the build.
- `META-INF/services/...TraceRoute` — generated ServiceLoader metadata that activates the class at runtime.

The pattern is:

**Look → Run → Observe → Establish**

## What Maven plugins mean in this lab

Maven has more than one dependency domain.

`mvn dependency:tree` describes the application's **project dependencies**. Maven plugins are different: they are executable build-time software. Maven resolves a plugin and its own dependencies, creates a **plugin classloader realm**, and invokes the plugin goal during the build lifecycle.

So these are different evidence views:

```text
application dependency graph
        !=
plugin dependency graph
        !=
plugin execution realm
```

A plugin can then transform the application by generating source, resources, metadata or other content. Once that content has been compiled and packaged, the final JAR may contain the resulting behaviour without retaining an obvious package boundary for the build-time software that introduced it.

The important trace boundary is therefore:

```text
plugin execution realm
        ↓
build transformation
        ↓
application bytes
        ↓
runtime behaviour
```

In this lab, the application POM declares `trace-injector-maven-plugin`, but does **not** declare `trace-route-payload` as an application dependency. The payload is a transitive dependency of the plugin. During `generate-sources`, the plugin reads that payload and creates Java code plus ServiceLoader metadata. Maven then compiles and packages those generated files as ordinary application content.

---

# 1. Start clean

## Why we need to do this

Separate source-controlled content from previous generated build output.

## Run

```bash
./scripts/clean.sh
```

## Observed output

The cleanup script completed successfully during the walkthrough.

## Establish

The application can be rebuilt from the checked-in scenario sources and local Maven fixture repository.

---

# 2. Look at the application dependency graph

## Why we need to do this

Start with the Maven view most developers use when asking "what does this application depend on?"

## Run

```bash
mvn \
  -Dmaven.repo.local="$PWD/.maven-repo" \
  dependency:tree
```

## Observed output

```text
[INFO] --------< dev.noregressions.trace:maven-plugin-hidden-content >---------
[INFO] Building Maven Plugin Hidden Content Trace Lab 1.0.0
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------

[INFO] --- dependency:3.7.0:tree (default-cli) @ maven-plugin-hidden-content ---
[INFO] dev.noregressions.trace:maven-plugin-hidden-content:jar:1.0.0

[INFO] BUILD SUCCESS
```

## Establish

The application's normal Maven dependency graph is empty:

```text
maven-plugin-hidden-content:1.0.0
```

Neither `trace-injector-maven-plugin` nor `trace-route-payload` appears as an application dependency.

---

# 3. Ask Maven about plugin dependencies instead

## Why we need to do this

The project dependency graph is not Maven's only dependency domain.

## Run

```bash
mvn \
  -Dmaven.repo.local="$PWD/.maven-repo" \
  dependency:resolve-plugins \
  -DincludeArtifactIds=trace-injector-maven-plugin
```

## Observed output

```text
[INFO] The following plugins have been resolved:

[INFO]    dev.noregressions.trace:trace-injector-maven-plugin:maven-plugin:1.0.0:runtime
[INFO]       dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
[INFO]       dev.noregressions.trace:trace-route-payload:jar:1.0.0

[INFO] BUILD SUCCESS
```

## Establish

When we ask Maven about the **plugin** dependency domain, a second graph appears:

```text
trace-injector-maven-plugin:1.0.0
        ↓
trace-route-payload:1.0.0
```

Maven knows about the payload, but not as an application dependency.

---

# 4. Inspect the actual plugin execution realm

## Why we need to do this

Resolver output tells us what Maven can resolve. Debug output tells us what Maven actually loads to execute the plugin.

## Run

```bash
mvn \
  -Dmaven.repo.local="$PWD/.maven-repo" \
  -X generate-sources 2>&1 \
  | grep -E 'trace-injector|trace-route-payload'
```

## Observed output

```text
[DEBUG] Goal:          dev.noregressions.trace:trace-injector-maven-plugin:1.0.0:inject-route (inject-build-route)
[INFO] --- trace-injector:1.0.0:inject-route (inject-build-route) @ maven-plugin-hidden-content ---
[DEBUG] dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
[DEBUG]    dev.noregressions.trace:trace-route-payload:jar:1.0.0:compile
[DEBUG] Created new class realm plugin>dev.noregressions.trace:trace-injector-maven-plugin:1.0.0
[DEBUG] Populating class realm plugin>dev.noregressions.trace:trace-injector-maven-plugin:1.0.0
[DEBUG]   Included: dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
[DEBUG]   Included: dev.noregressions.trace:trace-route-payload:jar:1.0.0
[DEBUG] Loading mojo dev.noregressions.trace:trace-injector-maven-plugin:1.0.0:inject-route from plugin realm ClassRealm[plugin>dev.noregressions.trace:trace-injector-maven-plugin:1.0.0, ...]
```

## Establish

`trace-route-payload` is not merely resolvable. It is actually present in the Maven **plugin ClassRealm** used to execute `inject-route`.

```text
application dependency graph
        no payload

plugin execution realm
        plugin + payload
```

---

# 5. Inspect the generated Java source

## Why we need to do this

Now follow the build-time input across the transformation boundary into application source.

## Run

```bash
find target/generated-sources -type f -print
```

## Observed output

```text
target/generated-sources/trace-injector/dev/noregressions/trace/s04/generated/GeneratedTraceRoute.java
```

Then:

```bash
sed -n '1,220p' \
  target/generated-sources/trace-injector/dev/noregressions/trace/s04/generated/GeneratedTraceRoute.java
```

## Observed output

```java
package dev.noregressions.trace.s04.generated;

import dev.noregressions.trace.s04.TraceRoute;

public final class GeneratedTraceRoute implements TraceRoute {

    @Override
    public String path() {
        return "/hidden/build-info";
    }

    @Override
    public String responseJson() {
        return "{\n  \"message\": \"This runtime endpoint came from a transitive Maven plugin dependency.\",\n  \"origin\": \"trace-route-payload\",\n  \"introducedBy\": \"trace-injector-maven-plugin\",\n  \"route\": \"/hidden/build-info\"\n}\n";
    }
}
```

## Establish

The runtime route now exists as Java application source even though it did not originate in the application's checked-in Java source.

Its provenance is explicit:

```text
origin       = trace-route-payload
introducedBy = trace-injector-maven-plugin
route        = /hidden/build-info
```

---

# 6. Inspect the generated activation metadata

## Why we need to do this

Generating a class does not make it execute. We need to see how the build connects it to the application.

## Run

```bash
find target/generated-resources -type f -print
```

## Observed output

```text
target/generated-resources/trace-injector/META-INF/trace-lab/plugin-injection.properties
target/generated-resources/trace-injector/META-INF/services/dev.noregressions.trace.s04.TraceRoute
```

Inspect the ServiceLoader registration:

```bash
cat \
  target/generated-resources/trace-injector/META-INF/services/dev.noregressions.trace.s04.TraceRoute
```

## Observed output

```text
dev.noregressions.trace.s04.generated.GeneratedTraceRoute
```

Inspect the provenance marker:

```bash
cat \
  target/generated-resources/trace-injector/META-INF/trace-lab/plugin-injection.properties
```

## Observed output

```text
plugin=trace-injector-maven-plugin
payload=trace-route-payload
route=/hidden/build-info
```

## Establish

The build generated both:

```text
GeneratedTraceRoute.class
        +
META-INF/services/...TraceRoute
```

The ServiceLoader descriptor makes the generated implementation discoverable by the source-defined application at runtime.

---

# 7. Prove the generated content entered the final JAR

## Why we need to do this

Generated build directories are intermediate evidence. The deployable JAR is the shipped artefact.

## Run

```bash
unzip -l target/maven-plugin-hidden-content-1.0.0.jar \
  | grep -E 'GeneratedTraceRoute|META-INF/services|plugin-injection'
```

## Observed output

```text
        0  08-22-2026 11:58   META-INF/services/
       88  08-22-2026 11:58   META-INF/trace-lab/plugin-injection.properties
       58  08-22-2026 11:58   META-INF/services/dev.noregressions.trace.s04.TraceRoute
      803  08-22-2026 11:58   dev/noregressions/trace/s04/generated/GeneratedTraceRoute.class
```

## Establish

The generated implementation, activation metadata and provenance marker are all bytes in the final application JAR.

---

# 8. Inspect the shipped bytecode

## Why we need to do this

Generated Java source may be deleted after the build. The final JAR still has to carry the behaviour.

## Run

```bash
javap \
  -classpath target/maven-plugin-hidden-content-1.0.0.jar \
  -c -p \
  dev.noregressions.trace.s04.generated.GeneratedTraceRoute
```

## Observed output

```text
Compiled from "GeneratedTraceRoute.java"

public final class dev.noregressions.trace.s04.generated.GeneratedTraceRoute implements dev.noregressions.trace.s04.TraceRoute {

  public java.lang.String path();
    Code:
       0: ldc           #7                  // String /hidden/build-info
       2: areturn

  public java.lang.String responseJson();
    Code:
       0: ldc           #9                  // String {\n  \"message\": \"This runtime endpoint came from a transitive Maven plugin dependency.\",\n  \"origin\": \"trace-route-payload\",\n  \"introducedBy\": \"trace-injector-maven-plugin\",\n  \"route\": \"/hidden/build-info\"\n}\n
       2: areturn
}
```

## Establish

The final application bytecode contains:

```text
/hidden/build-info
trace-route-payload
trace-injector-maven-plugin
```

The runtime behaviour survived the transformation even though the build-time package boundary did not.

---

# 9. Scan the final JAR with Syft

## Why we need to do this

Now compare physical runtime capability with a package scanner's inventory.

## Run

```bash
syft target/maven-plugin-hidden-content-1.0.0.jar
```

## Observed output

```text
✔ Indexed file system   target/maven-plugin-hidden-content-1.0.0.jar
✔ Cataloged contents

   ├── ✔ Packages      [1 packages]
   ├── ✔ File digests  [1 files]
   ├── ✔ Executables   [0 executables]

NAME                         VERSION  TYPE
maven-plugin-hidden-content  1.0.0    java-archive
```

## Establish

Syft sees the application archive, but does not identify either of the build-time components responsible for the generated behaviour:

```text
trace-injector-maven-plugin   not identified
trace-route-payload           not identified
```

The bytes are present. Their build provenance is not recovered as package identity.

---

# 10. Generate a Maven-model CycloneDX SBOM

## Why we need to do this

Compare the scanner view with an SBOM generated from Maven's project dependency model.

## Run

```bash
mvn \
  -Dmaven.repo.local="$PWD/.maven-repo" \
  org.cyclonedx:cyclonedx-maven-plugin:2.9.3:makeBom \
  -DoutputFormat=json
```

## Observed output

```text
[INFO] CycloneDX: Resolving Dependencies
[INFO] CycloneDX: Creating BOM version 1.6 with 0 component(s)
[INFO] CycloneDX: Writing and validating BOM (JSON): .../target/bom.json
[INFO] BUILD SUCCESS
```

Focused check:

```bash
jq -r '.components[]? | [.name, .version] | @tsv' target/bom.json \
  | grep -E 'trace-injector|trace-route-payload|maven-plugin-hidden-content' || true
```

## Observed output

```text
```

No matching output.

## Establish

The Maven-model CycloneDX SBOM contains **zero dependency components**. It does not identify the build plugin or its transitive payload.

At this point the evidence views are:

```text
Maven dependency tree     → no plugin or payload
CycloneDX Maven SBOM      → no plugin or payload
Maven plugin resolution   → plugin + payload
Maven execution realm     → plugin + payload
final JAR                 → generated runtime behaviour present
Syft JAR scan             → application archive only
```

---

# 11. Run the application

## Why we need to do this

The final test is whether the generated, packaged bytes actually change runtime capability.

## Run

```bash
./scripts/run.sh
```

## Observed output

```text
Runtime started as PID 69945
Open:   http://localhost:8082/
Health: http://localhost:8082/health
```

## Establish

The application starts successfully from the final JAR on port `8082`.

---

# 12. Verify the source-defined application endpoint

## Why we need to do this

This is the control endpoint: behaviour deliberately present in the checked-in application source.

## Run

```bash
curl -sS http://localhost:8082/health | jq
```

## Observed output

```json
{
  "application": "maven-plugin-hidden-content",
  "status": "UP"
}
```

## Establish

The source-defined application is running normally.

---

# 13. Request the build-supplied endpoint

## Why we need to do this

This closes the chain from plugin dependency to runtime behaviour.

## Run

```bash
curl -sS http://localhost:8082/hidden/build-info | jq
```

## Observed output

```json
{
  "message": "This runtime endpoint came from a transitive Maven plugin dependency.",
  "origin": "trace-route-payload",
  "introducedBy": "trace-injector-maven-plugin",
  "route": "/hidden/build-info"
}
```

## Establish

The endpoint exists at runtime and explicitly ties itself back to:

```text
trace-route-payload
        ↓
trace-injector-maven-plugin
        ↓
generated Java + ServiceLoader metadata
        ↓
application JAR
        ↓
/hidden/build-info
```

---

# What this lab establishes

1. **Maven has multiple dependency domains.** An empty application dependency tree does not mean no third-party software participates in producing the application.

2. **Maven plugins are executable supply-chain inputs.** The plugin and its transitive dependencies are loaded into a separate plugin ClassRealm and execute during the build.

3. **A transitive plugin dependency can influence shipped behaviour without becoming an application dependency.** `trace-route-payload` supplied data used to create runtime code, but never appeared in `mvn dependency:tree`.

4. **Build transformations can destroy obvious package identity.** The plugin and payload become generated Java bytecode and ServiceLoader metadata in the application JAR.

5. **Presence and provenance are different questions.** `javap` proves the behaviour is physically present. Syft identifies the application archive but does not recover the plugin or payload that caused those bytes to exist.

6. **A normal dependency-derived SBOM can omit causally important build software.** The CycloneDX Maven plugin produced zero dependency components even though two external build components participated in producing the JAR.

7. **The correct evidence depends on the question.** Project graph, plugin graph, plugin realm, generated source, packaged bytes, scanner output, SBOM and runtime each reveal different parts of the same supply-chain event.

The complete evidence chain is:

```text
application POM
        ↓
trace-injector-maven-plugin
        ↓
trace-route-payload
        ↓
Maven plugin ClassRealm
        ↓
GeneratedTraceRoute.java
        +
META-INF/services registration
        ↓
compiled/package application JAR
        ↓
ServiceLoader
        ↓
GET /hidden/build-info
```
