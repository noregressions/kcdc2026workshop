# Investigation Cheat Sheet

## Before the workshop

```bash
# From repo root: build S01–S05 and their images, warm scanner DBs, and (slow) run the T01–T07 baselines.
./scripts/build-all.sh --with-investigations
```


---

## T01 — Snyk beyond the SBOM

Question: what does a commercial SCA tool know that an SBOM does not, and which transformations stay invisible even to it?
Needs: Maven 3.9+, JDK 21+, `jq`, Syft, and an authenticated Snyk CLI. S01 to S05 built.

```bash
cd investigations/T01-snyk-beyond-sbom

# Log in once; every run snyk script should start by recording `snyk --version`.
snyk auth
```

**S04, the live demo**

```bash
# Capture Maven's dependency tree, plugin resolution, plugin ClassRealm, CycloneDX and a Syft JAR scan. Writes results/baseline/.
./scripts/baseline.sh
```
```text
Maven application dependency tree:  application only
Maven CycloneDX:                    0 dependency components
Syft final-JAR scan:                application archive only
Included: dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
Included: dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

```bash
# Five Snyk views: Maven test, test + --include-provenance, CycloneDX SBOM, SBOM + provenance, unmanaged JAR. Writes results/snyk/.
./scripts/run-snyk.sh
```
Snyk Maven test identifies the application only. The plugin and payload are absent. Provenance adds a PURL to the root artefact and nothing else. The unmanaged JAR scan reports:
```text
unknown
```

```bash
# Grep every baseline and Snyk file for the plugin, payload and app names, then print the five discussion prompts.
./scripts/compare.sh
```
```text
Interpretation questions:
  1. Does normal Snyk Maven analysis expose plugin or payload?
  2. Does Snyk's SBOM expose either?
  3. Does --include-provenance change the visible evidence?
  4. Can unmanaged JAR analysis identify anything useful?
  5. Which S04 ground-truth facts remain visible only in Maven's plugin domain?
```

**S01, S02, S03, S05 reference runs**

```bash
# S01: Maven reactor, npm, bundle, and unmanaged JAR views. Also builds an isolated Maven repo for provenance mode.
./scripts/baseline-s01.sh && ./scripts/run-snyk-s01.sh && ./scripts/compare-s01.sh

# S02: Maven test with/without provenance, CycloneDX, unmanaged WAR, unpacked WAR.
./scripts/baseline-s02.sh && ./scripts/run-snyk-s02.sh && ./scripts/compare-s02.sh

# S03: pip test, pip CycloneDX, then project discovery on the sdist, wheel and site-packages.
./scripts/baseline-s03.sh && ./scripts/run-snyk-s03.sh && ./scripts/compare-s03.sh

# S05: npm test, npm CycloneDX, then project scans of source, unpacked tarball and installed package.
./scripts/baseline-s05.sh && ./scripts/run-snyk-s05.sh && ./scripts/compare-s05.sh
```

What each shows:

- **S01.** Maven scan finds `commons-codec 1.17.1` under normalizer and `1.18.0` plus `jackson-databind 2.19.4` under service. `--include-provenance` keeps the same set and adds `?checksum=sha1:...` to each PURL. npm scan finds `lodash 4.17.21`; scanning `frontend/dist` returns `No supported files found`. Unmanaged scans of the shaded JAR, stripped JAR and Boot JAR all return `unknown`. After unpacking, Snyk recovers `commons-codec 1.18.0` and `jackson-databind 2.19.4` but never the shaded 1.17.1, even with its Maven metadata intact where Syft succeeds.
- **S02.** Maven scan finds `commons-lang3 3.18.0` and the Jakarta `provided` dependencies, not `lodash-es`. Provenance mode checksum-qualifies the Jakarta artefacts even though they never ship in the WAR. Whole WAR is `unknown custom WAR`. Unpacked WAR recovers commons-lang3; lodash-es is not identified at any boundary.
- **S03.** pip graph shows `reportkit 1.0.0 → tracehook-demo 1.0.0`, an edge `requirements.txt` never states. No Snyk output mentions `tracehook_backend`, `build_wheel` or `pep517-build-backend-executed`. The sdist, wheel and site-packages are not supported projects on their own.
- **S05.** npm scan shows `node-prepack-trace-lab 1.0.0 → trace-route-package 1.0.0`. Source, unpacked tarball and installed package all scan because each has `package.json`. No output mentions `generate-dist.js`, `npm-prepack-generated` or `/hidden/prepack-info`.

```bash
# Assert 34 claims against the results/ tree written by the five triplets above.
./scripts/proof-check.sh

