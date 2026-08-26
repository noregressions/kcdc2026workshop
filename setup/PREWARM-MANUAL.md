---
id: setup-prewarm-manual
oneliner: "Every pre-warm step done by hand: the manual equivalent of build-all.sh, for understanding a step or debugging its failure."
track: reference
---

# Pre-Warm by Hand

The manual equivalent of `./scripts/build-all.sh`, step by step — see
[`04 PREPULL-PREWARM.md`](./04%20PREPULL-PREWARM.md) for the one-command
route. Follow this if you want to understand each step, or if `build-all.sh`
reports a failure you need to investigate on its own.

## 1. Clone or update the repository

```bash
git clone https://github.com/noregressions/kcdc2026workshop.git
cd kcdc2026workshop
```

If you already have it:

```bash
git pull
```

## 2. Pull the container base images

The repository currently uses exactly two base images:
`eclipse-temurin:21-jre-jammy` (S01) and `payara/server-web:7.2026.7` (S02).

Docker:

```bash
docker pull eclipse-temurin:21-jre-jammy
docker pull payara/server-web:7.2026.7
```

Podman:

```bash
podman pull docker.io/library/eclipse-temurin:21-jre-jammy
podman pull docker.io/payara/server-web:7.2026.7
```

Verify Docker has both images:

```bash
docker image inspect eclipse-temurin:21-jre-jammy >/dev/null
docker image inspect payara/server-web:7.2026.7 >/dev/null

echo "Base images available"
```

## 3. Warm Maven dependencies

Build the Java-based scenarios once. This populates the local Maven
repository with the plugins and dependencies used by the labs.

```bash
cd scenarios/S01-spring-node && ./scripts/build.sh && cd ../..
cd scenarios/S02-payara-mvnpm && ./scripts/build.sh && cd ../..
cd scenarios/S04-maven-plugin-hidden-content && ./scripts/build.sh && cd ../..
```

## 4. Warm npm dependencies

S01 already performs npm installation as part of its build. Also build S05
once — this also proves that npm lifecycle scripts are able to execute in
your environment:

```bash
cd scenarios/S05-node-prepack && ./scripts/build.sh && cd ../..
```

## 5. Warm the Python environment

Build S03 once. The package fixtures used by the S03 scenario are local, so
the core S03 build does not require PyPI:

```bash
cd scenarios/S03-python-pep517 && ./scripts/build.sh && cd ../..
```

## 6. Warm Grype's vulnerability database

```bash
grype db update
grype db status
```

A successful `db status` should show a valid local database.

## 7. Warm Trivy's vulnerability database

A simple filesystem scan is sufficient to trigger the initial database
download. The exact vulnerability result does not matter here — the
objective is only to ensure Trivy can download its database before the
workshop:

```bash
trivy fs --scanners vuln --no-progress scenarios/S01-spring-node
```

## 8. Warm Syft

```bash
syft scenarios/S01-spring-node -o table >/dev/null
syft version
```

## 9. Verify Snyk authentication

```bash
snyk auth
snyk --version
```

Optionally run the T01 baseline (you do not need to complete T01 before the
workshop):

```bash
cd investigations/T01-snyk-beyond-sbom
./scripts/baseline.sh
cd ../..
```

## 10. Warm OWASP Dependency-Check / NVD data

This is the most important pre-warm step: the first Dependency-Check run may
need to populate a large local NVD database.

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

Dependency-Check stores its data under
`~/.cache/kcdc-dependency-check/<version>`; subsequent runs reuse that local
data. If you do not have an NVD API key, the current harness falls back to
Dependency-Check 12.2.2.

## 11. Verify Docker Scout

```bash
docker scout version
```

Then make sure Docker can access the locally built S01/S02 images — T02 uses
`local://IMAGE`, so the relevant scenario image must exist in the local
Docker image store:

```bash
docker images | grep -E 'checkout-service|payara-mvnpm-trace-lab'
```

## 12. Final workshop readiness check

```bash
./scripts/tools-check.sh
```

plus the T06 key and the two base images:

```bash
printenv NVD_API_KEY >/dev/null &&
  echo "NVD API key: configured" ||
  echo "NVD API key: not configured"

docker image inspect eclipse-temurin:21-jre-jammy >/dev/null &&
docker image inspect payara/server-web:7.2026.7 >/dev/null &&
echo "Workshop base images ready"
```

If all of these succeed, the machine is ready for the complete workshop as
the repository is currently written.
