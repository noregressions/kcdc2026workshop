# T01 — Snyk Beyond the SBOM

## Question

> What does a commercial SCA tool know that an ordinary SBOM does not, and which supply-chain transformations remain invisible even to it?

This investigation reuses five completed trace labs:

```text
S01  Spring + Node
S02  Payara + mvnpm
S03  Python + PEP 517
S04  Maven plugin hidden-content
S05  Node + npm prepack
```

The investigation compares several evidence types:

```text
source declarations
package-manager dependency models
build-tool execution evidence
generated artefacts
SBOMs
Snyk project scans
Snyk artefact/unmanaged scans
runtime evidence
```

The central result is:

```text
better package identity
        !=
complete supply-chain history
```

Snyk can often provide richer identity, vulnerability and dependency-path information than a basic SBOM. But it does not reconstruct every build realm, lifecycle action, code-generation step, bundling transformation, or publication-time mutation after those facts have disappeared from the dependency model.

---

# S01 — Spring + Node

## Ground truth

The lab contains four useful tracer states:

```text
jackson-databind 2.19.4
    ordinary Maven dependency
    physically shipped as intact nested JAR

commons-codec 1.17.1
    dependency of normalizer
    shaded and relocated into normalizer
    Maven package metadata survives

commons-codec 1.18.0
    selected by service dependency management
    physically shipped as intact nested JAR

lodash 4.17.21
    npm dependency
    bundled by Vite into generated browser JavaScript
    package boundary disappears
```

Maven resolves:

```text
normalizer
    → commons-codec 1.17.1

service
    → normalizer
        → commons-codec 1.18.0
    → jackson-databind 2.19.4
```

The final Spring Boot JAR physically contains:

```text
BOOT-INF/lib/jackson-databind-2.19.4.jar
BOOT-INF/lib/normalizer-1.0.0.jar
BOOT-INF/lib/commons-codec-1.18.0.jar
```

The normalizer JAR also contains relocated `commons-codec 1.17.1` bytecode.

Syft can identify `commons-codec 1.17.1` inside the shaded normalizer while its Maven metadata survives. Removing only:

```text
META-INF/maven/commons-codec/commons-codec/
```

makes that identity disappear from Syft while leaving the relocated bytecode unchanged.

## Snyk Maven project result

Snyk's Maven aggregate view identifies both codec versions in their respective module contexts:

```text
normalizer
    → commons-codec 1.17.1

service
    → normalizer
        → commons-codec 1.18.0
    → jackson-databind 2.19.4
```

This proves Snyk knows both versions from the Maven reactor model.

It does **not** prove that Snyk independently reconstructed the physical fact that both versions' code ship in the final application.

## Snyk provenance result

`--include-provenance` preserves the same component set.

For external Maven artefacts it adds checksum-qualified PURLs such as:

```text
pkg:maven/commons-codec/commons-codec@1.17.1?checksum=sha1:...
pkg:maven/commons-codec/commons-codec@1.18.0?checksum=sha1:...
pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.19.4?checksum=sha1:...
```

The root reactor POM gains:

```text
?type=pom
```

The result is:

> Snyk provenance strengthens the identity of software already present in its dependency model. It does not broaden the dependency model.

## Snyk npm result

From the npm project Snyk identifies:

```text
lodash 4.17.21
```

and reports vulnerability information for it.

After Vite bundling, scanning `frontend/dist` produces:

```text
No supported files found
```

So the correct interpretation is not:

```text
Snyk inspected the bundle and failed to recognise lodash
```

but:

```text
the deployable bundle no longer presents a supported npm project boundary
```

No tested artefact-oriented Snyk view recovered `lodash 4.17.21` from the shipped browser bundle.

## Snyk unmanaged JAR result

Direct unmanaged scans of both:

```text
normalizer-1.0.0.jar
normalizer-no-codec-metadata.jar
```

produce an `unknown` custom JAR.

Unlike Syft, Snyk unmanaged scanning did not identify shaded `commons-codec 1.17.1` from the surviving Maven metadata.

Scanning the complete Spring Boot JAR also produced one unknown custom JAR.

After unpacking the Spring Boot JAR, recursive unmanaged scanning identifies intact nested libraries such as:

```text
commons-codec 1.18.0
jackson-databind 2.19.4
```

