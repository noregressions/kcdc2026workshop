---
id: workshop-03-vulnerabilities
oneliner: "The vulnerability pipeline, the Tomcat CVE/CPE worked example and timeline, and why a CVE is an evolving record rather than a fact."
track: core
status: placeholder
---

# Introduction

> **PLACEHOLDER** — presentation content to be written. Outline and timing
> below are the working plan from the transformation TODO.

**Target duration:** 35 min presentation + guided web investigation

## Planned content

- Framing source: the foojay.io article *The Real Mechanics of
  Vulnerabilities in an Upstream/Downstream, Topsy-Turvy EOL World*: the
  delta model (forks/embeddings/repackagings, not a single river), "a CVE is
  not a demand for a patch", and silence as the real exposure. The
  presentation narrates the model; the investigation proves it from data.
- Pipeline diagram: software → identity → mapping → CVE record → affected
  versions → scanner matching → finding. Every arrow can fail.
- Tomcat 8.5 worked example — **built**: `investigations/CVE-tomcat-85`
  (Ghostcat: CNA record, NVD analysis, CPE config, 57 edits over six years,
  KEV, and the EOL comparison with CVE-2025-24813). The presentation frames
  it; the investigation is the guided web/API part.
- CPE properly: version ranges; forks, embeddings and repackaging; which
  variant the CVE/CPE relationship actually describes.
- Short OpenSSL counter-example (under 5 minutes).
- CVE lifecycle: a CVE is not a point-in-time fact.
- Closing exercise: what exactly had to be true for this scanner to produce
  this finding?

**BREAK follows this part**: the boundary between discovering problems and
deciding what to do about them.
