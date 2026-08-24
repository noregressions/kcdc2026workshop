---
id: t01-s01-spring-node
oneliner: "Snyk against S01's four tracer states, including the shaded JAR and the bundled frontend."
---

# T01 / S01 — Snyk Against Spring + Node

This is the S01 case inside **T01 — Snyk Beyond the SBOM**.

S01 contains four useful tracer states:

```text
jackson-databind 2.19.4
    ordinary Maven dependency
    survives as an intact nested JAR


commons-codec 1.17.1
    resolved by normalizer
    shaded and relocated to com.acme.internal.codec
    original Maven metadata survives inside normalizer

commons-codec 1.18.0
    selected in the service graph
    survives as an ordinary nested JAR

lodash 4.17.21
    ordinary npm dependency before the frontend build
    folded into Vite-generated JavaScript
    package boundary absent from deployable frontend
```

S01 already established an important controlled result:

```text
shaded commons-codec bytecode + Maven metadata
    → Syft identifies commons-codec 1.17.1

same shaded bytecode - Maven metadata
    → Syft no longer identifies commons-codec

frontend/dist
    → Syft identifies 0 packages

final Spring Boot JAR
    → Syft identifies commons-codec 1.17.1
    → Syft identifies commons-codec 1.18.0
    → Syft identifies jackson-databind 2.19.4
    → no lodash package identified
```

The Snyk questions are:

> Does Snyk behave like the Maven model, like Syft's artefact inspection, or differently at each evidence boundary?

and:

> Can Snyk recover package identity after shading or JavaScript bundling?

---

# 1. Re-establish S01 ground truth

## Run

```bash
./scripts/baseline-s01.sh
```

The baseline also populates an isolated Maven repository under:

```text
results/s01/maven-repo
```

because Snyk's Maven provenance mode requires resolved artefacts to be present in a local Maven repository.

## Observe

Capture during walkthrough.

## Establish

Confirm:

```text
normalizer resolves commons-codec 1.17.1
service graph resolves commons-codec 1.18.0
service resolves jackson-databind 2.19.4
npm resolves lodash 4.17.21

normalizer contains relocated com.acme.internal.codec bytecode
normalizer retains commons-codec Maven metadata
metadata-stripped normalizer retains bytecode but loses that metadata

frontend/dist contains generated assets, not node_modules/lodash

service JAR contains:
    jackson-databind 2.19.4
    normalizer 1.0.0
    commons-codec 1.18.0
    frontend static assets
```

---

# 2. Run Snyk against the Maven reactor

## Run

```bash
./scripts/run-snyk-s01.sh
```

The first four probes are:

```text
Snyk Maven aggregate test
Snyk Maven aggregate test + --include-provenance
Snyk Maven aggregate CycloneDX
Snyk Maven aggregate CycloneDX + --include-provenance
```

## Question

Does the Maven reactor view expose both commons-codec versions because it sees both module contexts?

Does it see the physically embedded shaded `1.17.1` as shipped software, or merely as a dependency of the normalizer project?

## Observe

Capture during walkthrough.

## Establish

Keep project-model knowledge separate from physical-inclusion evidence.

---

# 3. Ask Snyk about the npm source

## Question

Before Vite bundling, can Snyk identify:

```text
lodash 4.17.21
react 18.3.1
react-dom 18.3.1
```

from the npm project and lockfile?

## Observe

Capture during walkthrough.

## Establish

This is the strongest package-identity point for lodash.

---

# 4. Ask Snyk about deployable `frontend/dist`

## Question

Once only Vite output remains, can Snyk still identify lodash?

## Observe

Capture during walkthrough.

## Establish

Compare with the npm-source result.

The important distinction is:

```text
build workspace package identity
        !=
deployable bundle package identity
```

---

# 5. Scan the shaded normalizer directly

## Question

Syft identified `commons-codec 1.17.1` from the shaded JAR because Maven package metadata survived.

Can Snyk's unmanaged JAR mode do the same?

## Observe

Capture during walkthrough.

## Establish

This is a direct comparison between two artefact scanners over exactly the same custom JAR.

---

# 6. Repeat after removing Maven metadata

## Question

Does the controlled evidence-loss experiment change Snyk's result?

```text
normalizer-1.0.0.jar
    relocated codec bytecode
    + commons-codec Maven metadata

normalizer-no-codec-metadata.jar
    same relocated codec bytecode
    - commons-codec Maven metadata
```

## Observe

Capture during walkthrough.

## Establish

If Snyk gives the same answer for both, then its unmanaged identification mechanism differs materially from Syft's.

If the answer changes, record exactly which evidence it used.

---

# 7. Scan the complete Spring Boot JAR

## Question

Can direct unmanaged analysis of the custom executable JAR identify anything useful?

Then, after unpacking it, can recursive unmanaged scanning identify intact nested JARs such as:

```text
jackson-databind 2.19.4
commons-codec 1.18.0
```

Can it recover `commons-codec 1.17.1` inside the nested shaded normalizer?

Can it recover lodash from the packaged static frontend bundle?

## Observe

Capture during walkthrough.

## Establish

Compare:

```text
custom top-level application archive
intact nested dependency JARs
transformed shaded bytes
bundled JavaScript bytes
```

---

# 8. Compare every evidence view

## Run

```bash
./scripts/compare-s01.sh
```

Complete this matrix from actual output:

| Evidence view | Jackson 2.19.4 | codec 1.17.1 shaded | codec 1.18.0 | lodash 4.17.21 |
| --- | --- | --- | --- | --- |
| Maven module resolution | ? | ? | ? | n/a |
| npm source/lockfile | n/a | n/a | n/a | ? |
| Maven CycloneDX | ? | ? | ? | no |
| Syft normalizer | n/a | yes | n/a | n/a |
| Syft stripped normalizer | n/a | no | n/a | n/a |
| Syft frontend/dist | n/a | n/a | n/a | no |
| Syft final service JAR | yes | yes | yes | no |
| Snyk Maven aggregate | ? | ? | ? | n/a |
| Snyk Maven + provenance | ? | ? | ? | n/a |
| Snyk npm source | n/a | n/a | n/a | ? |
| Snyk frontend/dist | n/a | n/a | n/a | ? |
| Snyk shaded normalizer | n/a | ? | n/a | n/a |
| Snyk stripped normalizer | n/a | ? | n/a | n/a |
| Snyk final service JAR | ? | ? | ? | ? |
| Snyk unpacked service | ? | ? | ? | ? |

The central S01/T01 question is:

```text
Which kinds of software identity survive a transformation strongly enough
for Snyk to recover them, and which require evidence from an earlier
supply-chain boundary?
```
