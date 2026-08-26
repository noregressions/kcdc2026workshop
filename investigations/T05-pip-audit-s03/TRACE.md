---
id: t05-pip-audit-s03
oneliner: "Separates dependency identity from vulnerability matching and from PEP 517 build execution, as distinct facts about one environment."
track: reference
---

# T05 — pip-audit / S03

## Objective

Use `pip-audit` against S03 to separate four different facts:

```text
dependency identity
vulnerability matching
PEP 517 build execution
generated installed content
```

The central question is:

> Can a Python vulnerability audit reconstruct the fact that a transitive source distribution executed a PEP 517 backend and generated runtime files?

T05 also asks a more surprising question:

> Can running the vulnerability audit itself execute packaging code from the dependency being audited?

The observed answer to the second question is **yes**.

---

# Tool versions observed

```text
pip-audit 2.10.1
Python 3.14
pip 26.1.2
```

---

# S03 ground truth

## Check

The direct requirement is:

```text
reportkit==1.0.0
```

The `reportkit` wheel metadata contains:

```text
Requires-Dist: tracehook-demo==1.0.0
```

`tracehook-demo` is supplied as a source distribution.

Its source distribution contains only:

```text
tracehook_demo-1.0.0/pyproject.toml
tracehook_demo-1.0.0/tracehook_backend.py
```

Its PEP 517 configuration contains:

```text
[build-system]
requires = []
build-backend = "tracehook_backend"
backend-path = ["."]
```

The source distribution does **not** contain:

```text
tracehook_demo/__init__.py
tracehook_demo/build-hook.json
```

## Run

```bash
./scripts/baseline-s03.sh
```

## Observe

Ordinary pip installation showed:

```text
Processing reportkit-1.0.0-py3-none-any.whl

Processing tracehook_demo-1.0.0.tar.gz
  Getting requirements to build wheel
  Preparing metadata (pyproject.toml)

Building wheels for collected packages: tracehook-demo
  Building wheel for tracehook-demo (pyproject.toml)
  Created wheel for tracehook-demo

Successfully installed:
  reportkit-1.0.0
  tracehook-demo-1.0.0
```

The installed environment contained:

```text
pip             26.1.2
reportkit       1.0.0
tracehook-demo  1.0.0
```

The installed package contained files absent from the source distribution:

```text
tracehook_demo/__init__.py
tracehook_demo/build-hook.json
```

The generated marker contained:

```json
{
  "event": "pep517-build-backend-executed",
  "generatedBy": "tracehook_backend.build_wheel",
  "package": "tracehook-demo",
  "version": "1.0.0"
}
```

## Establish

The package installation crosses a transformation boundary:

```text
sdist
    ↓ PEP 517 backend execution
wheel
    ↓ install
runtime files
```

Therefore:

```text
source distribution contents
    !=
installed runtime contents
```

---

# A. Normal requirements audit

## Run

```bash
./scripts/run-pip-audit-s03.sh
```

The normal requirements audit uses dependency resolution.

## Observe

`pip-audit` reported:

```text
Dry run: would have audited 2 packages
```

The resulting audit set contained:

```text
reportkit
tracehook-demo
```

`pip-audit` skipped both with:

```text
Dependency not found on PyPI and could not be audited
```

## Establish

`pip-audit` successfully recovered the transitive dependency identity:

```text
reportkit
    → tracehook-demo
```

But package identity did not imply vulnerability coverage.

For these private scenario packages:

```text
package identified
    !=
package vulnerability-auditable through PyPI
```

---

# B. Controlled PEP 517 execution probe

## Check

The harness creates a temporary, controlled copy of the same
`tracehook-demo` source distribution.

The dependency metadata is unchanged.

The backend receives one benign observable side effect:

```text
when tracehook_backend is imported
    write a marker file
```

## Run

```bash
./scripts/run-pep517-exec-probe.sh
```

## Observe

The audit reported:

```text
INFO:pip_audit._audit:Dry run: would have audited 2 packages
No known vulnerabilities found
```

The marker was created:

```text
PEP 517 execution marker:

tracehook_backend imported during pip-audit dependency resolution
```

## Establish

This is direct evidence that:

```text
pip-audit -r requirements.txt
    ↓
pip-assisted dependency collection
    ↓
PEP 517 hook processing
    ↓
import tracehook_backend
    ↓
backend code executes
```

`pip-audit` is not executing code maliciously here: the important point is that a vulnerability audit of a requirements file can cross a Python packaging execution boundary, because dependency collection uses pip and PEP 517 machinery.

So:

> Running the security audit can itself execute code from the dependency being audited.

This is not visible in the final vulnerability report.

---

# C. `--no-deps`

## Observe

With:

```bash
pip-audit --no-deps ...
```

