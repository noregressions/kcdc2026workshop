---
id: t05-pip-audit-s03-overview
oneliner: "pip-audit against S03: scope and how to run it."
track: reference
---

# T05 — pip-audit / S03: Overview

> **Workshop track: REFERENCE** — self-study material, not part of the timed route.

## Scenario

```text
S03 — Python + PEP 517
```

## Tool

Observed:

```text
pip-audit 2.10.1
Python 3.14
pip 26.1.2
```

## Core question

What does `pip-audit` recover from the Python dependency graph, and what does it know about the PEP 517 execution that manufactured the installed package?

## Canonical results

Normal dependency resolution recovered:

```text
reportkit
tracehook-demo
```

pip-audit identified both private packages but skipped them because they were not found in PyPI's vulnerability service.

The controlled execution probe proved:

```text
pip-audit -r
    → pip dependency collection
    → PEP 517 backend import
    → backend code executes
```

Observed marker:

```text
tracehook_backend imported during pip-audit dependency resolution
```

`--no-deps` alone still produced:

```text
reportkit
tracehook-demo
```

while:

```text
--no-deps --disable-pip
```

produced only:

```text
reportkit
```

The installed-environment audit also found:

```text
pip 26.1.2
CVE-2026-13346 / PYSEC-2026-3721
fixed in 26.2
```

## Run

```bash
./scripts/baseline-s03.sh
./scripts/run-pip-audit-s03.sh
./scripts/run-pep517-exec-probe.sh
./scripts/compare-s03.sh
./scripts/proof-check.sh
```

See `TRACE.md` for the full evidence chain.