# Remove the whole results/ tree. Prints: T01 results removed.
./scripts/clean.sh
```
```text
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

---

## T02 — Docker Scout: what does the final container know? (S01, S02)

Question: once the image is built, what identity can Scout recover from it, and what history is already gone?
Needs: Docker Desktop with Scout, `docker login`, `jq`. S01 and S02 images are rebuilt by the baselines.

```bash
cd investigations/T02-docker-scout

# Confirm Scout is available and the CLI is authenticated.
docker scout version
```

**S01 image**

```bash
# Rebuild the S01 image via the scenario's image-trace and record its digest and labels. Writes results/s01/baseline/.
./scripts/baseline-s01.sh
```
```text
registry.example.com/checkout-service:release-123
sha256:<digest>
179 packages        (Syft, second witness)
837 executables
```

```bash
# Run quickview, sbom --format list, cves (filtered to the tracers) and recommendations against local://<image>. Writes results/s01/scout/.
./scripts/run-scout-s01.sh
```
```text
237 packages indexed
base image: eclipse-temurin:21-jre-jammy
provenance obtained from attestation
policy: FAILED (3/7)
health score: D (44%)

commons-codec      1.17.1
commons-codec      1.18.0
jackson-databind   2.19.4
normalizer         1.0.0
lodash 4.17.21     (not identified)

jackson-databind 2.19.4
    2 HIGH
    3 MEDIUM
```
Provenance shows the repo URL and source commit. Syft saw 179 packages, Scout 237, same image.

```bash
# Print the Scout summary, tracer identities and tracer CVEs, then ten interpretation questions.
./scripts/compare-s01.sh
```

**S02 image**

```bash
# Rebuild the Payara image and record its digest and labels. Writes results/s02/baseline/.
./scripts/baseline-s02.sh

# Same four Scout views on local://payara-mvnpm-trace-lab:local, filtered to commons-lang3, lodash-es, jakarta and payara. Writes results/s02/scout/.
./scripts/run-scout-s02.sh
```
```text
655 packages indexed
base image: payara/server-web:7.2026.7
provenance obtained from attestation

commons-lang3 3.18.0
many Jakarta APIs
many Payara/GlassFish modules
lodash-es 4.17.21     (not identified)

No vulnerable packages detected
No recommendations
```
Jakarta is back in the inventory, but as Payara's packages, not the WAR's.

```bash
# Print the S02 answers and a fixed interpretation block.
./scripts/compare-s02.sh

# Assert six claims: the three Java tracers seen, lodash not recovered, provenance obtained, commons-lang3 seen.
./scripts/proof-check.sh
```
```text
T02 Docker Scout proof check
============================
PASS  S01 Scout identifies commons-codec
PASS  S01 Scout identifies jackson-databind
PASS  S01 Scout identifies normalizer
PASS  S01 Scout does not recover bundled lodash
PASS  S01 Scout obtains provenance attestation
PASS  S02 Scout identifies commons-lang3

Passed: 6
Failed: 0
```

Takeaway: a container is a different evidence boundary. Moving later adds runtime and OS software but does not recover identity lost by bundling. Same artefact boundary ≠ same inventory across scanners.

---

## T03 — Trivy across S01 boundaries

