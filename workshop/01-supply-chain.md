---
id: workshop-01-supply-chain
oneliner: "Software supply chain architecture, dependency resolution boundaries, and inventory identification scope."
track: core
status: planned
---

# Part 1: Supply Chain Fundamentals

**Target duration:** 15 minutes

## Technical Outline

- **Environment Verification:** Execute `./scripts/tools-check.sh` and `./scripts/build-all.sh` to initialize build caches and container images.
- **Supply Chain Architecture Scope:** Complete supply chain definition spanning source development, component selection, test execution, dependency resolution, build-time code execution, packaging transformations, repository distribution, runtime environments, and lifecycle support/EOL.
- **External Dependency Ingress:** Direct dependencies, transitive graphs, build plugins, build engines, execution runtimes (JDK/Node/Python), base images, and operating system packages.
- **Application Composition Boundary Model:**
  - Source declarations
  - Direct and transitive dependency graphs
  - Build plugin execution realms
  - Bundled/shaded application artifacts
  - Runtime and container environments
- **Core Evaluation Query:** *Can you determine the complete set of software components present in a deployed artifact?*
- **Operational Drivers:** Vulnerability correlation, patch remediation, compliance verification, provenance tracking, and security auditing.
