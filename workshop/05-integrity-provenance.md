---
id: workshop-05-integrity-provenance
oneliner: "Malicious build execution vectors and technical defensive controls: controlled ingress, cryptographic integrity, and signed provenance."
track: core
status: planned
---

# Part 5: Malicious Execution Vectors and Defensive Controls

**Target duration:** 25 minutes (presentation and hands-on lab)

## Threat Vectors Across Build Boundaries

The build-time execution mechanisms evaluated in Part 2 constitute execution attack surface:
- **Build Plugin ClassRealms:** Arbitrary bytecode execution during compilation phases.
- **Package Lifecycle Hooks:** Unsandboxed shell/JS execution during archive packaging (`prepack`) or dependency installation (`postinstall`).
- **Build Backends:** Dynamic code generation during wheel/sdist builds (PEP 517).
- **Ingress Vectors:** Dependency confusion, namespace typosquatting, and account takeovers.

## Code-Level Scanning vs Metadata Matching (T08 / GuardDog)

Investigation `investigations/T08-guarddog` evaluates static AST analysis against package archives:
- **S05 Tarball:** Evaluates clean (0.0/10) because `files: ["dist"]` omits the generator script that executed during packaging.
- **S03 Source Distribution:** Evaluates clean (0.0/10) because the embedded PEP 517 build backend uses standard packaging primitives.
- **Malicious Fixture Control:** Validates scanner rule activation against known malicious payload patterns.

## Defensive Controls Architecture

### 1. Controlled Ingress
Public repository isolation via artifact staging proxies with checksum verification, namespace reservation, and explicit license/policy validation.

### 2. Cache and Artifact Integrity
Validation of repository artifact digests against published checksums and immutable signature chains to detect tampering in local or remote caches.

### 3. Layered Reverse Provenance (S07)

Evaluation in `scenarios/S07-provenance-s01` builds an audit trail across four distinct verification tiers:

```text
Layer 1: Embedded build metadata (git.properties inside JAR) -> Unsigned internal claim
Layer 2: Container image annotations (OCI revision/source labels) -> Unsigned image claim
Layer 3: Cryptographic SBOM (Syft CycloneDX keyed to image digest) -> Unsigned content claim
Layer 4: Digital signatures & attestations (Cosign + in-toto predicate) -> Cryptographically verifiable proof
```

Verification requires evaluating immutable image digests against signed public key infrastructure (or keyless Sigstore/Fulcio/Rekor workflows) rather than mutable registry tags.
