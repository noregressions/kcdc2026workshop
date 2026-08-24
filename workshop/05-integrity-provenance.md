---
id: workshop-05-integrity-provenance
oneliner: "The same build mechanisms used maliciously, and the three defensive controls: ingress, integrity, provenance."
track: core
status: placeholder
---

# Part 5 — What If Someone Exploits the Gaps?

> **PLACEHOLDER** — presentation content to be written. Outline and timing
> below are the working plan from the transformation TODO.

**Target duration:** 35 min presentation + hands-on

## Planned content

- Reframe S03/S04/S05: everything shown so far can be done maliciously —
  plugin execution, lifecycle scripts, build backends, dependency confusion,
  typosquatting, compromised releases.
- Control 1 — controlled ingress: public ecosystem → controlled ingress →
  internal repository → build.
- Integrity lab (S06, to be built): corrupt a cached Maven artefact, watch
  the build, add verification — 10 minutes.
- Control 2 — reverse provenance (S07, to be built): which repo, commit,
  build, dependencies? Where ordinary metadata stops; SLSA conceptually.
- The three controls: control what comes in, verify the bytes, preserve
  evidence of how they were produced.