while the custom shaded normalizer remains unknown.

## S01 establishes

```text
known from model + shipped intact
    → recoverable from Maven model
    → recoverable again when intact nested package boundary survives

known from model + transformed
    → visible before transformation
    → may become unrecoverable afterwards

known from npm model + bundled
    → visible before bundling
    → package identity can disappear from deployable output
```

---

# S02 — Payara + mvnpm

## Ground truth

The application has:

```text
commons-lang3 3.18.0
    ordinary application dependency
    physically shipped in WEB-INF/lib

Jakarta EE Web API 11.0.0
    Maven provided dependency
    present in application dependency model
    absent from WAR

lodash-es 4.17.21
    dependency of esbuild Maven plugin
    present in actual Maven plugin ClassRealm
    contributes source modules to generated browser bundle
    absent from application dependency graph
```

The generated source map proves `lodash-es` source modules contributed to the browser bundle.

## Snyk project result

Snyk's Maven project scan identifies the application dependency graph, including:

```text
Jakarta provided dependencies
commons-lang3 3.18.0
```

It does not identify:

```text
lodash-es 4.17.21
```

because that package exists in the Maven plugin realm rather than the application dependency graph.

## Provenance

Normal `snyk test` JSON emitted no PURLs.

With `--include-provenance`, Snyk added PURLs for the same Maven dependency set:

```text
root
    → ?type=war

dependencies
    → ?checksum=sha1:...
```

The CycloneDX comparison showed the same component set before and after provenance enrichment.

Critically, Snyk checksum-qualified Jakarta `provided` dependencies even though they were not physically shipped in the WAR.

Therefore:

```text
provenance identity
        !=
physical inclusion proof
```

## Artefact scanning

Direct unmanaged scan of the whole WAR:

```text
unknown custom WAR
```

After unpacking the WAR, Snyk identifies preserved `commons-lang3 3.18.0`.

It does not reconstruct `lodash-es 4.17.21` from the generated browser bundle.

## S02 establishes

```text
modelled but not shipped
    → Jakarta provided APIs

modelled and shipped intact
    → commons-lang3

not modelled by the application but code ships
    → lodash-es
```

Snyk's project/provenance model handles the first two well, but the Maven plugin-domain contribution remains invisible.

---

# S03 — Python + PEP 517

## Ground truth

The application declares:

```text
reportkit==1.0.0
```

The `reportkit` wheel metadata declares:

```text
Requires-Dist: tracehook-demo==1.0.0
```

`tracehook-demo` is supplied as an sdist containing:

```text
pyproject.toml
tracehook_backend.py
```

Its PEP 517 configuration declares:

```text
build-backend = "tracehook_backend"
backend-path = ["."]
```

The original sdist does not contain:

```text
tracehook_demo/__init__.py
tracehook_demo/build-hook.json
```

During `pip install`, pip builds a wheel and executes:

```text
tracehook_backend.build_wheel()
```

The generated wheel contains both runtime files.

The installed marker records:

```text
event       = pep517-build-backend-executed
generatedBy = tracehook_backend.build_wheel
```

and the generated content affects runtime behaviour.

## Snyk Pip result

Snyk reconstructs the full installed dependency graph:

```text
S03-python-pep517
    → reportkit 1.0.0
        → tracehook-demo 1.0.0
```

Its CycloneDX SBOM preserves:

```text
application
    → reportkit
        → tracehook-demo
```

## Missing execution history

The actual Snyk outputs contain no evidence for:

```text
tracehook_backend
build_wheel
build-hook.json
pep517-build-backend-executed
```

Snyk can therefore reconstruct package dependency identity without reconstructing the executable PEP 517 build history that produced the installed files.

## Package artefact boundaries

In the tested modes, Snyk Open Source did not treat any of these as a supported project on their own:

```text
unpacked tracehook sdist
unpacked generated wheel
installed site-packages directory
```

The successful scan is anchored on the application `requirements.txt` plus the installed Python environment.

## S03 establishes

```text
dependency graph knowledge
        !=
build execution history
```

---

# S04 — Maven plugin hidden-content

## Ground truth

The application has no ordinary third-party runtime dependencies.

During the build:

```text
trace-injector-maven-plugin
    → trace-route-payload
```

