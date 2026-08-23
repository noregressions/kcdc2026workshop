# T06 — OWASP Dependency-Check / S04

## Scenario

```text
S04 — Maven plugin hidden content
```

## Tool

Observed successful run:

```text
OWASP Dependency-Check Maven Plugin 13.0.0
NVD_API_KEY supplied
```

## Core result

The same Dependency-Check engine produced radically different inventories
depending on which Maven evidence domain was admitted:

```text
default Maven scan
    0 dependencies
    0 vulnerability records

plugin-aware Maven scan
    167 dependencies
    78 vulnerability records
    trace-injector-maven-plugin
    trace-route-payload

final application JAR
    1 dependency
    application archive only

direct plugin/payload JARs
    2 dependencies
    trace-injector-maven-plugin
    trace-route-payload
```

The final JAR still contains the generated `/hidden/build-info` runtime
behaviour, but the original build-time package identities are no longer
recoverable from that artefact.

## Run

```bash
export NVD_API_KEY='your-key-here'

./scripts/baseline-s04.sh
./scripts/run-dependency-check-s04.sh
./scripts/compare-s04.sh
./scripts/proof-check.sh
```

See `TRACE.md` for the complete evidence chain and NVD key setup instructions.
