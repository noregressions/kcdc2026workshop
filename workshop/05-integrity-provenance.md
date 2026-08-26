---
id: workshop-05-integrity-provenance
oneliner: "The same build mechanisms used maliciously, and the three defensive controls: ingress, integrity, provenance."
track: core
status: placeholder
---

# Introduction

> **PLACEHOLDER** — presentation content to be written. Outline and timing
> below are the working plan from the transformation TODO.

**Target duration:** 25 min presentation + hands-on (was 35; the malware dissection moved to Part 6)

## Planned content

- Reframe S03/S04/S05: everything shown so far can be done maliciously:
  plugin execution, lifecycle scripts, build backends, dependency confusion,
  typosquatting, compromised releases.
- **Beyond metadata**: what a code-reading scanner finds that a metadata one
  cannot. Investigation `T08-guarddog` runs GuardDog against S05 and S03:
  two clean results for opposite reasons (mechanism excluded from the
  artefact vs present-but-benign), with a malicious positive control to
  prove the scanner fires. Reading code beats reading metadata; a clean
  score still is not a safety proof. (Dynamic behaviour analysis, running
  the package in a sandbox, is the heavier tool named but not run.)
- (AI-generated malware dissection and hallucinated-package attacks moved
  to their own segment: Part 6.)
- Control 1 — controlled ingress: public ecosystem → controlled ingress →
  internal repository → build.
- Integrity lab (S06, to be built): corrupt a cached Maven artefact, watch
  the build, add verification (10 minutes).
- Control 2 — reverse provenance (**S07, built**:
  `scenarios/S07-provenance-s01`): reuse S01's image, fail to trace it home,
  then add provenance in four layers, git → OCI labels → SBOM → attestation,
  re-auditing after each. The lesson is the ladder: an embedded commit is a
  claim anyone can fake; only the cosign-signed attestation is verifiable by
  someone who does not trust your build. SLSA/keyless (Fulcio/Rekor) named as
  the production form of the same mechanics.
- The three controls: control what comes in, verify the bytes, preserve
  evidence of how they were produced.
