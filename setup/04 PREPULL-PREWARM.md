---
id: setup-prepull-prewarm
oneliner: "Pull the images and warm the scanner databases before the workshop — one command, and what it does."
track: core
---

# Pre-Pull and Pre-Warm

Do this before the workshop, on a good network. The goal is to avoid
spending workshop time downloading container images, vulnerability databases
or large scanner datasets.

## The one-command route

```bash
./scripts/build-all.sh
```

That pulls the base images, builds all five scenarios, builds the S01 and S02
container images, and warms the Grype, Trivy and Syft data. It starts no
servers and leaves no container running.

To include the investigation baselines as well (slower, and the T06 step
downloads a large NVD dataset the first time):

```bash
./scripts/build-all.sh --with-investigations
```

Useful variants:

```bash
./scripts/build-all.sh --list     # show which phases would run
./scripts/build-all.sh --quick    # scenarios only, no pulls or database warming
./scripts/build-all.sh --help     # all options
```

Each phase runs independently and records its own result, so a single run
tells you everything that needs attention rather than stopping at the first
problem. The exit status is non-zero if any step failed.

## What it does

| Step | What warms up | By hand |
|---|---|---|
| Pull base images | `eclipse-temurin:21-jre-jammy` (S01), `payara/server-web:7.2026.7` (S02) | `docker pull` each |
| Build S01, S02, S04 | Maven plugins and dependencies into your local repository | each scenario's `./scripts/build.sh` |
| Build S05 | npm dependencies — and proves npm lifecycle scripts can execute | `scenarios/S05-node-prepack/scripts/build.sh` |
| Build S03 | the Python environment (fixtures are local; no PyPI needed) | `scenarios/S03-python-pep517/scripts/build.sh` |
| Warm Grype | its vulnerability database | `grype db update && grype db status` |
| Warm Trivy | its vulnerability database, via a throwaway scan | `trivy fs --scanners vuln --no-progress scenarios/S01-spring-node` |
| Warm Syft | first-run downloads | `syft scenarios/S01-spring-node -o table >/dev/null` |

Every step above, done entirely by hand with its verification commands, is in
[`setup/PREWARM-MANUAL.md`](./PREWARM-MANUAL.md) in the repository — follow
it if `build-all.sh` reports a failure you need to investigate on its own.

## Two steps it does not do for you

**Snyk authentication** (needed for T01):

```bash
snyk auth
```

**OWASP Dependency-Check / NVD data** (needed for T06, and the most
important pre-warm: the first run may populate a large local NVD database).
With your `NVD_API_KEY` exported (see
[`03 ACCOUNTS-AND-KEYS.md`](./03%20ACCOUNTS-AND-KEYS.md)):

```bash
cd investigations/T06-owasp-dependency-check-s04

./scripts/baseline-s04.sh
./scripts/run-dependency-check-s04.sh

cd ../..
```

Dependency-Check stores its data under
`~/.cache/kcdc-dependency-check/<version>` and reuses it on later runs.
Without an NVD API key, the harness falls back to Dependency-Check 12.2.2.
(`build-all.sh --with-investigations` covers this step too.)

## Ready when

```bash
./scripts/tools-check.sh                   # exits 0
./scripts/build-all.sh                     # reports 0 failed
```

and the two base images are present:

```bash
docker image inspect eclipse-temurin:21-jre-jammy >/dev/null &&
docker image inspect payara/server-web:7.2026.7 >/dev/null &&
echo "Workshop base images ready"
```
