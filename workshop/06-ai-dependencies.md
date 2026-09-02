---
id: workshop-06-ai-dependencies
oneliner: "Impact of AI-generated dependencies on supply chain expansion, package hallucination vectors, and automated code vetting."
track: core
status: planned
---

# Part 6: AI Tooling and Automated Dependency Ingress

**Target duration:** 20 minutes (technical presentation and malware analysis)

## Technical Analysis

1. **Dependency Profile Shift Under LLM Code Generation:**
   - Expansion of transitive dependency graph depth and package volume.
   - Selection bias toward training set frequency rather than project health, active maintenance, or minimal surface area.

2. **Package Hallucination and Namespace Squatting:**
   - Mechanism: Generative language models predict synthetic package names across ecosystem namespaces (npm, PyPI).
   - Exploitation vector: Registration of predicted package identifiers with malicious payloads.
   - Ingress point: Automated developer tooling executing `npm install` or `pip install` on generated manifests.

3. **Analysis of AI-Generated Malware Fixtures:**
   - Technical dissection of malicious code generation patterns, evasion techniques, and execution triggers.
   - Isolation requirements: Execution within dedicated non-networked containment sandboxes.

4. **Integration with Defensive Supply Chain Controls:**
   - AI-suggested dependencies traverse identical supply chain boundaries (resolution, transformation, runtime packaging) and require the ingress controls established in Part 5.

## Technical Architecture Summary

```text
1. Automated code generation increases dependency ingress velocity.
2. Unregistered hallucinated package identifiers create preemptive registration attack surfaces.
3. Ingress controls, private registries, and explicit pinning must precede automated resolution.
```
