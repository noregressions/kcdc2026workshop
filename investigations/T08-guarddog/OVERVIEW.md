---
id: t08-guarddog-overview
oneliner: "GuardDog reads the code, not just the metadata: two clean results for opposite reasons, and what that tells you."
track: reference
---

# T08 — GuardDog / S05 + S03: Overview

> **Workshop track: REFERENCE** — self-study material, not part of the timed
> route. Pairs with Part 5, where the question is what a tool can detect once
> it stops trusting metadata and starts reading code.

## What GuardDog is

[GuardDog](https://github.com/DataDog/guarddog) (Datadog, Apache-2.0) is a
malicious-package scanner for npm, PyPI, Go, RubyGems, GitHub Actions and
editor extensions. It works two ways: **source-code heuristics** (Semgrep and
YARA rules over the package's actual code, looking for obfuscation, download-
and-execute, install hooks, exfiltration) and **metadata heuristics**
(typosquatting, expired maintainer domains, and the like).

The reason it belongs in this workshop: every scanner in Part 2 read
*metadata*. GuardDog reads the **code**. So it should, in principle, see the
mechanisms that hid from an SBOM. This investigation asks whether it does, by
pointing it at two scenarios you have already taken apart by hand.

## Observed tooling

```text
guarddog 3.2.0
python  3.11.15
```

GuardDog wants a kernel-level sandbox it cannot get on most laptops; the
source-code heuristics run identically with `--no-sandbox`, which every script
here passes.

## Core result

Both artefacts scan **completely clean**, and the two clean results mean
opposite things:

```text
S05 published tarball        → No risks detected (0.0/10)
S03 source distribution      → No risks detected (0.0/10)
positive control (malicious) → High risk (8.2/10)   ← proves the scanner fires
```

**S05 is clean because the mechanism is not in the artefact.** The published
tarball ships the generated `dist/` output and a `package.json` that still
declares `"prepack": "node scripts/generate-dist.js"`, pointing at a
generator the tarball does not contain (`files: ["dist"]` excluded it).
GuardDog cannot flag code that was never shipped.

**S03 is clean because the mechanism IS in the artefact, and it is benign.**
The sdist carries its PEP 517 build backend, `tracehook_backend.py`. GuardDog
read it. The backend writes a wheel using `json`, `base64` and `zipfile`:
ordinary build machinery, indistinguishable by heuristic from a real backend.
Nothing to flag, correctly.

A `0.0/10` cannot tell those two situations apart. One clean result means
*the evidence left the building*; the other means *the evidence is here and
it is fine*. GuardDog reads code, which beats reading metadata, and it still
inherits the boundary Part 2 established: it can only judge what the artefact
actually contains.

The positive control is a deliberately malicious package (a `preinstall` hook
and a base64-hidden `child_process` download-and-execute). It is never
installed or published: it exists only to prove the scanner is awake, so that
a clean S05/S03 result reads as "nothing detected", not "scanner asleep".

## The malicious variant — catch vs miss

Step 4 turns S05's own mechanism malicious, in
[`scenarios/S05-node-prepack/malicious-variant`](../../scenarios/S05-node-prepack/malicious-variant/README.md),
and gets the workshop's sharpest single result. The same `curl | sh` payload
is planted two ways:

```text
payload in the generator   → runs at pack time, hits the PUBLISHER  → NOT in tarball → scan MISSES (0.0)
payload in the generated   → runs on load,      hits the CONSUMER   → IN tarball     → scan CATCHES (8.2)
```

The same mechanism attacks two different victims, and a scan of the published
tarball is exactly right for one and completely blind to the other. The payload is a harmless
stand-in (an async `curl` to a reserved `.invalid` host); nothing is installed
or published.

## Run

```bash
./scripts/scan-s05.sh          # published tarball → clean
./scripts/scan-s03.sh          # sdist with backend → clean
./scripts/positive-control.sh  # malicious control → High risk
./scripts/scan-malicious.sh    # S05 malicious variant → catch vs miss
./scripts/proof-check.sh
```

Needs GuardDog on the path (`pipx install guarddog`) and the S05/S03
artefacts built (`(cd scenarios/S05-node-prepack && ./scripts/build.sh)`, same
for S03). Captured outputs are in `evidence/` if you would rather read along.

See `TRACE.md` for the annotated walkthrough.