Question: does the vulnerability answer change when the same software is observed as a POM, a JAR, a bundle, or an image?
Needs: Trivy, `jq`, Docker, `zip`, Maven, npm. Trivy mode matters: `fs` for models and dist, `rootfs` for staged JARs, `image --image-src docker` for the image.

```bash
cd investigations/T03-trivy-s01

# Build S01 clean, create the metadata-stripped normalizer, build the image, capture Maven/npm/jar/Syft ground truth. Writes results/s01/baseline/.
./scripts/baseline-s01.sh
```
```text
normalizer -> commons-codec 1.17.1
service    -> jackson-databind 2.19.4, normalizer 1.0.0 -> commons-codec 1.18.0 (version managed from 1.17.1)
checkout-trace-frontend@1.0.0 -> lodash@4.17.21
```

```bash
# trivy fs on the two POMs, package-lock and frontend/dist, plus trivy image on the container. Writes results/s01/trivy/<label>.*
./scripts/run-trivy-nonarchives-s01.sh

# Stage each JAR (shaded, stripped, Boot) in an isolated dir and scan with trivy rootfs. Same output layout.
./scripts/run-trivy-archives-s01.sh

# Or run all eight probes in one pass.
./scripts/run-trivy-s01.sh
```

Per boundary, the tracer identities Trivy reported:

```text
normalizer POM             commons-codec 1.17.1
service POM                jackson-databind 2.19.4 (5 CVEs: 2 HIGH, 3 MEDIUM); codec 1.18.0 NOT seen from this POM alone
package-lock               lodash 4.17.21 (3 CVEs, e.g. CVE-2026-4800)
shaded normalizer JAR      commons-codec 1.17.1
stripped normalizer JAR    normalizer 1.0.0 only; commons-codec GONE
service JAR                codec 1.17.1, codec 1.18.0, jackson-databind 2.19.4, normalizer 1.0.0
frontend/dist              Number of language-specific files num=0; nothing
container image            codec 1.17.1, codec 1.18.0, jackson-databind 2.19.4; OS Ubuntu 22.04, 143 OS packages; no lodash
```

```bash
# Print ground truth, then tracer identity and tracer CVEs for all eight boundaries, then ten questions.
./scripts/compare-s01.sh

# Assert 19 claims against results/, including "Trivy loses codec identity after Maven metadata removal".
./scripts/proof-check.sh
```
```text
T03 Trivy proof check
=====================
PASS  ...
Passed: 19
Failed: 0
```

Takeaway: a CVE scanner is downstream of identification. Break the chain at package identity and the CVE disappears while the code stays. Using the wrong scan mode is a false negative before matching even starts.

---

## T04 — Grype: inventory versus matching (S02)

Question: does Grype give a different answer when it discovers the Payara image itself versus consuming an SBOM of that image?
Needs: Grype, Syft, Docker, `jq`, `diff`. Grype refuses a stale DB (max age 5 days); `common.sh` sets `GRYPE_DB_VALIDATE_AGE=false`.

```bash
cd investigations/T04-grype-s02

# Build S02, capture Maven app tree, plugin realm, WAR contents, build the image, and write Syft JSON + CycloneDX inventories of it. Writes results/s02/baseline/.
./scripts/baseline-s02.sh
```
```text
payara-mvnpm-trace-lab:local
589 packages / 825 executables      (Syft JSON)
6014 components                     (CycloneDX)
commons-lang3 3.18.0   seen
lodash-es 4.17.21      not identified
```

```bash
# Grype three ways over one image (docker:, sbom:<syft json>, sbom:<cyclonedx>) plus two direct PURL controls. Writes results/s02/grype/.
./scripts/run-grype-s02.sh
```
```text
direct image     169 unique vulnerability matches
Syft JSON        169 unique vulnerability matches
CycloneDX        169 unique vulnerability matches

nimbus-jose-jwt 10.0.1   GHSA-xwmg-2g98-w7v9   Medium
jline-remote-telnet      GHSA-2r2c-cx56-8933   High
jackson-core 2.15.2      GHSA-r7wm-3cxj-wff9   High

pkg:maven/org.apache.commons/commons-lang3@3.18.0   no vulnerability matches
pkg:maven/org.mvnpm/lodash-es@4.17.21               no vulnerability matches
```
No tracer match anywhere. The PURL controls show the silence is a database fact for commons-lang3 and an identity loss plus database fact for lodash-es.

