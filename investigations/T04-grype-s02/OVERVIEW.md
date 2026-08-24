---
id: t04-grype-s02-overview
oneliner: "Grype against S02: scope and how to run it."
---

# T04 — Grype / S02: Overview

One CVE tool against one supply-chain scenario.

## Scenario

```text
S02 — Payara + mvnpm
```

## Tool

Observed run:

```text
Grype 0.115.0
Syft 1.46.0
```

## Question

Does Grype produce the same vulnerability answer when the final Payara image is supplied as:

```text
1. a Docker image for direct discovery
2. a Syft JSON SBOM
3. a CycloneDX SBOM
```

## Run

```bash
./scripts/baseline-s02.sh
./scripts/run-grype-s02.sh
./scripts/compare-s02.sh
```

If Grype reports an invalid database, refresh it first:

```bash
grype db update
grype db status
```

The observed successful run used a valid database built on 22 August 2026.

## Canonical result

```text
direct image     169 unique vulnerability matches
Syft JSON        169 unique vulnerability matches
CycloneDX        169 unique vulnerability matches

all exact match-set diffs: empty
```

S02 also proves that `lodash-es 4.17.21` participates in the Maven plugin realm but is not identifiable in the final image inventory.

See `TRACE.md` for the complete evidence chain.
