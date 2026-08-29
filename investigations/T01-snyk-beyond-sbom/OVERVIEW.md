---
id: t01-snyk-beyond-sbom-overview
oneliner: "Snyk across all five scenarios: scope, the ground truth it starts from, and the scripts that produce each run."
track: instructor-demo
---

# T01 — Snyk Beyond the SBOM: Overview

> **Workshop track: INSTRUCTOR DEMO** — shown live during the workshop against S04 ground truth. You don't need to run it yourself; the per-scenario traces are reference material.

T01 is an **investigation** over S04 rather than another synthetic supply-chain scenario.

It starts from known S04 ground truth:

```text
Maven project dependency tree     → plugin/payload absent
Maven-model CycloneDX             → plugin/payload absent
Maven plugin resolver             → plugin + payload visible
Maven plugin ClassRealm           → plugin + payload visible
final application JAR             → generated behaviour present
Syft final-JAR scan               → application archive only
```

T01 asks:

> Can Snyk recover anything material about the missing build plugin, its transitive payload, or their provenance?

## Result from Snyk CLI 1.1305.2

```text
Snyk normal Maven test
    → root application only
    → plugin/payload not recovered

Snyk Maven test --include-provenance
    → adds Maven PURL to root project identity
    → plugin/payload still not recovered

Snyk CycloneDX
    → root application metadata
    → zero dependency components
    → plugin/payload not recovered

Snyk CycloneDX --include-provenance
    → no substantive change
    → only run timestamp and serial UUID differ

Snyk unmanaged final-JAR scan
    → sees the custom JAR as an unknown artefact
    → warns some dependencies cannot be identified
    → does not recover plugin/payload identity
```

The main finding is:

```text
better metadata about known software
        !=
broader supply-chain coverage
```

The build-plugin facts remain visible in Maven's plugin-resolution and execution evidence, not in the application dependency model, the SBOMs, or the final-JAR package identification.

## Layout

Recommended:

```text
investigations/
  T01-snyk-beyond-sbom/

scenarios/
  S04-maven-plugin-hidden-content/
```

Scripts look for S04 at:

```text
../../scenarios/S04-maven-plugin-hidden-content
```

or use:

```bash
S04_DIR=/path/to/S04-maven-plugin-hidden-content ./scripts/baseline.sh
```

## Requirements

- completed S04
- Maven 3.9+
- JDK 21+
- Snyk CLI authenticated
- jq
- Syft for the baseline scanner comparison

## Reproduce

```bash
./scripts/baseline.sh
./scripts/run-snyk.sh
./scripts/compare.sh
```

## Proof check

```bash
./scripts/proof-check.sh
```

The proof reruns the investigation and asserts the observed evidence boundaries.

See `TRACE.md` for the complete evidence walkthrough.


## Cross-lab investigation status

T01 is intentionally broader than S04.

```text
S04 Maven plugin hidden-content    completed
S02 Payara + mvnpm                 completed walkthrough
S01 Spring + Node                  completed walkthrough
S03 Python + PEP 517               completed walkthrough
S05 Node + npm prepack             next
```

### Run the S02 investigation

```bash
./scripts/baseline-s02.sh
./scripts/run-snyk-s02.sh
./scripts/compare-s02.sh
```

See `S02-TRACE.md` for the S02-specific evidence questions.

The S02 investigation adds a positive control: Snyk scans the original `commons-lang3` JAR extracted from the WAR. We then compare that with `lodash-es`, whose code survived only after being transformed into browser JavaScript.

### Run the S03 investigation

```bash
./scripts/baseline-s03.sh
./scripts/run-snyk-s03.sh
./scripts/compare-s03.sh
```

See `S03-TRACE.md` for the Python/PEP 517 evidence questions.

S03 deliberately does not use `--include-provenance`: Snyk currently documents that experimental option for Maven artefacts. The Python investigation instead tests the supported Pip model: `requirements.txt` plus an installed environment, then compares that package inventory with the separate pip/PEP 517 execution evidence.



### Run the S05 investigation

```bash
./scripts/baseline-s05.sh
./scripts/run-snyk-s05.sh
./scripts/compare-s05.sh
```