```bash
# Print counts and the exact diffs of the three match sets side by side.
./scripts/compare-s02.sh
```
```text
direct image vs Syft JSON    no differences
direct image vs CycloneDX    no differences
Syft JSON vs CycloneDX       no differences
```

```bash
# Assert 20 claims: inventory counts, 169 x3, identical sets, empty PURL controls, the two named GHSA findings.
./scripts/proof-check.sh
```
```text
T04 Grype proof check
=====================
PASS  Direct image scan has 169 unique vulnerability matches
PASS  Direct image and Syft JSON match sets are identical
PASS  lodash-es PURL control has no vulnerability match
...
Passed: 20
Failed: 0
```

Takeaway: representation does not change the answer; inventory does. An SBOM-driven scan can agree perfectly with a direct scan and still miss software whose identity vanished earlier. The database, and its freshness, is part of the result.

---

## T05 — pip-audit: identity, matching, and execution (S03)

Question: can a Python audit see that a PEP 517 backend ran, and can the audit itself run that backend?
Needs: pip-audit, Python 3.11+, `jq`, `tar`, `unzip`.

```bash
cd investigations/T05-pip-audit-s03

# Build S03 in a fresh venv and capture requirements, metadata, sdist listing, backend declaration, installed files and the generated marker. Writes results/s03/baseline/.
./scripts/baseline-s03.sh
```
```text
Successfully installed: reportkit-1.0.0 tracehook-demo-1.0.0
tracehook_demo/__init__.py        (installed, absent from sdist)
tracehook_demo/build-hook.json    (installed, absent from sdist)
```

```bash
# Build a local PEP 503 index, then run five audits: requirements (resolved), --no-deps, --no-deps --disable-pip, installed site-packages, CycloneDX. Writes results/s03/pip-audit/.
./scripts/run-pip-audit-s03.sh
```
```text
requirements audit          Dry run: would have audited 2 packages
                            reportkit, tracehook-demo
                            Dependency not found on PyPI and could not be audited
--no-deps                   reportkit, tracehook-demo      (still both, on pip-audit 2.10.1)
--no-deps --disable-pip     reportkit                      (transitive gone)
installed environment       pip 26.1.2, reportkit 1.0.0, tracehook-demo 1.0.0
                            pip 26.1.2  PYSEC-2026-3721 / CVE-2026-13346  fixed in 26.2
CycloneDX output            pip 26.1.2 only; reportkit and tracehook-demo absent
```

```bash
# Controlled experiment: rebuild the sdist with a backend that writes a marker on import, then audit it. Proves the audit executes packaging code.
./scripts/run-pep517-exec-probe.sh
```
```text
INFO:pip_audit._audit:Dry run: would have audited 2 packages
No known vulnerabilities found

PEP 517 execution marker:
tracehook_backend imported during pip-audit dependency resolution
```

```bash
# Print ground truth, resolution signals, the marker, all four dependency lists and the CycloneDX grep, then nine questions.
./scripts/compare-s03.sh

# Assert 21 claims against results/.
./scripts/proof-check.sh
```
```text
T05 pip-audit proof check
=========================
PASS  pip-audit dependency collection executes PEP 517 backend code
PASS  --no-deps --disable-pip excludes transitive tracehook-demo
PASS  Installed-environment audit finds PYSEC-2026-3721
...
Passed: 21
Failed: 0
```

Takeaway: package identity ≠ vulnerability coverage ≠ build history. With resolution enabled, the audit is itself an active supply-chain operation, not a static read.

---

## T06 — OWASP Dependency-Check: which dependency universe? (S04)

