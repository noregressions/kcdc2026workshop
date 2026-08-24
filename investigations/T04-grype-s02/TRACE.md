---
id: t04-grype-s02
oneliner: "Separates how Grype constructs a software inventory from how it matches vulnerabilities against that inventory."
track: reference
---

# T04 — Grype / S02

## Objective

Use Grype against S02 to separate:

```text
software inventory construction
```

from:

```text
vulnerability matching
```

The central question is:

> Does Grype produce a different vulnerability answer when it discovers the Payara image itself versus when it consumes an SBOM generated from that same image?

The observed run used:

```text
Grype 0.115.0
Syft 1.46.0
Grype DB schema 6.1.9
Grype DB built 2026-08-22T06:14:16Z
DB status: valid
```

The same final image and the same Grype vulnerability database were used throughout.

---

# S02 ground truth

## Look

S02 has three deliberately different kinds of software evidence.

### Application dependencies

The Maven application model contains:

```text
jakarta.platform:jakarta.jakartaee-web-api:11.0.0   provided
org.apache.commons:commons-lang3:3.18.0             compile
```

### Maven plugin dependencies

The `esbuild-maven-plugin` runs during `generate-resources`.

Its Maven plugin realm contains:

```text
io.mvnpm:esbuild-maven-plugin:2.0.0
org.mvnpm:lodash-es:4.17.21
```

The plugin realm also contains its own larger transitive toolchain, including:

```text
commons-codec 1.19.0
commons-lang3 3.18.0
jackson-databind 2.20.1
jackson-core 2.20.1
```

### WAR contents

The built WAR contains:

```text
WEB-INF/lib/commons-lang3-3.18.0.jar
assets/app.js
assets/app.js.map
```

It does not physically package the provided Jakarta EE API dependency.

It does not contain a `lodash-es` package boundary.

## Run

```bash
./scripts/baseline-s02.sh
```

## Observe

The final image is:

```text
payara-mvnpm-trace-lab:local
```

Observed image digest:

```text
sha256:9deab630f88089a2254668ed55569a73f0317a0d1d226832ed1134436a48aeaa
```

Syft catalogued:

```text
589 packages
825 executables
5,424 locations
```

The Syft image inventory identifies:

```text
commons-lang3 3.18.0
payara-mvnpm-trace-lab 1.0.0
many Jakarta API/runtime components supplied by Payara
```

It does not identify:

```text
lodash-es 4.17.21
```

The generated CycloneDX document contained:

```text
6014 components
```

This number is not treated as equivalent to the Syft package count. The CycloneDX document represents more than the 589-package catalogue.

## Establish

S02 separates four boundaries:

```text
application dependency model
Maven plugin realm
WAR contents
final deployed container
```

They contain different software universes.

---

# Grype experiment

## Run

```bash
./scripts/run-grype-s02.sh
```

Grype was run three ways:

```text
1. docker:payara-mvnpm-trace-lab:local

2. sbom:results/s02/baseline/image.syft.json

3. sbom:results/s02/baseline/image.cdx.json
```

Two direct PURL controls were also used:

```text
pkg:maven/org.apache.commons/commons-lang3@3.18.0
pkg:maven/org.mvnpm/lodash-es@4.17.21
```

---

# Database state

## Observe

The first attempted run failed because the local Grype database was too old:

```text
Status: invalid
the vulnerability database was built 2 weeks ago
(max allowed age is 5 days)
```

After refreshing the database, the successful run reported:

```text
Schema: v6.1.9
Built: 2026-08-22T06:14:16Z
Status: valid
```

## Establish

Vulnerability database state is part of the evidence.

A stale or invalid database can prevent the vulnerability experiment from running at all.

---

# Direct image scan

## Observe

Grype reported:

```text
169 unique vulnerability matches
```

The findings include both operating-system and Java-runtime packages.

Examples from the final image include:

```text
nimbus-jose-jwt 10.0.1
    GHSA-xwmg-2g98-w7v9
    Medium
    fixed in 10.0.2

jline-remote-telnet 3.30.15
    GHSA-2r2c-cx56-8933
    High
    fixed in 4.2.1

jline-remote-telnet 3.30.15
    GHSA-47qp-hqvx-6r3f
    High
    fixed in 4.2.1

jackson-core 2.15.2
    GHSA-r7wm-3cxj-wff9
    High
    fixed in 2.18.8

jackson-core 2.15.2
    GHSA-72hv-8253-57qq
    Medium
    fixed in 2.18.6
```

There were also many Ubuntu package findings.

No tracer-related vulnerability match was reported for:

```text
commons-lang3
lodash-es
Payara-named tracer pattern
Jakarta-named tracer pattern
```

## Establish

The final-image vulnerability answer is dominated by the deployed runtime/base-image software universe, not merely the application WAR.

The harness did not expose a direct Grype package-catalogue count, so this investigation does not claim one.

---

# Syft JSON input

## Observe

Grype emitted:

```text
document has schema version 16.1.10,
but parser has older schema version 16.1.5
```

Despite that compatibility warning, Grype again produced:

