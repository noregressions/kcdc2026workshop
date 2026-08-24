---
id: s03-python-pep517-overview
oneliner: "A transitive sdist that executes build code during installation: prerequisites and how to run it."
track: optional
---

# S03 — Python PEP 517 Supply Chain Trace Lab: Overview

> **Workshop track: OPTIONAL** — not part of the timed route. Visit this lab if you use Python: it shows the same build-time execution problem via PEP 517.

A deliberately small, Python-native supply-chain scenario.

The local application declares one dependency:

```text
reportkit==1.0.0
```

`reportkit` has a transitive dependency:

```text
tracehook-demo==1.0.0
```

That transitive dependency is supplied only as a Python source distribution
(`sdist`). Installing it causes pip to invoke its PEP 517 build backend.

The backend generates an importable Python package and a JSON marker that did
**not** exist in the source distribution.

The installed application then imports the direct dependency, which imports the
generated transitive package, and exposes the generated trace at `/trace`.

```text
requirements.txt
    |
    v
reportkit==1.0.0 wheel
    |
    | Requires-Dist
    v
tracehook-demo==1.0.0 sdist
    |
    | PEP 517
    v
tracehook_backend.build_wheel()
    |
    | generates package content
    v
.venv/site-packages/tracehook_demo/
    |
    v
runtime import
    |
    v
GET /trace
```

## Requirements

- Python 3.11+
- `curl`
- `tar`
- `unzip`
- `jq` optional
- Syft optional

The package fixtures are local, so the build does not need PyPI access.

## Build

```bash
./scripts/build.sh
```

## Run

```bash
./scripts/run.sh
```

Then:

```bash
curl -sS http://localhost:8081/trace | jq
```

Stop the runtime with:

```bash
./scripts/stop.sh
```

Return the whole scenario to its pre-build state with:

```bash
./scripts/clean.sh
```

Verify the complete scenario with:

```bash
./scripts/proof-check.sh
```

## Package fixtures

`python-repo/` contains the exact package artefacts consumed by pip:

```text
reportkit-1.0.0-py3-none-any.whl
tracehook_demo-1.0.0.tar.gz
```

`python-sources/` contains their auditable fixture source.

If you deliberately change those fixtures, rebuild the local package repository:

```bash
python3 scripts/rebuild-python-repo.py
```

## Trace helper

```bash
./scripts/trace-python.sh
```

`trace-python.sh` replays the core evidence sequence in one pass: the direct declaration in `requirements.txt`, the `reportkit` wheel metadata that names the transitive dependency, the contents of the `tracehook_demo` sdist, its PEP 517 backend declaration, the generated `build-hook.json` marker in `site-packages`, and the installed package metadata.

It reads the virtual environment created by `./scripts/build.sh`, so run the build first.

See `TRACE.md` for the annotated walkthrough.
