---
id: t01-s05-node-prepack
oneliner: "Snyk against S05, from package source through the packed tarball to the installed package."
---

# T01 / S05 — Snyk Against npm `prepack`

This is the final scenario case inside **T01 — Snyk Beyond the SBOM**.

```text
trace-route-package source
    package.json
    build-input/route.json
    scripts/generate-dist.js
        ↓ npm pack / prepack
    dist/index.js
    dist/prepack-evidence.json
        ↓ files=[dist]
published tarball
    package.json + dist
    generator absent
    build input absent
        ↓ npm install
node_modules/trace-route-package
```

The question is: **Can Snyk identify the installed npm package while preserving the publication-time fact that `prepack` executed and manufactured the runtime files?**

`package inventory != publication history`

## Run

```bash
./scripts/baseline-s05.sh
./scripts/run-snyk-s05.sh
./scripts/compare-s05.sh
```

The harness compares source, npm-pack evidence, packed tarball, installed package, npm SBOM, Snyk application dependency analysis, Snyk CycloneDX, and direct scans of source/published/installed package forms.
