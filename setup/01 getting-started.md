---
id: setup-getting-started
oneliner: "Clone repository, verify dependencies, install missing tools, and pre-warm build caches."
track: core
---

# Getting Started

Environment setup can be completed via a preconfigured Docker container environment or direct host installation.

## Option A: Workshop Container Environment

Requirements: Docker Desktop or Docker Engine on Linux with at least 20 GB free disk space.

Execute from the repository root:

```bash
./container/build.sh
./container/run.sh
```

The container provides preinstalled tools, precompiled scenario targets, and pre-cached vulnerability databases. Validate the environment inside the container:

```bash
./scripts/tools-check.sh
```

Architecture details:
- The container accesses the host Docker daemon via a mounted Unix socket (`/var/run/docker.sock`). Images built by scenarios S01 and S02 are registered directly with the host daemon and publish ports to `localhost`.
- Scenario servers in S03, S04, and S05 bind within the container network namespace. Issue `curl` verification requests from within the container shell.
- Authentication tokens can be forwarded by exporting `SNYK_TOKEN` and `NVD_API_KEY` before executing `./container/run.sh`.

## Option B: Local Host Installation

Complete the following four steps:

### 1. Clone Repository

```bash
git clone https://github.com/noregressions/kcdc2026workshop.git
cd kcdc2026workshop
```

To update an existing checkout:

```bash
git pull
```

### 2. Check Tool Prerequisites

```bash
./scripts/tools-check.sh
```

This utility inspects installed binaries against the minimum required versions and outputs installation links for missing dependencies. It makes no system modifications.

### 3. Install Missing Prerequisites

Install missing packages using the system package manager or refer to [`setup/INSTALL.md`](./INSTALL.md) for OS-specific commands (macOS Homebrew, Debian/Ubuntu APT).

Re-run validation:

```bash
./scripts/tools-check.sh
```

### 4. Pre-Warm Caches and Compile Targets

```bash
./scripts/build-all.sh
```

This script:
1. Pulls required container base images (`eclipse-temurin:21-jre-jammy`, `payara/server-web:7.2026.7`).
2. Builds Maven, npm, and Python targets across scenarios S01–S05.
3. Builds container image targets.
4. Initializes local vulnerability databases for Grype, Trivy, and Syft.

Returns exit code 0 when all pre-warm steps succeed.

## Verification Criteria

Setup is complete when:

```text
tools-check.sh   exits 0
build-all.sh     reports 0 failed
```
