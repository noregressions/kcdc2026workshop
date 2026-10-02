---
id: cheatsheet-part5
oneliner: "Part 5 in run order: GuardDog against the S05/S03 packages and their malicious variants, then reverse provenance on S01."
track: reference
---

# Part 5 — Someone Is Counting on That

---

## T08 — GuardDog: reading code, not metadata (S05, S03, malicious variants)

**Proving:** What a code-reading scanner recovers, and the boundary it still cannot cross: what packaging chose to include.

Question: when a scanner reads the code, does a clean result mean safe, or only that nothing detectable was in the bytes it was handed?
Needs: `pipx install guarddog` (3.2.0, Python 3.11), `tar`. Every command passes `--no-sandbox`; that lowers isolation, not detection. S05 and S03 built. No Java ecosystem, so S04 is out of scope.

```command
cd investigations/T08-guarddog
```

Calibration: write a deliberately malicious npm package (never installed) and scan it, so a later 0.0 means "nothing matched", not "nothing ran". Writes results/control/.
```command
./scripts/positive-control.sh
```
```output
execution-risk: found 1 indicator
│ * threat.process.spawn
│   Detects download-and-execute patterns: fetching a remote file then executing it
│   at index.js:3
Assessment:  High risk  (8.2/10)
```

Scan the S05 published tarball. The prepack generator was excluded by files:["dist"], so there is no mechanism to judge. Writes results/s05/.
```command
./scripts/scan-s05.sh
```
```output
package/dist/index.js
package/package.json
package/dist/prepack-evidence.json

No risks found in trace-route-package-1.0.0.tgz
Assessment:  No risks detected  (0.0/10)
```

Scan the S03 sdist. The PEP 517 backend does ship and is benign; every rule ran and returned empty. Writes results/s03/ including scan.json.
```command
./scripts/scan-s03.sh
```
```output
tracehook_demo-1.0.0/pyproject.toml
tracehook_demo-1.0.0/tracehook_backend.py

No risks found in tracehook_demo-1.0.0.tar.gz
Assessment:  No risks detected  (0.0/10)
```

Build both malicious S05 variants (payload aimed at an unresolvable .invalid host), then scan A's tarball, A's source, and B's tarball. Writes results/malicious/.
```command
./scripts/scan-malicious.sh
```
```output
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

Assert ten claims against results/: the two clean scans, tarball contents, control fired, A-tarball clean, A-source and B-tarball caught.
```command
./scripts/proof-check.sh
```
```output
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

The S7 reverse-provenance sheet follows, generated from its lesson.