the observed audit set still contained:

```text
reportkit
tracehook-demo
```

The tool emitted:

```text
--no-deps is supported, but users are encouraged to fully hash their pinned dependencies
```

## Establish

For the observed `pip-audit 2.10.1` run, `--no-deps` alone did not reduce the resulting audit set to only the directly pinned requirement.

That is recorded as observed behaviour rather than inferred behaviour.

---

# D. `--no-deps --disable-pip`

## Observe

With:

```bash
pip-audit --no-deps --disable-pip ...
```

the audit set contained only:

```text
reportkit
```

`tracehook-demo` was absent.

## Establish

The difference is:

```text
--no-deps
    reportkit
    tracehook-demo

--no-deps --disable-pip
    reportkit
```

This isolates pip-assisted dependency collection from static handling of the explicitly pinned requirements file.

---

# E. Installed-environment audit

## Run

The harness audits the already-installed `site-packages` directory.

## Observe

The audit saw:

```text
pip 26.1.2
reportkit 1.0.0
tracehook-demo 1.0.0
```

It found one known vulnerability:

```text
pip 26.1.2

PYSEC-2026-3721
CVE-2026-13346

fixed in:
26.2
```

The audit again skipped the scenario packages because they were not found in PyPI's vulnerability service.

## Establish

Auditing the installed environment changes the software universe.

The vulnerability scan now includes packaging/runtime tooling present in that environment:

```text
pip
```

That produced a real vulnerability finding that was unrelated to the application dependency graph itself.

---

# F. CycloneDX output

## Observe

The observed pip-audit CycloneDX output surfaced:

```text
pip 26.1.2
```

The comparison helper did not surface the skipped private packages as CycloneDX components:

```text
reportkit
tracehook-demo
```

## Establish

The JSON vulnerability result and the CycloneDX output preserve different evidence.

The JSON result explicitly records private packages as:

```text
identified but skipped
```

The observed CycloneDX component view did not retain those identities.

Therefore:

```text
same audit operation
    !=
same evidence preserved in every output format
```

---

# What T05 establishes

## 1. Dependency resolution can recover a transitive package

The direct input declared only:

```text
reportkit==1.0.0
```

Normal pip-audit resolution recovered:

```text
tracehook-demo==1.0.0
```

So transitive dependency identity can be reconstructed from package metadata.

---

## 2. Identified packages can still be unauditable

The audit identified both scenario packages but skipped them:

```text
Dependency not found on PyPI and could not be audited
```

This is materially different from:

```text
package not identified
```

A clean result for a skipped/private package is not proof that the package has no vulnerabilities.

---

## 3. A requirements vulnerability audit can execute packaging code

The controlled marker proves:

```text
pip-audit
    → pip dependency collection
    → PEP 517 backend import
    → backend code execution
```

This is the strongest T05 result.

The vulnerability audit itself participates in the Python software supply chain.

---

## 4. Vulnerability output does not preserve PEP 517 execution history

Although the backend executed during dependency resolution, the vulnerability result does not say:

```text
tracehook_backend was imported
PEP 517 hooks ran
runtime files were generated
```

That evidence exists only because the harness separately instrumented the build/install boundary.

---

## 5. Installed package identity does not explain how installed files were created

The installed environment knows:

```text
tracehook-demo 1.0.0
```

But that identity alone does not tell us that:

```text
__init__.py
build-hook.json
```

were generated by the backend and were absent from the source distribution.

So:

```text
installed package identity
    !=
installation provenance
```

---

## 6. `--disable-pip` materially changes the observed audit boundary

Observed:

```text
--no-deps
    reportkit
    tracehook-demo

--no-deps --disable-pip
    reportkit
```

That distinction matters because using pip for collection can cross packaging execution boundaries.

---

## 7. Auditing the environment can reveal vulnerabilities in the audit/install tooling itself

The installed-environment scan found:

```text
pip 26.1.2
CVE-2026-13346
```

So the vulnerability surface of the environment includes more than the application's declared packages.

---

# Final conclusion

T05 demonstrates two different supply-chain blind spots.

First:

```text
package identity
    !=
vulnerability coverage
```

`reportkit` and `tracehook-demo` were identified but not auditable through the selected vulnerability service.

Second:

```text
package identity
    !=
build/install history
```

`pip-audit` could identify the installed/transitive packages, but its final report did not preserve the fact that PEP 517 code executed or that runtime files were generated during wheel construction.

Most importantly, the audit operation itself can participate in that execution chain:

```text
audit requirements
    → resolve dependencies
    → invoke packaging machinery
    → execute PEP 517 backend code
```

The practical rule is:

> Treat Python dependency auditing as an active supply-chain operation when dependency resolution is enabled, not as a purely static inspection step.
