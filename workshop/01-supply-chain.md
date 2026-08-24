---
id: workshop-01-supply-chain
oneliner: "What a software supply chain is, why dependency trees are only part of it, and the question the whole workshop keeps asking."
track: core
status: placeholder
---

# Part 1 — Supply-Chain Fundamentals

> **PLACEHOLDER** — presentation content to be written. Outline and timing
> below are the working plan from the transformation TODO.

**Target duration:** 15 min presentation

## Planned content

- **While-you-listen machine check** (first slide): attendees run
  `./scripts/tools-check.sh`, fix what it reports, then
  `./scripts/build-all.sh`. Broken machines get fixed here, during talk time,
  not during the S01 exercise.
- Define a software supply chain as more than dependencies: development,
  selection, testing, integration, build, repositories, deployment,
  maintenance, security, support, EOL.
- Every dependency brings decisions made by other people.
- Single application diagram: our source, Maven deps, transitives, npm
  packages, build plugins, build tools, JDK/runtime, container base, OS
  packages.
- The opening question: *Can you tell me exactly what software this
  application contains?*
- Why we care: vulnerability matching, remediation, compliance, audit,
  customer evidence, cyber insurance.
- Verify or drop the "10% own code / 90% dependencies" and "150 deps per
  application" claims before use.