Question: at which boundary can Dependency-Check still identify the plugin and payload that generated S04's hidden route?
Needs: Maven, `jq`, `javap`, and an NVD API key. First run downloads about 380,000 NVD records and is slow; the cache lives in `~/.cache/kcdc-dependency-check/<version>`.

```bash
cd investigations/T06-owasp-dependency-check-s04

# Without a key the harness falls back to Dependency-Check 12.2.2; with one it uses 13.0.0.
export NVD_API_KEY='your-key-here'

# Capture Maven app tree, plugin resolution, plugin realm, generated files, JAR entries and javap strings, and copy the plugin/payload JARs as controls. Writes results/s04/baseline/ and results/s04/controls/.
./scripts/baseline-s04.sh
```
```text
dev.noregressions.trace:maven-plugin-hidden-content:jar:1.0.0          (app tree: only this)
dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0          (plugin resolution)
dev.noregressions.trace:trace-route-payload:jar:1.0.0                  (plugin resolution)
dev/noregressions/trace/s04/generated/GeneratedTraceRoute.class        (in JAR)
```

```bash
# Four probes, one engine and one NVD snapshot: default Maven scan, plugin-aware scan (-Dodc.plugins.scan=true), final JAR directory, plugin+payload JAR controls. Writes results/s04/dependency-check/<label>/.
./scripts/run-dependency-check-s04.sh
```
```text
NVD API key: supplied via NVD_API_KEY environment variable

default-maven             Dependencies: 0     Vulnerability records: 0    tracers: (none)
plugin-aware-maven        Dependencies: 167   Vulnerability records: 78   tracers: trace-injector-maven-plugin, trace-route-payload
final-jar                 Dependencies: 1     Vulnerability records: 0    tracers: maven-plugin-hidden-content only
plugin-payload-controls   Dependencies: 2     Vulnerability records: 0    tracers: both identified
```
The 78 records are build tooling: commons-beanutils 1.7.0, commons-compress 1.20, guava 16.0.1, maven-core 3.2.5, jetty 9.4.46, velocity 1.7 and others. Neither tracer itself has a match.

```bash
# Re-print ground truth, the four probe summaries, diffs between adjacent probes, and eight questions.
./scripts/compare-s04.sh

# Assert 27 claims. Note: it pins the exact counts 167 and 78, which drift with Maven version and NVD snapshot.
./scripts/proof-check.sh
```
```text
T06 Dependency-Check proof check
================================
PASS  ...
Passed: 27
Failed: 0
```

Takeaway: application graph ≠ build-tool graph ≠ plugin realm ≠ final artefact identity. Scan build tooling where its package identity still exists; the shipped JAR cannot give it back.

---

## T07 — npm audit: metadata versus bytes (S05)

Question: when prepack generates the shipped code and the generator disappears, what can `npm audit` still see?
Needs: Node 20+, npm, `tar`. Network for the registry advisory endpoint and the lodash control.

```bash
cd investigations/T07-npm-audit-s05

# Clean and build S05, then capture source files, pack log, tarball listing, the unpacked tarball, installed files and the evidence JSON. Writes results/s05/baseline/.
./scripts/baseline-s05.sh
```
```text
npm notice run trace-route-package@1.0.0 prepack
generated dist/index.js for /hidden/prepack-info
package/dist/index.js
package/package.json
package/dist/prepack-evidence.json          (no scripts/generate-dist.js, no build-input/)
```

```bash
# Eight audits: application, --package-lock-only, source pkg with/without lockfile, published pkg with/without lockfile, provenance-string grep, public lodash control. Writes results/s05/npm-audit/<probe>/.
./scripts/run-npm-audit-s05.sh
```
```text
application                     dependencyTotal=1  vulnerabilityRecords=0  exit=0
application-lock-only           dependencyTotal=1  vulnerabilityRecords=0  exit=0
source-package                  npm error code ENOLOCK  (This command requires an existing lockfile.)
source-package-no-lock          dependencyTotal=0  vulnerabilityRecords=0
published-package               npm error code ENOLOCK
published-package-no-lock       dependencyTotal=0  vulnerabilityRecords=0

scripts/generate-dist.js     not found
npm-prepack-generated        not found
prepack-evidence.json        not found
/hidden/prepack-info         not found

public-vulnerable-control       lodash  severity: high  direct  range: <=4.17.23   vulnerabilityRecords=1
```
The lodash control proves the advisory path works, so the clean S05 results are real.

