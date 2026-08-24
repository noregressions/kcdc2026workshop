---
id: setup-prepull-prewarm
oneliner: "Pull the images and warm the scanner databases before the workshop, in one command or by hand."
track: core
---

# Pre-Pull and Pre-Warm

Do this before the workshop.

The goal is to avoid spending workshop time downloading container images, vulnerability databases or large scanner datasets.

---

# 0. The one-command route

Everything in this document is automated by:

```bash
./scripts/build-all.sh
```

That pulls the base images, builds all five scenarios, builds the S01 and S02
container images, and warms the Grype, Trivy and Syft data. It starts no servers
and leaves no container running.

To include the investigation baselines as well — slower, and the T06 step
downloads a large NVD dataset the first time:

```bash
./scripts/build-all.sh --with-investigations
```

Useful variants:

```bash
./scripts/build-all.sh --list     # show which phases would run
./scripts/build-all.sh --quick    # scenarios only, no pulls or database warming
./scripts/build-all.sh --help     # all options
```

Each phase runs independently and records its own result, so a single run tells
you everything that needs attention rather than stopping at the first problem.
The exit status is non-zero if any step failed.

The rest of this document is the same work done by hand. Follow it if you want
to understand each step, or if `build-all.sh` reports a failure you need to
investigate on its own.

---

# 1. Clone or update the repository

```bash
git clone https://github.com/noregressions/kcdc2026workshop.git
cd kcdc2026workshop
```

If you already have it:

```bash
git pull
```

---

# 2. Pull the container base images

The repository currently uses exactly two base images.

## S01

```text
eclipse-temurin:21-jre-jammy
```

Docker:

```bash
docker pull eclipse-temurin:21-jre-jammy
```

Podman:

```bash
podman pull docker.io/library/eclipse-temurin:21-jre-jammy
```

## S02

```text
payara/server-web:7.2026.7
```

Docker:

```bash
docker pull payara/server-web:7.2026.7
```

Podman:

```bash
podman pull docker.io/payara/server-web:7.2026.7
```

Verify Docker has both images:

```bash
docker image inspect eclipse-temurin:21-jre-jammy >/dev/null
docker image inspect payara/server-web:7.2026.7 >/dev/null

echo "Base images available"
```

---

# 3. Warm Maven dependencies

Build the Java-based scenarios once.

## S01

```bash
cd scenarios/S01-spring-node
./scripts/build.sh
cd ../..
```

## S02

```bash
cd scenarios/S02-payara-mvnpm
./scripts/build.sh
cd ../..
```

## S04

```bash
cd scenarios/S04-maven-plugin-hidden-content
./scripts/build.sh
cd ../..
```

This populates the local Maven repository with the plugins and dependencies used by the labs.

---

# 4. Warm npm dependencies

S01 already performs npm installation as part of its build.

Also build S05 once:

```bash
cd scenarios/S05-node-prepack
./scripts/build.sh
cd ../..
```

This also proves that npm lifecycle scripts are able to execute in your environment.

---

# 5. Warm the Python environment

Build S03 once:

```bash
cd scenarios/S03-python-pep517
./scripts/build.sh
cd ../..
```

The package fixtures used by the S03 scenario are local, so the core S03 build does not require PyPI.

---

# 6. Warm Grype's vulnerability database

```bash
grype db update
grype db status
```

A successful `db status` should show a valid local database.

---

# 7. Warm Trivy's vulnerability database

A simple filesystem scan is sufficient to trigger the initial database download:

```bash
trivy fs --scanners vuln --no-progress scenarios/S01-spring-node
```

The exact vulnerability result does not matter here. The objective is only to ensure the Trivy database can be downloaded before the workshop.

---

# 8. Warm Syft

```bash
syft scenarios/S01-spring-node -o table >/dev/null
syft version
```

---

# 9. Verify Snyk authentication

```bash
snyk auth
snyk --version
```

Optionally run the T01 baseline:

```bash
cd investigations/T01-snyk-beyond-sbom
./scripts/baseline.sh
cd ../..
```

You do not need to complete T01 before the workshop.

---

# 10. Warm OWASP Dependency-Check / NVD data

This is the most important pre-warm step.

The first Dependency-Check run may need to populate a large local NVD database.

Make sure your NVD key is exported:

```bash
printenv NVD_API_KEY >/dev/null &&
  echo "NVD_API_KEY is exported"
```

Then:

```bash
cd investigations/T06-owasp-dependency-check-s04

./scripts/baseline-s04.sh
./scripts/run-dependency-check-s04.sh

cd ../..
```

Dependency-Check data is stored under:

```text
~/.cache/kcdc-dependency-check/<version>
```

Subsequent runs should reuse that local data.

If you do not have an NVD API key, the current harness falls back to Dependency-Check 12.2.2.

---

# 11. Verify Docker Scout

```bash
docker scout version
```

Then make sure Docker can access the locally built S01/S02 images.

For example:

```bash
docker images | grep -E 'checkout-service|payara-mvnpm-trace-lab'
```

T02 uses `local://IMAGE`, so the relevant scenario image must exist in the local Docker image store.

---

# 12. Final workshop readiness check

```bash
java -version
mvn --version

node --version
npm --version

python3 --version
pip-audit --version

docker version
docker scout version

jq --version
syft version
snyk --version
trivy --version
grype version

printenv NVD_API_KEY >/dev/null &&
  echo "NVD API key: configured" ||
  echo "NVD API key: not configured"
```

Then verify the two base images:

```bash
docker image inspect eclipse-temurin:21-jre-jammy >/dev/null &&
docker image inspect payara/server-web:7.2026.7 >/dev/null &&
echo "Workshop base images ready"
```

If all of these succeed, the machine is ready for the complete workshop as the repository is currently written.
