---
id: cheatsheet-part2-t01
oneliner: "The T01 scanner test that closes Part 2: what a commercial SCA tool sees that an SBOM does not."
track: reference
---

# T01 — Snyk beyond the SBOM

**Proving:** A commercial scanner against S04 ground truth. Analysis cannot reconstruct evidence the build never produced.

Question: what does a commercial SCA tool know that an SBOM does not, and which transformations stay invisible even to it?
Needs: Maven 3.9+, JDK 21+, `jq`, Syft, and an authenticated Snyk CLI. S01 to S05 built.

```command
cd investigations/T01-snyk-beyond-sbom
```

Log in once; every run snyk script should start by recording `snyk --version`.
```command
snyk auth
```

**S04, the live demo**

Capture Maven's dependency tree, plugin resolution, plugin ClassRealm, CycloneDX and a Syft JAR scan. Writes results/baseline/.
```command
./scripts/baseline.sh
```
```output
Maven application dependency tree:  application only
Maven CycloneDX:                    0 dependency components
Syft final-JAR scan:                application archive only
Included: dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
Included: dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

Five Snyk views: Maven test, test + --include-provenance, CycloneDX SBOM, SBOM + provenance, unmanaged JAR. Writes results/snyk/.
```command
./scripts/run-snyk.sh
```
Snyk Maven test identifies the application only. The plugin and payload are absent. Provenance adds a PURL to the root artefact and nothing else. The unmanaged JAR scan reports:
```text
unknown
```

Grep every baseline and Snyk file for the plugin, payload and app names, then print the five discussion prompts.
```command
./scripts/compare.sh
```
```output
Interpretation questions:
  1. Does normal Snyk Maven analysis expose plugin or payload?
  2. Does Snyk's SBOM expose either?
  3. Does --include-provenance change the visible evidence?
  4. Can unmanaged JAR analysis identify anything useful?
  5. Which S04 ground-truth facts remain visible only in Maven's plugin domain?
```

**S01, S02, S03, S05 reference runs**

S01: Maven reactor, npm, bundle, and unmanaged JAR views. Also builds an isolated Maven repo for provenance mode.
```command
./scripts/baseline-s01.sh && ./scripts/run-snyk-s01.sh && \
  ./scripts/compare-s01.sh
```

S02: Maven test with/without provenance, CycloneDX, unmanaged WAR, unpacked WAR.
```command
./scripts/baseline-s02.sh && ./scripts/run-snyk-s02.sh && \
  ./scripts/compare-s02.sh
```

S03: pip test, pip CycloneDX, then project discovery on the sdist, wheel and site-packages.
```command
./scripts/baseline-s03.sh && ./scripts/run-snyk-s03.sh && \
  ./scripts/compare-s03.sh
```

S05: npm test, npm CycloneDX, then project scans of source, unpacked tarball and installed package.
```command
./scripts/baseline-s05.sh && ./scripts/run-snyk-s05.sh && \
  ./scripts/compare-s05.sh
```

What each shows:

- **S01.** Maven scan finds `commons-codec 1.17.1` under normalizer and `1.18.0` plus `jackson-databind 2.19.4` under service. `--include-provenance` keeps the same set and adds `?checksum=sha1:...` to each PURL. npm scan finds `lodash 4.17.21`; scanning `frontend/dist` returns `No supported files found`. Unmanaged scans of the shaded JAR, stripped JAR and Boot JAR all return `unknown`. After unpacking, Snyk recovers `commons-codec 1.18.0` and `jackson-databind 2.19.4` but never the shaded 1.17.1, even with its Maven metadata intact where Syft succeeds.
- **S02.** Maven scan finds `commons-lang3 3.18.0` and the Jakarta `provided` dependencies, not `lodash-es`. Provenance mode checksum-qualifies the Jakarta artefacts even though they never ship in the WAR. Whole WAR is `unknown custom WAR`. Unpacked WAR recovers commons-lang3; lodash-es is not identified at any boundary.
- **S03.** pip graph shows `reportkit 1.0.0 → tracehook-demo 1.0.0`, an edge `requirements.txt` never states. No Snyk output mentions `tracehook_backend`, `build_wheel` or `pep517-build-backend-executed`. The sdist, wheel and site-packages are not supported projects on their own.
- **S05.** npm scan shows `node-prepack-trace-lab 1.0.0 → trace-route-package 1.0.0`. Source, unpacked tarball and installed package all scan because each has `package.json`. No output mentions `generate-dist.js`, `npm-prepack-generated` or `/hidden/prepack-info`.

Assert 34 claims against the results/ tree written by the five triplets above.
```command
./scripts/proof-check.sh
```

Remove the whole results/ tree. Prints: T01 results removed.
```command
./scripts/clean.sh
```
```output
T01 proof check
===============
PASS  S01 Maven normalizer resolves codec 1.17.1
PASS  S01 bundled frontend has no supported Snyk project
PASS  S03 Snyk recovers transitive tracehook-demo
PASS  S04 Snyk Maven scan omits plugin payload
PASS  S05 Snyk dependency result omits generator
...
Passed: 34
Failed: 0
```

Takeaway: better package identity ≠ complete supply-chain history. Capture evidence when the transformation happens; a later scanner cannot reconstruct what the build discarded.