exist in the Maven plugin resolution domain and actual plugin ClassRealm.

The plugin generates:

```text
GeneratedTraceRoute.class
META-INF/services/dev.noregressions.trace.s04.TraceRoute
META-INF/trace-lab/plugin-injection.properties
```

The resulting application exposes:

```text
/hidden/build-info
```

even though that route did not exist in checked-in application source.

## Application dependency views

Maven application dependency tree:

```text
application only
```

Maven CycloneDX:

```text
0 dependency components
```

Syft final-JAR scan:

```text
application archive only
```

## Snyk project result

Normal Snyk Maven analysis identifies:

```text
application only
```

It does not identify:

```text
trace-injector-maven-plugin
trace-route-payload
```

## Snyk provenance

`--include-provenance` adds a Maven PURL to the known root application artefact.

It does not discover the plugin or payload.

In Snyk's CycloneDX output, provenance produced no substantive component-set change beyond run-specific metadata.

## Unmanaged JAR scan

The final custom JAR is reported as:

```text
unknown
```

The scan exposes uncertainty but does not reconstruct the plugin/payload relationship or build history.

## S04 establishes

```text
Maven dependency tree     → application only
Maven plugin resolver     → plugin + payload
Maven plugin ClassRealm   → plugin + payload
Maven CycloneDX           → no dependency components
Snyk Maven                → application only
Snyk + provenance         → same known application identity, enriched
Snyk unmanaged JAR        → unknown custom JAR
runtime                   → plugin-generated behaviour executes
```

The build-tool dependency realm is a distinct evidence source.

---

# S05 — Node + npm prepack

## Ground truth

The application depends on:

```text
trace-route-package 1.0.0
```

The package source declares:

```json
{
  "main": "dist/index.js",
  "files": ["dist"],
  "scripts": {
    "prepack": "node scripts/generate-dist.js"
  }
}
```

The source contains:

```text
build-input/route.json
scripts/generate-dist.js
```

The clean build removes any old `dist/`, then `npm pack` records:

```text
trace-route-package@1.0.0 prepack
node scripts/generate-dist.js
generated dist/index.js
generated dist/prepack-evidence.json
```

The resulting tarball contains only:

```text
package.json
dist/index.js
dist/prepack-evidence.json
```

It does **not** contain:

```text
scripts/generate-dist.js
build-input/route.json
```

The installed package preserves the same publication boundary.

Runtime imports the generated `dist/index.js`.

## A particularly awkward publication state

The published `package.json` still declares:

```text
prepack = node scripts/generate-dist.js
```

but the referenced file:

```text
scripts/generate-dist.js
```

is absent from the published package.

Therefore the published package contains a lifecycle declaration but not the executable source that previously satisfied it.

That declaration alone is not proof that the lifecycle hook executed.

The `npm pack` log provides that proof.

## Snyk application result

Snyk identifies:

```text
node-prepack-trace-lab 1.0.0
    → trace-route-package 1.0.0
```

The Snyk CycloneDX SBOM preserves the same relationship.

## Snyk package scans

Snyk can independently scan:

```text
source trace-route-package
unpacked published tarball
installed trace-route-package
```

because each retains `package.json`.

All scans succeed.

## Missing publication history

The real Snyk outputs contain no evidence for:

```text
scripts/generate-dist.js
npm-prepack-generated
prepack-evidence.json
/hidden/prepack-info
```

Textual matches for `prepack` are only incidental occurrences in project/path names such as:

```text
node-prepack-trace-lab
```

They are not lifecycle-script evidence.

Even when scanning the source package, where the lifecycle declaration and generator physically exist, the Snyk Open Source result does not expose the `prepack` action as supply-chain execution evidence.

## S05 establishes

```text
npm package identity
        !=
npm publication history
```

Snyk knows what package is present, but the tested dependency views do not explain how npm manufactured the files that package published.

---

# Cross-scenario matrix