```bash
# Print ground truth beside each probe's exit and summary, FOUND / not found per provenance string, and eight questions.
./scripts/compare-s05.sh

# Assert 33 claims: prepack ran, tarball contents, each probe's exit and counts, lodash record, no provenance string in any output.
./scripts/proof-check.sh
```
```text
T07 npm audit proof check
========================
PASS  npm prepack executed
PASS  published tarball excludes generator implementation
PASS  lodash control returns one vulnerability record
PASS  npm audit output omits provenance string: /hidden/prepack-info
...
Passed: 33
Failed: 0
```

Takeaway: `npm audit` is vulnerability analysis over dependency metadata. Source and published packages look identical to it, and a clean result says nothing about how the shipped bytes were produced.

---

## T08 — GuardDog: reading code, not metadata (S05, S03, malicious variants)

Question: when a scanner reads the code, does a clean result mean safe, or only that nothing detectable was in the bytes it was handed?
Needs: `pipx install guarddog` (3.2.0, Python 3.11), `tar`. Every command passes `--no-sandbox`; that lowers isolation, not detection. S05 and S03 built. No Java ecosystem, so S04 is out of scope.

```bash
cd investigations/T08-guarddog

# Calibration: write a deliberately malicious npm package (never installed) and scan it, so a later 0.0 means "nothing matched", not "nothing ran". Writes results/control/.
./scripts/positive-control.sh
```
```text
execution-risk: found 1 indicator
│ * threat.process.spawn
│   Detects download-and-execute patterns: fetching a remote file then executing it
│   at index.js:3
Assessment:  High risk  (8.2/10)
```

```bash
# Scan the S05 published tarball. The prepack generator was excluded by files:["dist"], so there is no mechanism to judge. Writes results/s05/.
./scripts/scan-s05.sh
```
```text
package/dist/index.js
package/package.json
package/dist/prepack-evidence.json

No risks found in trace-route-package-1.0.0.tgz
Assessment:  No risks detected  (0.0/10)
```

```bash
# Scan the S03 sdist. The PEP 517 backend does ship and is benign; every rule ran and returned empty. Writes results/s03/ including scan.json.
./scripts/scan-s03.sh
```
```text
tracehook_demo-1.0.0/pyproject.toml
tracehook_demo-1.0.0/tracehook_backend.py

No risks found in tracehook_demo-1.0.0.tar.gz
Assessment:  No risks detected  (0.0/10)
```

```bash
# Build both malicious S05 variants (payload aimed at an unresolvable .invalid host), then scan A's tarball, A's source, and B's tarball. Writes results/malicious/.
./scripts/scan-malicious.sh
```
```text
== Case A — published tarball (payload was in the un-shipped generator) ==
No risks found in CASE-A-generator-payload.tgz
Assessment:  No risks detected  (0.0/10)

== Case A — SOURCE (the generator is present here) ==
│ * threat.process.spawn   at scripts/generate-dist.js:9
Assessment:  High risk  (8.2/10)

== Case B — published tarball (payload rode into the shipped dist) ==
│ * threat.process.spawn   at package/dist/index.js:4
Assessment:  High risk  (8.2/10)
```
Payload in the generator hits the publisher and the tarball scan misses it. Payload in the generated output hits the consumer and the tarball scan catches it.

