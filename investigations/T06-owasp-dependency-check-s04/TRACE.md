---
id: t06-owasp-dependency-check-s04
oneliner: "Distinguishes application dependencies, plugin dependencies, plugin execution and final bytes — and which of them the scan can actually see."
---

# T06 — OWASP Dependency-Check / S04

## Objective

Use OWASP Dependency-Check against S04 to distinguish:

```text
application dependency inventory
Maven plugin dependency inventory
plugin execution
final application bytes
vulnerability matching
```

The central question is:

> If a Maven plugin and its transitive dependency generate runtime capability that survives in the final application JAR, at which boundary can Dependency-Check still identify the build-time packages?

---

# Tooling observed

```text
OWASP Dependency-Check Maven Plugin 13.0.0
```

The successful walkthrough used:

```text
NVD API key: supplied via NVD_API_KEY environment variable
```

Dependency-Check data directory:

```text
~/.cache/kcdc-dependency-check/13.0.0
```

---

# NVD API key

## Why this matters

OWASP Dependency-Check maintains a local vulnerability database populated from
NVD data.

An NVD API key is not conceptually required for Dependency-Check, but version
13.0.0 has a known no-key regression in its NVD update path. The T06
walkthrough therefore used a valid NVD API key with 13.0.0.

The NVD documents higher request limits when a key is supplied.

For a workshop, the best option is normally to reuse a pre-populated
Dependency-Check data directory so every attendee does not have to populate
the complete NVD database.

## Getting an NVD API key

Go to:

```text
https://nvd.nist.gov/developers/request-an-api-key
```

The request form asks for:

```text
organisation name
email address
organisation type
```

Then:

```text
1. Read and accept the NVD Terms of Use.
2. Submit the request.
3. Check the supplied email address for the NVD activation email.
4. Open the single-use activation link.
5. Activate and view the API key.
6. Store the key somewhere secure.
```

The activation link expires after seven days.

The page used to display the key is single-use, so copy it to a secure secret
store when it is displayed.

Requesting and activating another key with the same email address invalidates
the previous key.

Do not commit an NVD API key to this repository.

## Using the key with T06

Export it into the environment:

```bash
export NVD_API_KEY='your-key-here'
./scripts/run-dependency-check-s04.sh
```

Check that it is actually exported:

```bash
printenv NVD_API_KEY >/dev/null && echo "NVD_API_KEY is exported"
```

The harness should print:

```text
NVD API key: supplied via NVD_API_KEY environment variable
```

---

# 1. Establish the application dependency model

## Run

```bash
./scripts/baseline-s04.sh
```

## Observe

The application dependency tree contained only the application itself:

```text
dev.noregressions.trace:maven-plugin-hidden-content:jar:1.0.0
```

No normal application dependency on either controlled build-time tracer was
present.

## Establish

The ordinary Maven dependency universe is:

```text
maven-plugin-hidden-content 1.0.0
```

with no application dependency on:

```text
trace-injector-maven-plugin
trace-route-payload
```

---

# 2. Establish the plugin dependency model

## Observe

Maven plugin resolution showed:

```text
dev.noregressions.trace:trace-injector-maven-plugin:maven-plugin:1.0.0:runtime
    dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
    dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

## Establish

Maven has a separate build-tooling dependency domain:

```text
trace-injector-maven-plugin 1.0.0
    ↓
trace-route-payload 1.0.0
```

Neither package is an application dependency.

---

# 3. Prove both packages entered the actual plugin execution realm

## Observe

Maven debug output showed:

```text
Created new class realm plugin>dev.noregressions.trace:trace-injector-maven-plugin:1.0.0

Included:
dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

Maven then loaded:

```text
trace-injector-maven-plugin:1.0.0:inject-route
```

from that ClassRealm.

## Establish

The payload was not merely resolvable.

It was present in the actual Maven ClassRealm used to execute the build plugin.

---

# 4. Follow the build transformation

## Observe

Plugin execution generated:

```text
target/generated-sources/trace-injector/.../GeneratedTraceRoute.java

target/generated-resources/trace-injector/
    META-INF/services/dev.noregressions.trace.s04.TraceRoute
    META-INF/trace-lab/plugin-injection.properties
```

The final JAR contained:

```text
META-INF/trace-lab/plugin-injection.properties
META-INF/services/dev.noregressions.trace.s04.TraceRoute
dev/noregressions/trace/s04/generated/GeneratedTraceRoute.class
```

Disassembly of the final class contained:

```text
/hidden/build-info
trace-route-payload
trace-injector-maven-plugin
```

## Establish

The build-time packages changed the final runtime capability.

The transformation was:

```text
plugin + payload
    ↓ Maven ClassRealm
plugin execution
    ↓
generated Java + ServiceLoader metadata
    ↓ compile/package
final application JAR
```

The behaviour survives into the final JAR.

---

# 5. Default Dependency-Check Maven scan

## Run

```bash
./scripts/run-dependency-check-s04.sh
```

## Observe

The default scan produced:

```text
Dependencies: 0
Vulnerability records: 0
S04 tracers:
(none)
```

## Establish

The default Maven Dependency-Check view followed the ordinary application
dependency model.

It did not include:

```text
trace-injector-maven-plugin
trace-route-payload
```

So:

```text
default application scan
    !=
complete Maven build-tooling inventory
```

---

# 6. Enable plugin scanning

## Observe

With Maven plugin scanning enabled, Dependency-Check reported:

```text
Dependencies: 167
Vulnerability records: 78
```

It identified both controlled S04 tracers:

```text
trace-injector-maven-plugin-1.0.0.jar
pkg:maven/dev.noregressions.trace/trace-injector-maven-plugin@1.0.0

trace-route-payload-1.0.0.jar
pkg:maven/dev.noregressions.trace/trace-route-payload@1.0.0
```

Neither tracer had a vulnerability match.

The plugin-aware scan also exposed vulnerabilities in build-time tooling,
including dependencies such as:

```text
commons-beanutils 1.7.0
commons-compress 1.20
commons-io 2.6
commons-io 2.11.0
guava 16.0.1
maven-core 3.2.5
jetty 9.4.46.v20220331
plexus-archiver 4.2.7
velocity 1.7
```

## Establish

Changing only the evidence admitted to Dependency-Check changed the software
universe from:

```text
0 dependencies
0 vulnerability records
```

to:

```text
167 dependencies
78 vulnerability records
```

This is the strongest T06 result.

The difference is not a different vulnerability database.

It is a different dependency boundary.

---

# 7. Scan the final application JAR

## Observe

The final JAR scan produced:

```text
Dependencies: 1
Vulnerability records: 0
```

The only S04 identity recovered was:

```text
maven-plugin-hidden-content-1.0.0.jar
pkg:maven/dev.noregressions.trace/maven-plugin-hidden-content@1.0.0
```

The final JAR scan did not identify:

```text
trace-injector-maven-plugin
trace-route-payload
```

## Establish

The final application JAR retains the generated behaviour:

```text
GeneratedTraceRoute.class
ServiceLoader metadata
/hidden/build-info
trace-route-payload
trace-injector-maven-plugin
```

but it no longer retains those original build-time components as package
identities.

So:

```text
runtime behaviour present
    !=
build-time package identity recoverable
```

---

# 8. Direct plugin/payload controls

## Observe

Scanning the original build-time JARs directly produced:

```text
Dependencies: 2
Vulnerability records: 0
```

Dependency-Check identified both:

```text
trace-injector-maven-plugin-1.0.0.jar
pkg:maven/dev.noregressions.trace/trace-injector-maven-plugin@1.0.0

trace-route-payload-1.0.0.jar
pkg:maven/dev.noregressions.trace/trace-route-payload@1.0.0
```

## Establish

This rules out:

```text
Dependency-Check cannot recognise the controlled tracer JARs
```

The scanner can identify both original packages when the package boundaries
are still available.

The loss occurs after the plugin transformation:

```text
original plugin/payload JARs
    → identities recoverable

final application JAR
    → identities not recoverable
```

---

# 9. Compare the tracer sets

Observed:

```text
default Maven
    no tracers

plugin-aware Maven
    trace-injector-maven-plugin
    trace-route-payload

final JAR
    maven-plugin-hidden-content only

direct plugin/payload
    trace-injector-maven-plugin
    trace-route-payload
```

The transformation boundary is therefore visible directly in the
Dependency-Check results.

---

# 10. Dependency-Check operational findings

The first full 13.0.0 run populated:

```text
381,857 NVD records
```

and took substantially longer than subsequent runs.

Once populated, later scans reused the local database and completed quickly.

The first run also encountered unrelated RetireJS and .NET Assembly analyzer
noise. The final harness disables those analyzers because they are outside the
Java-only experiment.

A separate 13.0.0 no-key run failed before analysis with:

```text
NvdApiException:
Invalid API Key, length of 0 too short to provided a masked partial key
```

That failure was not an S04 dependency-analysis result.

---

# What T06 establishes

## 1. Maven has more than one dependency universe

The ordinary application dependency graph can be empty while Maven still
loads a substantial amount of executable third-party software to build the
application.

For S04:

```text
application dependencies
    0

plugin-aware Dependency-Check inventory
    167
```

---

## 2. Build tooling has its own vulnerability surface

Enabling plugin scanning exposed:

```text
78 vulnerability records
```

that were completely absent from the default application scan.

Therefore:

```text
application vulnerability scan
    !=
build-pipeline vulnerability scan
```

---

## 3. Maven plugin dependencies can directly change shipped runtime behaviour

`trace-route-payload` was:

```text
not an application dependency
present in the Maven plugin ClassRealm
used during plugin execution
responsible for generated runtime content
```

The final application exposes:

```text
/hidden/build-info
```

because of that build-time dependency.

---

## 4. A final artefact scan cannot reconstruct every build-time dependency

The final JAR still contains the generated behaviour, but Dependency-Check
identified only:

```text
maven-plugin-hidden-content 1.0.0
```

It did not reconstruct:

```text
trace-injector-maven-plugin
trace-route-payload
```

So:

```text
shipped behaviour
    !=
recoverable build provenance
```

---

## 5. Direct controls prove this is identity loss, not scanner incapability

When shown the original plugin and payload JARs directly, Dependency-Check
identified both.

Therefore the missing identities in the final application JAR are caused by
the transformation boundary, not by an inability to recognise the packages.

---

## 6. Vulnerability visibility depends on what enters the inventory

The same Dependency-Check engine and vulnerability database produced:

```text
default Maven
    0 vulnerabilities

plugin-aware Maven
    78 vulnerability records
```

The decisive variable was not the CVE data.

It was what software identities the scan admitted.

---

# Final conclusion

T06 demonstrates:

```text
application dependency graph
    !=
build-tool dependency graph
    !=
plugin execution realm
    !=
final artefact package identity
```

and:

```text
software executed during build
    can alter shipped runtime behaviour
    without remaining identifiable
    in the final application artefact
```

The practical rule is:

> Scan build tooling at the point where its package identity still exists. A later scan of the shipped application cannot reliably reconstruct the software that transformed it.