| Evidence / capability | S01 | S02 | S03 | S04 | S05 |
| --- | --- | --- | --- | --- | --- |
| Normal dependency model | Java + npm identities visible before transformation | App Maven deps visible | Python transitive package recovered | Plugin/payload absent | npm package recovered |
| Snyk SBOM | Same project identities | Same app Maven identities | Preserves Python transitive edge | Plugin/payload absent | Preserves npm dependency edge |
| Provenance enrichment | Same Maven set + checksum PURLs | Same Maven set + checksum PURLs | not applicable in tested Python mode | Root identity enriched only | not used |
| Build-time dependency realm | not reconstructed from final artefact | `lodash-es` plugin realm missed | PEP 517 backend execution not represented | plugin + payload missed | lifecycle execution not represented |
| Generated/bundled content lineage | lodash not recovered after bundle | lodash-es not recovered after bundle | generated Python files not tied to backend | generated route not tied to plugin | generated dist not tied to prepack |
| Intact package artefact recovery | nested JARs recoverable after unpack | commons JAR recoverable after unpack | project anchored to manifest + environment | custom JAR unknown | package.json remains enough for npm project scan |
| Transformed custom artefact recovery | shaded normalizer unknown to Snyk unmanaged | n/a | n/a | custom application JAR unknown | n/a |
| Evidence outside Snyk still required | shade metadata / physical JAR / bundling evidence | Maven plugin ClassRealm + source map | pip build log + sdist/backend + generated marker | Maven plugin resolver/ClassRealm | npm pack log + generator + generated evidence |

---

# What T01 establishes

## 1. Snyk can know more than a literal source declaration

Examples:

```text
requirements.txt
    reportkit only

Snyk
    reportkit → tracehook-demo
```

and:

```text
npm application
    → trace-route-package
```

Snyk dependency analysis reconstructs dependency relationships rather than merely echoing top-level declarations.

## 2. Snyk can provide materially richer security intelligence than a basic inventory

The investigation observed Snyk adding:

```text
dependency paths
vulnerability intelligence
fix guidance
PURLs
checksum-qualified Maven identities in provenance mode
```

That is useful information beyond a minimal component list.

## 3. Provenance enrichment is not provenance reconstruction

For the Maven cases:

```text
--include-provenance
    → stronger identities for known Maven artefacts
```

It did not discover:

```text
Maven plugin-realm packages
code-generation history
bundling history
lifecycle execution
```

Therefore:

```text
provenance enrichment
        !=
supply-chain history reconstruction
```

## 4. Package-manager models and shipped artefacts answer different questions

A model may include something not shipped:

```text
Jakarta provided dependencies
```

A shipped artefact may contain something absent from the application model:

```text
lodash-es code introduced through a Maven plugin
```

A transformed artefact may contain code whose package identity has become difficult or impossible for the tested scanner to recover:

```text
bundled lodash
shaded custom JAR contents
```

## 5. Build systems have dependency and execution domains outside the application dependency graph

Observed examples:

```text
Maven plugin ClassRealm
PEP 517 build backend
npm prepack lifecycle
```

These domains can execute code and materially change the resulting application without becoming ordinary runtime dependency edges.

## 6. Generated content does not carry its own history automatically

Observed examples:

```text
Vite browser bundle
PEP 517 generated Python files
Maven-plugin-generated Java/service metadata
npm-prepack-generated dist files
```

A scanner observing only the final output may identify some surviving package boundaries, but it cannot be assumed to reconstruct the process that created those bytes.

## 7. Evidence must be collected at the boundary where the fact still exists

For these labs:

```text
Maven application graph
    → ordinary application dependency resolution

Maven plugin ClassRealm
    → build-plugin dependencies

npm/package-lock
    → Node package identity before bundling

pip build log + sdist
    → PEP 517 build execution

npm pack log
    → publication lifecycle execution

final artefact scan
    → software whose package boundaries survive strongly enough
```

No single one of these views is the complete supply-chain record.

---

# Final conclusion

The strongest T01 conclusion is not that Snyk is deficient.

It is that software supply-chain evidence is **boundary-specific**.

Snyk is good at the dependency models and package identities it supports, and can enrich those identities with useful security and provenance information.

But once a build or publication transformation crosses out of that model:

```text
plugin execution
shading
bundling
PEP 517 build hooks
npm lifecycle scripts
generated code
```

the missing history cannot be assumed to be recoverable later from the final artefact.

The practical rule is:

> Capture supply-chain evidence when the transformation happens. Do not rely on a later scanner to reconstruct facts that the build has already discarded.
