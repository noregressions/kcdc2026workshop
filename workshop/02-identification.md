---
id: workshop-02-identification
oneliner: "Practical evaluation of software identifiability: build transformations (S01), plugin execution (S04), lifecycle hooks (S05), build backends (S03), and scanner visibility limits (T01)."
track: core
status: planned
---

# Part 2: Software Identifiability Across Boundaries

**Target duration:** 55 minutes

## Modules and Objectives

1. **S01 — Build Transformations and Metadata Stripping (15 min):**
   - Control: Standard Maven dependency resolution (`jackson-databind`) verified across resolver, artifact bytecode, and SBOM metadata.
   - Bytecode Shading: Relocating `commons-codec` into application namespaces and observing detection failure when Maven metadata is removed.
   - Frontend Bundling: Vite/esbuild bundling of `lodash`, eliminating individual package boundaries from static artifact inspection.

2. **S04 — Maven Plugin Execution Realms (15 min):**
   - Demonstration of runtime endpoint injection (`trace-route-payload`) via build-time plugin execution (`trace-injector-maven-plugin`).
   - Comparison of empty application `dependency:tree` against actual compiled classes in the target JAR.

3. **S05 — npm Package Lifecycle Hooks (8 min):**
   - Tarball generation via `prepack` lifecycle scripts executing before artifact packaging.
   - Contrast between declared repository source files and packaged distributable artifacts.

4. **S03 — Python PEP 517 Build Backends (8 min):**
   - Package construction during `pip install` via dynamic PEP 517 build backends in source distributions.
   - Comparison of source distribution contents against installed `site-packages` runtime structures.

5. **T01 — Commercial SCA Capabilities and Boundary Limits (5 min):**
   - Evaluation of advanced scanner analysis against S04 ground truth.
   - Demonstration that algorithmic analysis cannot synthesize metadata destroyed or omitted prior to artifact generation.

6. **Synthesis — The Evidence Boundary Matrix:**
   - Systematic classification of what each evidence source (Manifest, Resolver, SBOM, Artifact Scanner, Container Scanner) detects versus what it systematically omits.
