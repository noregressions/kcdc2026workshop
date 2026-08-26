---
id: s05-node-prepack-overview
oneliner: "An npm package that generates its own dist/ while being packed: prerequisites and how to run it."
track: core
---

# S05 — Node npm `prepack` Supply Chain Trace Lab: Overview

> **Workshop track: CORE** — part of the timed workshop route (Part 2: identification).

This scenario traces runtime code that is **generated during package creation**, rather than simply being copied from the package source tree.

```text
package source
    ↓
package.json prepack lifecycle hook
    ↓
scripts/generate-dist.js executes
    ↓
generates dist/index.js + provenance metadata
    ↓
npm pack creates trace-route-package-1.0.0.tgz
    ↓
application installs tarball
    ↓
node_modules contains generated runtime code
    ↓
GET /hidden/prepack-info
```

The package's `files` field deliberately publishes only `dist/`. The generator and its build input stay out of the tarball. This makes the source tree, lifecycle execution, packed package, installed package, inventory/SBOM views and runtime distinct evidence boundaries.

## Requirements

- Node.js 20+
- npm
- curl
- tar
- Syft for the scanner comparison
- jq for the manual walkthrough formatting

No external npm packages are required.

## Build

```bash
./scripts/build.sh
```

## Run

```bash
./scripts/run.sh
```

Defaults to port `8083`.

```bash
curl -sS http://localhost:8083/health | jq
curl -sS http://localhost:8083/hidden/prepack-info | jq
```

## Stop

```bash
./scripts/stop.sh
```

## Clean

```bash
./scripts/clean.sh
```

This removes generated and installed state, including the package's generated `dist/` directory.

## Proof check

After the walkthrough:

```bash
./scripts/proof-check.sh
```

The proof starts from the clean state, verifies `dist/` is absent before packing, exercises `prepack`, checks the tarball and installed package, validates npm/Syft evidence views, and runs the application on isolated port `18085`.

If Syft is not installed, the proof skips the Syft checks with a warning.

See `TRACE.md` for the evidence walkthrough.
