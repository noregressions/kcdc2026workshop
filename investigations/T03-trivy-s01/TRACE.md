---
id: t03-trivy-s01
oneliner: "Asks whether the vulnerability answer changes when the same software is observed as a dependency model, a Java archive, a browser bundle, or an image."
---

# T03 — Trivy Across S01 Boundaries

## Objective

Use one vulnerability tool, Trivy, against several evidence boundaries in S01.

The central question is:

> Does the vulnerability answer change when the same software is observed as a dependency model, a transformed Java archive, a browser bundle, or a final container image?

Trivy 0.74.0 was used for the observed run.

For source dependency models and the frontend bundle, the investigation uses:

```text
trivy fs
```

For built Java archives it uses:

```text
trivy rootfs
```

For the final image it uses:

```text
trivy image --image-src docker
```

The distinction matters: passing a JAR directly to `trivy fs` produced:

```text
Number of language-specific files num=0
```

and did not invoke the Java archive detector. The corrected archive probes stage each JAR in an isolated directory and scan that directory with `trivy rootfs`.

---

# Ground truth

## Look

S01 contains these tracer states:

```text
jackson-databind 2.19.4
    ordinary Maven dependency
    shipped intact

commons-codec 1.18.0
    service-selected Maven dependency
    shipped intact

commons-codec 1.17.1
    dependency of normalizer
    shaded and relocated
    Maven identity metadata survives in the original shaded JAR

normalizer 1.0.0
    custom application library

lodash 4.17.21
    npm dependency
    bundled by Vite
    npm package boundary disappears
```

A controlled copy of the shaded normalizer removes only:

```text
META-INF/maven/commons-codec/commons-codec/*
```

The relocated codec bytecode is unchanged.

## Run

```bash
./scripts/baseline-s01.sh
```

## Observe

Maven showed:

```text
normalizer
    -> commons-codec 1.17.1
```

The service dependency tree showed:

```text
service
    -> jackson-databind 2.19.4
    -> normalizer 1.0.0
         -> commons-codec 1.18.0
            (version managed from 1.17.1)
```

npm showed:

```text
checkout-trace-frontend@1.0.0
    -> lodash@4.17.21
```

The original shaded normalizer contained relocated codec classes under:

```text
com/acme/internal/codec/
```

and retained:

```text
META-INF/maven/commons-codec/commons-codec/pom.xml
META-INF/maven/commons-codec/commons-codec/pom.properties
```

The controlled stripped copy still contained the relocated codec bytecode but no codec Maven metadata.

Syft identified the original shaded archive as:

```text
commons-codec 1.17.1
normalizer    1.0.0
```

After only codec Maven metadata was removed, Syft no longer identified codec 1.17.1.

The service JAR physically contained:

```text
BOOT-INF/lib/jackson-databind-2.19.4.jar
BOOT-INF/lib/normalizer-1.0.0.jar
BOOT-INF/lib/commons-codec-1.18.0.jar
```

and the bundled frontend under:

```text
BOOT-INF/classes/static/
```

## Establish

The baseline separates:

```text
declared dependency identity
resolved dependency identity
physical shipped bytes
recoverable package identity
```

Those are not the same thing.

---

# Trivy across boundaries

## Run

```bash
./scripts/run-trivy-nonarchives-s01.sh
./scripts/run-trivy-archives-s01.sh
./scripts/compare-s01.sh
```

The full clean harness can also be run with:

```bash
./scripts/run-trivy-s01.sh
```

---

## Boundary 1 — normalizer POM

### Observe

Trivy identified:

```text
commons-codec 1.17.1
normalizer    1.0.0
```

No tracer vulnerability finding was reported.

### Establish

At the source dependency boundary, Trivy can identify codec 1.17.1 directly from Maven model evidence.

---

## Boundary 2 — service POM

### Observe

Trivy identified:

```text
jackson-databind 2.19.4
normalizer         1.0.0
```

It did not surface codec 1.18.0 in the tracer inventory from this single POM scan.

For Jackson 2.19.4 it reported:

```text
HIGH    CVE-2026-54512
HIGH    CVE-2026-54513
MEDIUM  CVE-2026-54514
MEDIUM  CVE-2026-54515
MEDIUM  CVE-2026-59888
```

### Establish

A source-model vulnerability scan answers a dependency-model question, not necessarily a complete resolved-graph or built-artefact question.

---

## Boundary 3 — frontend package-lock

### Observe

Trivy identified:

```text
lodash 4.17.21
```

and reported:

```text
HIGH    CVE-2026-4800
MEDIUM  CVE-2025-13465
MEDIUM  CVE-2026-2950
```

### Establish

At the npm package-model boundary, lodash has explicit package identity and Trivy can attach vulnerability intelligence to it.

---

## Boundary 4 — shaded normalizer JAR

### Observe

Using `trivy rootfs` against an isolated directory containing the shaded JAR, Trivy identified:

```text
commons-codec 1.17.1
normalizer    1.0.0
```

No tracer vulnerability finding was reported.

### Establish

Trivy can recover the shaded codec identity from the built artefact while the embedded Maven metadata survives.

---

## Boundary 5 — metadata-stripped shaded normalizer JAR

### Observe

The archive still contains the same relocated codec bytecode.

Trivy identified only:

```text
normalizer 1.0.0
```

It no longer identified:

```text
commons-codec 1.17.1
```

### Establish

This is the key controlled experiment:

