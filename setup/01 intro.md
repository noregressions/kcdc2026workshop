---
id: setup-intro
oneliner: "Required tool versions, the versions these walkthroughs were recorded against, and what is not pinned."
---
# KCDC Workshop Prerequisites

This workshop uses Java, Maven, Node.js, Python, container tooling, SBOM tooling and vulnerability scanners across the repository.

Complete setup in this order:

1. [Install before the workshop](./02%20tools.md)
2. [Accounts and keys](./03%20ACCOUNTS-AND-KEYS.md)
3. [Pre-pull and pre-warm](./04%20PREPULL-PREWARM.md)

Two scripts in the repository automate the checking and the warming:

```bash
./scripts/tools-check.sh    # what is installed, what is missing, how to get it
./scripts/build-all.sh      # every download, image pull and compile
```

`tools-check.sh` reports the version of every tool it finds, flags anything
below the minimum in the table below, and prints an installation link for
anything missing. It changes nothing.

`build-all.sh` then performs step 3 in one command, and reports what succeeded,
what was skipped and why.

## Minimum environment

| Tool | Requirement |
|---|---|
| Bash | System Bash is sufficient |
| Git | Current |
| JDK | 21+ |
| Maven | 3.9+ |
| Node.js | 20+ |
| npm | Bundled with Node.js |
| Python | 3.11+ |
| pip / venv | Bundled or installed with Python |
| Docker | Current Docker Desktop or Docker Engine |
| jq | Current |
| Syft | Current |
| Snyk CLI | Current and authenticated |
| Trivy | Current |
| Grype | Current |
| pip-audit | Current |
| Docker Scout | Current |
| curl | Current/system |
| zip / unzip / tar | Current/system |
| grep / find / sort / diff / tee | System versions |

## Container engine note

Docker is the canonical container engine for the workshop as the repository is currently written.

Podman can be used for the scenario container build/run stages, but the scripts currently invoke `docker` directly.

In addition:

- T02 uses **Docker Scout**, so Docker is required for that investigation.
- T03 currently tells Trivy to use Docker as the image source.
- T04 currently feeds Grype a Docker image source.

## Container images used by the repository

```text
eclipse-temurin:21-jre-jammy
payara/server-web:7.2026.7
```

S03, S04 and S05 do not contain Dockerfiles.

## Quick verification

```bash
git --version
bash --version

java -version
javac -version
mvn --version

node --version
npm --version

python3 --version
python3 -m pip --version

jq --version
curl --version
zip -v
unzip -v
tar --version

docker version
docker scout version

syft version
snyk --version
trivy --version
grype version
pip-audit --version
```

For T06:

```bash
printenv NVD_API_KEY >/dev/null &&
  echo "NVD API key: configured" ||
  echo "NVD API key: not configured"
```

## Verified baseline

The workshop material was last authored and verified against the versions below, on macOS (Apple silicon) on 2026-08-23.

These are **not** requirements. They are a known-good reference point: if your output differs from what a walkthrough records, compare against this table first.

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

Note that the recorded walkthroughs were produced on a newer JDK and Node.js than this document asks you to install. That is deliberate: the builds pin `maven.compiler.release` to 21, so the compiled output is the same. Installing the stated minimums is the supported path.

### Versions the repository pins itself

These are resolved by the build rather than installed by you, so they do not vary with your local setup:

```text
Spring Boot                3.5.12      (S01)
Maven Shade Plugin         3.6.2       (S01)
CycloneDX Maven Plugin     2.9.3       (S01)
esbuild Maven Plugin       2.0.0       (S02)
Jakarta EE API             11.0.0      (S02)
maven-plugin-tools         3.15.1      (S04 tooling)
```

### Two scanner versions that are not pinned

Two tools in this workshop resolve a version at run time, so different attendees can legitimately see different results:

- **OWASP Dependency-Check (T06)** selects `13.0.0` when `NVD_API_KEY` is set and `12.2.2` when it is not. Dependency-Check 13.0.0 rejects an empty configured key, so keyless runs deliberately fall back. See `investigations/T06-owasp-dependency-check-s04/scripts/common.sh`.
- **Grype** bundles its own Syft rather than calling yours. Grype 0.115.0 embeds Syft v1.46.0, so a Grype-derived component list can differ from a standalone Syft 1.51.0 one for reasons unrelated to the point being made.

### Vulnerability databases are not versions

Trivy, Grype, Snyk and Dependency-Check all resolve findings against databases that change daily. Counts recorded in a walkthrough are observations from the day it was written, not invariants.

Some `proof-check.sh` scripts do assert exact totals. T06 asserts a dependency count of `167` and a vulnerability-record count of `78` for the plugin-aware scan, so it is expected to drift as NVD data changes. A failure there means the recorded numbers need refreshing, not that the demonstrated point has stopped being true — the structural assertions in the same script (which components appear, which are omitted) are the claims that actually carry the lesson.

Check what your Trivy database currently holds with:

```bash
trivy --version
```

The `UpdatedAt` and `NextUpdate` fields tell you whether a refresh is due mid-workshop.
