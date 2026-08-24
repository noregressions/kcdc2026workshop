---
id: t01-known-ground-truth
oneliner: "The S04 facts T01 begins with — plugin, payload and generated route — established before any tool is pointed at anything."
---

# T01 Known Ground Truth — S04

T01 starts with facts already established by the completed S04 walkthrough.

## Software of interest

```text
trace-injector-maven-plugin:1.0.0
        ↓
trace-route-payload:1.0.0
```

The payload contributes:

```text
/hidden/build-info
```

The plugin converts that build-time input into generated Java source and ServiceLoader metadata.

## Known evidence views

### Maven application dependency tree

S04 observed:

```text
dev.noregressions.trace:maven-plugin-hidden-content:jar:1.0.0
```

There were no application dependencies beneath the root.

### Maven plugin resolver

S04 observed:

```text
trace-injector-maven-plugin:1.0.0
    trace-route-payload:1.0.0
```

### Actual Maven plugin ClassRealm

S04 debug evidence included both:

```text
Included: dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
Included: dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

### Final JAR

The final application JAR contains:

```text
dev/noregressions/trace/s04/generated/GeneratedTraceRoute.class
META-INF/services/dev.noregressions.trace.s04.TraceRoute
META-INF/trace-lab/plugin-injection.properties
```

### Maven-model CycloneDX

The completed S04 walkthrough observed:

```text
CycloneDX: Creating BOM version 1.6 with 0 component(s)
```

### Syft final-JAR scan

S04 observed one identified package:

```text
maven-plugin-hidden-content  1.0.0  java-archive
```

Neither the plugin nor payload was recovered as package identity.

### Runtime

```json
{
  "message": "This runtime endpoint came from a transitive Maven plugin dependency.",
  "origin": "trace-route-payload",
  "introducedBy": "trace-injector-maven-plugin",
  "route": "/hidden/build-info"
}
```

## T01 success criterion

T01 does **not** require Snyk to find more.

A useful result is any defensible answer to:

```text
For each Snyk analysis mode:
  what evidence source did it use?
  what did it identify?
  did it expose plugin/payload identity?
  did it expose provenance?
  where did it stop?
```

---

# S03 Ground Truth

S03 already established:

```text
requirements.txt
    → reportkit 1.0.0 only

reportkit wheel METADATA
    → Requires-Dist: tracehook-demo==1.0.0

tracehook-demo 1.0.0
    → distributed as sdist
    → pyproject.toml nominates tracehook_backend
    → build backend runs during pip installation

original sdist
    → no tracehook_demo/__init__.py
    → no build-hook.json

generated wheel / installed environment
    → tracehook_demo/__init__.py present
    → build-hook.json present

runtime
    → reportkit imports generated tracehook_demo content
```

T01 asks whether Snyk preserves only the package dependency relationship or also the build-execution lineage that created the installed files.



---

# S05 Ground Truth

```text
source package → prepack declared + generator/input present
npm pack → prepack executes + dist generated
published tarball → package.json + dist only
installed package → publication output only
runtime → generated dist/index.js executes
```
