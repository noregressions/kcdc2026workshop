---
id: setup-versions
oneliner: "The versions the walkthroughs were recorded against, what the repository pins itself, and what legitimately drifts."
track: reference
---

# Verified Baseline

The workshop material was last authored and verified against the versions
below, on macOS (Apple silicon) on 2026-08-23.

These are **not** requirements — the minimums are in
[`02 tools.md`](./02%20tools.md) — just a known-good reference point: if your
output differs from what a walkthrough records, compare against this table
first.

| Tool | Verified version |
|---|---|
| Bash | 3.2.57(1) (macOS system Bash) |
| Git | 2.50.1 (Apple Git-155) |
| JDK | 25.0.2 Temurin (`25.0.2+10-LTS`) |
| Maven | 3.9.16 |
| Node.js | 26.4.0 |
| npm | 12.0.1 |
| Python | 3.14.6 |
| pip | 26.1.2 |
| Docker | 29.7.2 client and engine (Docker Desktop 4.87.0) |
| Docker Compose | 5.4.0 |
| Docker Scout | 1.24.0 |
| jq | 1.7.1-apple |
| Syft | 1.51.0 |
| Snyk CLI | 1.1305.2 |
| Trivy | 0.74.0 |
| Grype | 0.115.0 (DB schema 6) |
| pip-audit | 2.10.1 |
| curl | 8.7.1 (LibreSSL 3.3.6) |
| zip / unzip | Zip 3.0 / UnZip 6.00 |
| tar | bsdtar 3.5.3 (libarchive 3.7.4) |
| grep | BSD grep 2.6.0-FreeBSD |

Note that we produced the recorded walkthroughs on a newer JDK and Node.js
than the setup documents ask you to install. That is deliberate: the builds
pin `maven.compiler.release` to 21, so the compiled output is the same.
Installing the stated minimums is the supported path.

## Versions the repository pins itself

These are resolved by the build rather than installed by you, so they do not
vary with your local setup:

| Component | Version | Used by |
|---|---|---|
| Spring Boot | 3.5.12 | S01 |
| Maven Shade Plugin | 3.6.2 | S01 |
| CycloneDX Maven Plugin | 2.9.3 | S01 |
| esbuild Maven Plugin | 2.0.0 | S02 |
| Jakarta EE API | 11.0.0 | S02 |
| maven-plugin-tools | 3.15.1 | S04 tooling |

## Two scanner versions that are not pinned

Two tools in this workshop resolve a version at run time, so different
attendees can legitimately see different results:

- **OWASP Dependency-Check (T06)** selects `13.0.0` when `NVD_API_KEY` is set
  and `12.2.2` when it is not. Dependency-Check 13.0.0 rejects an empty
  configured key, so keyless runs deliberately fall back. See
  `investigations/T06-owasp-dependency-check-s04/scripts/common.sh`.
- **Grype** bundles its own Syft rather than calling yours. Grype 0.115.0
  embeds Syft v1.46.0, so a Grype-derived component list can differ from a
  standalone Syft 1.51.0 one for reasons unrelated to the point being made.

## Vulnerability databases are not versions

Trivy, Grype, Snyk and Dependency-Check all resolve findings against
databases that change daily. Counts recorded in a walkthrough are
observations from the day it was written, not invariants.

Some `proof-check.sh` scripts do assert exact totals. T06 asserts a
dependency count of `167` and a vulnerability-record count of `78` for the
plugin-aware scan, so it is expected to drift as NVD data changes. A failure
there means the recorded numbers need refreshing, not that the demonstrated
point has stopped being true. The structural assertions in the same script
(which components appear, which are omitted) are the claims that actually
carry the lesson.

Check what your Trivy database currently holds with:

```bash
trivy --version
```

The `UpdatedAt` and `NextUpdate` fields tell you whether a refresh is due
mid-workshop.