```text
169 unique vulnerability matches
```

## Establish

For this image and these tool versions, the Syft schema-version warning did not change the resulting vulnerability match set.

---

# CycloneDX input

## Observe

Grype consumed the CycloneDX SBOM generated from the same image and again produced:

```text
169 unique vulnerability matches
```

## Establish

The fact that the CycloneDX document contains 6014 components rather than the Syft JSON's 589 package artifacts did not produce a different vulnerability answer in this run.

Those raw document counts therefore should not be interpreted as equivalent package counts.

---

# Exact match-set comparison

## Run

```bash
./scripts/compare-s02.sh
```

## Observe

The final comparison showed:

```text
direct image     169 unique vulnerability matches
Syft JSON        169 unique vulnerability matches
CycloneDX        169 unique vulnerability matches
```

and:

```text
direct image vs Syft JSON
    no differences

direct image vs CycloneDX
    no differences

Syft JSON vs CycloneDX
    no differences
```

## Establish

For this S02 image:

```text
Grype direct discovery
        =
Grype over Syft JSON
        =
Grype over CycloneDX
```

with respect to the vulnerability match set.

The inventory representation did not change Grype's vulnerability answer.

---

# commons-lang3 control

## Observe

The final image inventory contains:

```text
commons-lang3 3.18.0
```

The direct PURL control produced:

```text
no vulnerability matches
```

The image/SBOM scans likewise produced no tracer-related vulnerability match for commons-lang3.

## Establish

This is not an inventory failure.

Grype identifies the package in the final image inventory, but the observed Grype vulnerability database produced no match for that package/version.

---

# lodash-es control

## Observe

Maven plugin evidence proves:

```text
org.mvnpm:lodash-es:4.17.21
```

was included in the `esbuild-maven-plugin` ClassRealm during the build.

The final WAR contains the generated browser bundle, but no `lodash-es` package boundary.

The final image Syft inventory does not identify lodash-es.

The direct PURL control also produced:

```text
no vulnerability matches
```

## Establish

For this run, lodash-es cannot demonstrate:

```text
Grype knows the vulnerability
but package discovery loses the package
```

because the direct PURL control produced no vulnerability match.

What it does demonstrate is:

```text
build participation
    !=
final-image package identity
```

Grype cannot vulnerability-match a final-image package identity that is not present in the supplied inventory.

---

# Provided dependencies and runtime supply

## Observe

The application Maven model declares:

```text
jakarta.jakartaee-web-api 11.0.0
    scope: provided
```

The WAR does not package that API dependency.

The final image nevertheless contains many Jakarta components, including:

```text
jakarta.servlet-api 6.1.0
jakarta.ws.rs-api 4.0.0
jakarta.persistence-api 3.2.0
jakarta.validation-api 3.1.1
...
```

Those components are supplied by the Payara runtime image.

## Establish

The container vulnerability scan answers:

```text
what software is deployed together?
```

It does not tell us that all software found in the image came from the application dependency graph or WAR.

---

# What T04 establishes

## 1. Grype can consume different inventory representations without changing the answer

In this experiment:

```text
direct image
Syft JSON
CycloneDX
```

all produced exactly:

```text
169 unique vulnerability matches
```

with no match-set differences.

This means the SBOM representation was not the source of vulnerability-answer variation here.

## 2. Inventory still determines what can be vulnerability-matched

The equality of the three Grype results does not mean the inventory is complete.

All three views ultimately describe the same final-image software boundary.

They all omit `lodash-es` identity after its build-time contribution has been bundled away.

## 3. A container vulnerability scan includes software the application did not package

The application WAR contains commons-lang3 and generated browser assets.

The final container also contains:

```text
Ubuntu OS packages
Payara/GlassFish runtime libraries
Jakarta APIs
server-side Jackson
JLine
Nimbus JOSE JWT
...
```

Those packages materially change the deployed vulnerability surface.

## 4. Build-time software can disappear before final-image vulnerability scanning

`lodash-es 4.17.21` is proven in the Maven plugin realm.

Its package identity does not survive into the WAR or final image inventory.

Therefore:

```text
software participated in producing the artefact
```

does not imply:

```text
final-image vulnerability scanner can identify that software
```

## 5. The vulnerability database is itself part of the result

The initial run could not proceed because the DB was invalid due to age.

After updating it, the scan succeeded.

A CVE scan therefore depends on at least:

```text
inventory evidence
package identity
version identity
vulnerability database content
database freshness/validity
matching rules
```

---

# Final conclusion

T04 demonstrates that changing the *representation* of a good final-image inventory does not necessarily change the vulnerability answer.

For this image:

```text
direct image discovery
        =
Syft JSON
        =
CycloneDX
```

at the Grype vulnerability-match layer.

But all three still inherit the same supply-chain limitation:

> They can only vulnerability-match software identities that survived into, or can be reconstructed from, the final-image evidence.

The practical rule is:

> An SBOM-driven CVE scan can be perfectly consistent with a direct image scan and still miss software that disappeared as an identifiable package at an earlier build boundary.
