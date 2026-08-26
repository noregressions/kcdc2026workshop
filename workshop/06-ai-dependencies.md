---
id: workshop-06-ai-dependencies
oneliner: "AI coding tools are growing your dependency tree, picking poor libraries, and inventing packages, and attackers have learned to publish the inventions."
track: core
status: placeholder
---

# Introduction

> **PLACEHOLDER** — presentation and demo content to be built. Outline and
> timing below are the working plan.

**Target duration:** 20 min presentation + demo

## Planned content

- **AI coding tools quietly change your dependency profile**: larger trees,
  transitively heavier picks, libraries chosen for training-data popularity
  rather than health. (Evidence base to be assembled: verify and source
  every claim before presenting.)
- **Hallucinated packages**: models confidently import packages that do not
  exist, and the same names get hallucinated repeatedly.
- **Slopsquatting**: attackers register the hallucinated names with real,
  malicious packages. The hallucination becomes an install.
- **Dissect AI-generated malware**: a real sample, taken apart live.
  (Sample and safe-handling approach to be chosen; must run isolated,
  never on attendee machines.)
- Tie back to Part 2: an AI-suggested dependency is still a dependency.
  Same evidence boundaries, same identification problems, but adopted
  with less scrutiny and at higher volume.
- Tie back to Part 5: every ingress control just discussed now has a new,
  high-volume, low-scrutiny source of requests.

## Fixed conclusions

```text
An AI-suggested dependency enters the same supply chain
with less human scrutiny.

A hallucinated package name is free attack surface —
someone will register it before your model stops suggesting it.
```
