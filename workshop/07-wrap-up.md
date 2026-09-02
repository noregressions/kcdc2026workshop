---
id: workshop-07-wrap-up
oneliner: "End-to-end supply chain evidence model, operational verification procedures, and implementation checklist."
track: core
status: planned
---

# Part 7: Synthesis and Operational Architecture

**Target duration:** 10 minutes

## Complete Supply Chain Evidence Pipeline

Component observation requires evaluating state across all boundary transitions:

```text
1. Source Declaration        (Manifests, POMs, package.json)
         |
2. Dependency Resolution      (Lockfiles, effective POMs, resolution graphs)
         |
3. Build Execution           (Plugin realms, lifecycle scripts, PEP 517 backends)
         |
4. Artifact Packaging        (Shaded JARs, frontend bundles, compiled wheels)
         |
5. Containerization          (Base images, system packages, runtime environments)
         |
6. Cryptographic Provenance  (Digests, SBOM attestations, Cosign signatures)
```

## Security and Operational Data Overlay

- **Vulnerability Data (CVE / NVD / OSV):** Point-in-time defect records requiring exact identity matching.
- **Exploitation Intelligence (CISA KEV):** Verified exploitation status independent of catalogue publication dates.
- **Repository Health (OpenSSF Scorecard):** Observable engineering practices and CI/CD security hygiene.
- **Lifecycle / EOL (OpenEoX / Support Datasets):** Upstream maintenance availability and patch commitment windows.

## Implementation Verification Checklist

1. **Differential SBOM Generation:** Generate CycloneDX SBOMs via build resolver and artifact scanner (Syft), then diff results to identify transformed or stripped components.
2. **CPE Matching Audit:** Trace active scanner findings back to exact vendor/product/version CPE syntax to verify applicability against custom or backported builds.
3. **Lifecycle Horizon Audit:** Map all runtime framework and library versions against official EOL dates to identify unsupported components.
4. **Practice Metrics Verification:** Run OpenSSF Scorecard against critical direct dependencies to evaluate repository update hygiene.
5. **Lockfile Integrity Verification:** Audit lockfile package definitions against upstream registry hashes and verify registry source endpoints.
