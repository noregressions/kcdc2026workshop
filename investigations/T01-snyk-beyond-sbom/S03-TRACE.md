---
id: t01-s03-python-pep517
oneliner: "Snyk against S03, where a transitive dependency executes build code during installation."
track: reference
---

# T01 / S03 — Snyk Against Python + PEP 517

This is the S03 case inside **T01 — Snyk Beyond the SBOM**.

S03 is different from S01, S02 and S04.

The interesting fact is not merely that a component was transformed. A **transitive dependency executes build code during installation**.

Known S03 ground truth is:

```text
requirements.txt
    reportkit==1.0.0

        ↓ wheel metadata

Requires-Dist:
    tracehook-demo==1.0.0

        ↓ local repository

tracehook_demo-1.0.0.tar.gz
    pyproject.toml
    tracehook_backend.py

        ↓ PEP 517

tracehook_backend.build_wheel()

        ↓ creates files absent from sdist

tracehook_demo/__init__.py
tracehook_demo/build-hook.json

        ↓ generated wheel

site-packages

        ↓ runtime

reportkit.runtime_trace()
```

The central T01/S03 question is:

> Can Snyk identify the transitive Python package while also preserving the fact that dependency-supplied build code executed and generated new runtime content?

Those are two different kinds of knowledge:

```text
package inventory
        !=
build execution history
```

Snyk's current Python CLI model uses supported Python manifests such as `requirements.txt` and the installed Python environment to construct the dependency graph. Snyk's experimental `--include-provenance` option is Maven-specific, so it is deliberately **not** used for this Python case.

---

# 1. Re-establish S03 ground truth

## Run

```bash
./scripts/baseline-s03.sh
```

## Observe

Capture during walkthrough.

## Establish

Confirm all of the following:

```text
application declaration
    reportkit==1.0.0

reportkit wheel metadata
    Requires-Dist: tracehook-demo==1.0.0

tracehook-demo distribution
    sdist

sdist build-system
    build-backend = "tracehook_backend"

sdist files
    tracehook_demo/__init__.py absent
    tracehook_demo/build-hook.json absent

pip install
    builds a wheel for tracehook-demo

installed environment
    reportkit 1.0.0
    tracehook-demo 1.0.0

installed files
    tracehook_demo/__init__.py present
    tracehook_demo/build-hook.json present

runtime
    generated marker affects application behaviour
```

The baseline also performs a second wheel build and retains the generated wheel so we can inspect the post-build artefact directly.

---

# 2. Run Snyk against the Pip project

## Run

```bash
./scripts/run-snyk-s03.sh
```

The first probe runs:

```text
snyk test
    requirements.txt
    +
    the S03 virtual environment
```

## Question

Can Snyk recover:

```text
reportkit 1.0.0
    ↓
tracehook-demo 1.0.0
```

even though `requirements.txt` names only `reportkit`?

## Observe

Capture during walkthrough.

## Establish

If it does, Snyk is recovering more than the literal top-level requirements file because the installed Python environment supplies the transitive dependency information.

That still does not tell us whether Snyk knows **how** `tracehook-demo` was built.

---

# 3. Generate the Snyk Python CycloneDX SBOM

## Question

Does the Snyk SBOM contain:

```text
reportkit
tracehook-demo
reportkit → tracehook-demo
```

## Observe

Capture during walkthrough.

## Establish

Separate these questions:

```text
Does the SBOM know the package exists?
Does the SBOM know the dependency relationship?
Does the SBOM know the distribution was an sdist?
Does the SBOM know a build backend executed?
```

Do not infer the latter two from the first two.

---

# 4. Search for PEP 517 execution evidence

The harness explicitly searches Snyk text and JSON output for:

```text
tracehook_backend
build_wheel
build-hook.json
pep517-build-backend-executed
```

## Why

These strings are directly present in S03's actual build/runtime evidence.

If Snyk reconstructs the build execution path, we should be able to point to where that fact appears.

## Observe

Capture during walkthrough.

## Establish

Absence here does not mean the build hook did not execute. S03 already proved that independently.

It means that execution fact is not represented in the Snyk evidence we tested.

---

# 5. Ask Snyk to discover a project from the unpacked sdist

## Input

```text
tracehook_demo-1.0.0.tar.gz
    ↓ unpacked
pyproject.toml
tracehook_backend.py
```

## Question

Does Snyk Open Source treat this generic PEP 517/PEP 621 source tree as a supported Pip project on its own?

## Observe

Capture during walkthrough.

## Establish

This tests whether Snyk can move backwards from the dependency's source distribution into its build configuration without a `requirements.txt`-style application manifest.

---

# 6. Ask Snyk to discover a project from the generated wheel

The generated wheel contains the package identity and the generated files:

```text
tracehook_demo/__init__.py
tracehook_demo/build-hook.json
tracehook_demo-1.0.0.dist-info/METADATA
```

## Question

Can normal Snyk Open Source project discovery use that artefact directly?

## Observe

Capture during walkthrough.

## Establish

This distinguishes:

```text
Python package artefact metadata
        from
Snyk-supported project manifest
```

---

# 7. Ask Snyk about installed `site-packages`

## Question

If only the installed environment remains, without the application's `requirements.txt`, does Snyk discover a project from `.dist-info` package metadata?

## Observe

Capture during walkthrough.

## Establish

This tells us whether Snyk's Python dependency analysis is fundamentally anchored on the application/project manifest even though it consults the installed environment to build the complete dependency graph.

---

# 8. Compare every evidence boundary

## Run

```bash
./scripts/compare-s03.sh
```

Complete this matrix from actual output:

| Evidence view | reportkit | tracehook-demo | sdist fact | backend execution | generated files |
| --- | --- | --- | --- | --- | --- |
| requirements.txt | yes | no | no | no | no |
| reportkit wheel metadata | yes | yes | no | no | no |
| tracehook sdist | n/a | yes | yes | backend declared | files absent |
| pip build log | yes | yes | yes | build observed | wheel created |
| installed environment | yes | yes | history lost | history lost | files present |
| runtime marker | indirect | yes | says generated | names build_wheel | yes |
| Snyk Pip test | ? | ? | ? | ? | ? |
| Snyk Python SBOM | ? | ? | ? | ? | ? |
| Snyk sdist discovery | n/a | ? | input is sdist tree | ? | absent |
| Snyk wheel discovery | n/a | ? | history not intrinsic | ? | present |
| Snyk site-packages discovery | ? | ? | history not intrinsic | ? | present |

The central result we are testing is:

```text
A scanner may reconstruct package dependency identity
without reconstructing the executable build steps that produced
the installed package contents.
```