```bash
# Assert ten claims against results/: the two clean scans, tarball contents, control fired, A-tarball clean, A-source and B-tarball caught.
./scripts/proof-check.sh
```
```text
T08 GuardDog proof check
========================
PASS  S05 published tarball scans clean
PASS  S05 tarball excludes the generator itself
PASS  S03 sdist DOES carry the executable build backend
PASS  positive control is flagged High risk
PASS  case A published tarball is clean (generator payload not shipped)
PASS  case A source is caught (generator present)
PASS  case B published tarball is caught (payload rode into shipped dist)
...
Passed: 10
Failed: 0
```

Takeaway: reading code beats reading metadata, and a clean score still is not a safety proof. "No risk detected" covers absent evidence, benign evidence, and an attack in the half you did not scan. Only the artefact contents tell you which.

---

## CVE-2020-1938 "Ghostcat": anatomy of an evolving record (Part 3 core)

Question: what had to be true for a scanner to produce a finding from this record, and was that the same in 2020, 2022 and 2026?
Needs: `curl`, `jq`. `NVD_API_KEY` optional, raises rate limits only. No build, no Docker. Offline: skip the `curl` lines and run the `jq` lines against the captured files in `evidence/` (captured 2026-08-24).

```bash
cd investigations/CVE-tomcat-85

# Refresh all four captures at once (cve.org, NVD record, NVD history, NVD record for CVE-2025-24813). Prints the capture date to put in evidence/CAPTURED.md.
./scripts/fetch-evidence.sh
```

**The CNA record**

```bash
# Fetch what Apache, the CNA, actually claimed; everything downstream derives from this.
curl -sS https://cveawg.mitre.org/api/cve/CVE-2020-1938 -o evidence/cve-org.json

# Who published it and when it was last touched.
jq -r '.cveMetadata | {datePublished, dateUpdated, assignerShortName}' evidence/cve-org.json

# Which branches the CNA lists as affected.
jq -r '.containers.cna.affected[] | .versions[] | [.version, .status] | @tsv' evidence/cve-org.json
```
```text
"datePublished": "2020-02-24T21:19:18.000Z"
"dateUpdated":   "2025-10-21T23:35:50.835Z"
"assignerShortName": "apache"

Apache Tomcat 9.0.0.M1 to 9.0.0.30    affected
8.5.0 to 8.5.50                       affected
7.0.0 to 7.0.99                       affected
```
Three branches. No Tomcat 6.x, no embedding products. Apache rated it Important.

**What NVD added**

```bash
# Fetch NVD's enrichment of the same CVE: severity, CWE, CPE configurations.
curl -sS "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2020-1938" -o evidence/nvd.json

# NVD's own dates and analysis status.
jq -r '.vulnerabilities[0].cve | {published, lastModified, vulnStatus}' evidence/nvd.json

# The two CVSS scores NVD attached: v3.1 and v2.
jq -r '.vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData | {baseScore, baseSeverity}' evidence/nvd.json
jq -r '.vulnerabilities[0].cve.metrics.cvssMetricV2[0].cvssData.baseScore' evidence/nvd.json
```
```text
"published":    "2020-02-24T22:15:12.057"
"lastModified": "2026-06-17T03:02:39.187"
{ "baseScore": 9.8, "baseSeverity": "CRITICAL" }
7.5
```
Three severity claims for one defect: Important, 7.5, 9.8 CRITICAL. Last modified six years after publication.

**The CPE ranges a finding depends on**

```bash
# Extract the apache:tomcat CPE ranges; a scanner match is a join against exactly these.
jq -r '.vulnerabilities[0].cve.configurations[].nodes[].cpeMatch[]
       | select(.criteria | test("apache:tomcat"))
       | [.criteria, .versionStartIncluding, .versionEndExcluding] | @tsv' evidence/nvd.json
```
```text
cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*    7.0.0    7.0.100
cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*    8.5.0    8.5.51
cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*    9.0.0    9.0.31
```

