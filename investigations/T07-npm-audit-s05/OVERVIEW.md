---
id: t07-npm-audit-s05-overview
oneliner: "npm audit against S05: scope and how to run it."
---

# T07 — npm audit / S05: Overview

## Scenario

```text
S05 — Node npm prepack
```

## Observed tooling

```text
Node v26.4.0
npm 12.0.1
registry https://registry.npmjs.org/
```

## Core result

S05 proves that `npm prepack` executes a generator which creates the runtime
package contents:

```text
source package
    scripts/generate-dist.js
    build-input/route.json
        ↓ npm prepack
published package
    dist/index.js
    dist/prepack-evidence.json
    package.json
```

`npm audit` does not reconstruct that lifecycle history:

```text
application
    1 dependency
    0 vulnerability records

application --package-lock-only
    1 dependency
    0 vulnerability records

source --no-package-lock
    0 dependencies
    0 vulnerability records

published --no-package-lock
    0 dependencies
    0 vulnerability records
```

A separate `lodash@4.17.21` control returned a high-severity vulnerability,
proving the audit advisory path was functioning.

No S05 audit output contained:

```text
scripts/generate-dist.js
npm-prepack-generated
prepack-evidence.json
/hidden/prepack-info
```

## Run

```bash
./scripts/baseline-s05.sh
./scripts/run-npm-audit-s05.sh
./scripts/compare-s05.sh
./scripts/proof-check.sh
```

See `TRACE.md` for the complete evidence chain.