```text
same relocated codec bytecode
        +
Maven metadata present
        ↓
commons-codec 1.17.1 identified

same relocated codec bytecode
        +
Maven metadata removed
        ↓
commons-codec identity disappears
```

The software bytes did not disappear.

The package identity did.

A CVE scanner cannot attach package-version vulnerability intelligence to an identity it has not established.

---

## Boundary 6 — Spring Boot service JAR

### Observe

Trivy identified:

```text
jackson-databind 2.19.4
commons-codec    1.17.1
commons-codec    1.18.0
normalizer       1.0.0
```

For Jackson 2.19.4 it reported the same five CVEs:

```text
2 HIGH
3 MEDIUM
```

### Establish

The built service JAR contains a software reality that differs from the service Maven model:

```text
service Maven model
    -> codec 1.18.0

built service JAR
    -> codec 1.18.0
    -> codec 1.17.1 embedded inside shaded normalizer
```

The shaded codec becomes visible because its identifying Maven metadata survives inside the nested normalizer archive.

---

## Boundary 7 — frontend/dist

### Observe

Trivy reported:

```text
Number of language-specific files num=0
```

No tracer identities were recovered.

No tracer vulnerability findings were reported.

### Establish

The Vite output ships browser JavaScript, but the npm package boundary has disappeared.

For lodash:

```text
package-lock.json
    -> lodash 4.17.21 identified
    -> 3 CVEs identified

frontend/dist
    -> no lodash package identity
    -> no lodash CVE findings
```

This is not evidence that lodash code is absent.

It is evidence that Trivy cannot reconstruct the npm package identity from the bundled output.

---

## Boundary 8 — final container image

### Observe

Trivy detected:

```text
OS: Ubuntu 22.04
OS packages analysed: 143
Java archive files analysed: 1
```

Tracer identity:

```text
jackson-databind 2.19.4
commons-codec    1.17.1
commons-codec    1.18.0
normalizer       1.0.0
```

Lodash was not recovered.

For Jackson 2.19.4 Trivy again reported:

```text
HIGH    CVE-2026-54512
HIGH    CVE-2026-54513
MEDIUM  CVE-2026-54514
MEDIUM  CVE-2026-54515
MEDIUM  CVE-2026-59888
```

### Establish

The final container exposes a broader deployed software boundary because Trivy also analyses operating-system packages.

But moving later in the supply chain does not restore npm identity that Vite already destroyed.

---

# Boundary comparison

| Boundary | codec 1.17.1 | codec 1.18.0 | Jackson 2.19.4 | lodash 4.17.21 |
| --- | --- | --- | --- | --- |
| normalizer POM | yes | no | no | no |
| service POM | no | no | yes | no |
| package-lock | no | no | no | yes |
| shaded normalizer JAR | yes | no | no | no |
| stripped normalizer JAR | no | no | no | no |
| service JAR | yes | yes | yes | no |
| frontend/dist | no | no | no | no |
| final container | yes | yes | yes | no |

For the tracer CVEs observed:

```text
Jackson 2.19.4
    service POM      -> 5 CVEs
    service JAR      -> 5 CVEs
    final container  -> 5 CVEs

lodash 4.17.21
    package-lock     -> 3 CVEs
    frontend/dist    -> none
    final container  -> none
```

---

# What T03 establishes

## 1. Vulnerability visibility depends on package identity

The controlled codec experiment demonstrates:

```text
code present
    !=
package identified
    !=
CVE can be attached
```

Removing only package metadata changes the scanner's software inventory even though the executable bytecode remains.

## 2. A source dependency model and a built artefact answer different questions

The normalizer POM says:

```text
commons-codec 1.17.1
```

The service Maven model says:

```text
commons-codec 1.18.0
```

The built service JAR exposes:

```text
commons-codec 1.17.1
commons-codec 1.18.0
```

All three are valid observations at different supply-chain boundaries.

## 3. Transformation can remove vulnerability visibility without removing code

Lodash demonstrates this independently of Java shading:

```text
npm lockfile
    -> identity present
    -> CVEs present

Vite bundle
    -> code still shipped
    -> npm identity absent
    -> CVEs absent
```

The absence of a CVE finding at the later boundary does not prove absence of the vulnerable code.

## 4. Moving the scanner later gives a broader deployed view, but not complete history

The container scan adds Ubuntu package analysis and sees the final application archive.

It still does not reconstruct lodash identity after bundling.

The final image therefore answers:

```text
what software can Trivy identify in this deployment?
```

not:

```text
what software participated in every earlier build transformation?
```

## 5. Scanner mode is part of the evidence model

For Trivy 0.74.0:

```text
trivy fs
    -> source/dependency model and filesystem-oriented scanning

trivy rootfs
    -> post-build filesystem/archive analysis

trivy image
    -> final container analysis
```

Using the wrong scan mode can produce a false negative experiment before vulnerability matching even begins.

---

# Final conclusion

T03 demonstrates that a CVE scanner is downstream of software identification.

The practical chain is:

```text
bytes exist
    ↓
scanner recognises package identity
    ↓
scanner determines package version
    ↓
vulnerability database matches affected range
    ↓
CVE appears
```

Break the chain at package identity and the CVE can disappear from the result even though the underlying code remains.

The practical rule is:

> A clean vulnerability scan proves only that the scanner found no matching vulnerabilities for the software identities it was able to establish at that evidence boundary. It does not prove that all shipped software was identified.