```bash
# Count CPE entries by vendor to see who else the record knows embeds Tomcat.
jq -r '[.vulnerabilities[0].cve.configurations[].nodes[].cpeMatch[].criteria
        | split(":")[3]] | group_by(.) | map({(.[0]): length}) | add' evidence/nvd.json
```
```text
{ "apache": 4, "blackberry": 5, "debian": 3, "fedoraproject": 3, "netapp": 2, "opensuse": 1, "oracle": 20 }
```
35 of 38 entries are not apache:tomcat.

**The record as a changelog**

```bash
# Fetch NVD's full edit history for the CVE.
curl -sS "https://services.nvd.nist.gov/rest/json/cvehistory/2.0?cveId=CVE-2020-1938" -o evidence/nvd-history.json

# How many edits, then the first few with date, event and number of changed details.
jq -r '.totalResults' evidence/nvd-history.json
jq -r '.cveChanges[].change | [.created[0:10], .eventName, (.details|length)] | @tsv' evidence/nvd-history.json | head -8
```
```text
57

2020-02-25   CVE Modified       2
2020-02-27   Initial Analysis   8
...
```
Key edits: 2022-03-03 KEV added, 2022-04-29 Oracle and Geode CPEs added (26 months late), 2026-06-17 last modified. An Oracle product scanned in March 2022 had no finding; in May 2022 it was CRITICAL.

**KEV**

```bash
# Read the CISA Known Exploited Vulnerabilities fields NVD embeds.
jq -r '.vulnerabilities[0].cve | {cisaExploitAdd, cisaActionDue, cisaVulnerabilityName}' evidence/nvd.json
```
```text
"cisaExploitAdd": "2022-03-03"
"cisaActionDue":  "2022-03-17"
```
Two years after publication, though proof-of-concept code circulated within days in 2020. KEV dates are catalogue dates.

**The missing EOL branch**

```bash
# Look for Tomcat 6.x anywhere: CNA versions and the lower bound of every tomcat CPE range.
jq -r '.containers.cna.affected[].versions[].version' evidence/cve-org.json
jq -r '.vulnerabilities[0].cve.configurations[].nodes[].cpeMatch[]
       | select(.criteria | test("apache:tomcat")) | .versionStartIncluding' evidence/nvd.json
```
```text
7.0.0
8.5.0
9.0.0
```
6.x shipped the same AJP connector and went EOL in 2016. It appears nowhere. Scanner silence about EOL software means nobody looked.

**The named EOL branch, five years later**

```bash
# Fetch a 2025 Tomcat CVE for comparison, where 8.5 is the EOL branch.
curl -sS "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2025-24813" -o evidence/nvd-24813.json

# Does the prose name the EOL branch?
jq -r '.vulnerabilities[0].cve.descriptions[0].value' evidence/nvd-24813.json | grep -A1 "EOL"

# Are the CPE ranges bounded below?
jq -r '.vulnerabilities[0].cve.configurations[].nodes[].cpeMatch[]
       | select(.criteria | test("apache:tomcat:\\*"))
       | [(.versionStartIncluding//"UNBOUNDED"), .versionEndExcluding] | @tsv' evidence/nvd-24813.json
```
```text
The following versions were EOL at the time the CVE was created but are
known to be affected: 8.5.0 though 8.5.100.

UNBOUNDED    9.0.99
10.1.1       10.1.35
11.0.1       11.0.3
```
The prose names 8.5; the CPE is unbounded below, so 8.5, 7.0 and 6.x all match, and the "fix" is an upgrade to 9.0.99.

```bash
# Assert 14 facts about the captured JSON: CNA, dates, scores, ranges, KEV date, edit count, embedding date, EOL handling.
./scripts/proof-check.sh
```
```text
PASS: ...
CVE-tomcat-85 proof result: 14 passed, 0 failed
RESULT: PASS — the captured evidence still supports LESSON.md.
```

No cleanup. The investigation only reads.

Takeaway: a CVE is a record of an event that keeps evolving, not a point-in-time fact. Every severity number is a producer's claim, a finding is a join against an analyst-typed CPE range, and the record only knows the embeddings someone reported. Silence is the real exposure.
