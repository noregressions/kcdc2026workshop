---
id: setup-prewarm-manual
oneliner: "Step-by-step manual execution procedures corresponding to build-all.sh."
track: reference
---

# Manual Pre-Warm Procedures

Manual execution instructions corresponding to `./scripts/build-all.sh`. Use these commands for targeted debugging of specific build or cache initialization failures.

## 1. Clone or Update Repository

```bash
git clone https://github.com/noregressions/kcdc2026workshop.git
cd kcdc2026workshop
```

To update:

```bash
git pull
```

## 2. Pull Container Base Images

Base images utilized across scenarios: `eclipse-temurin:21-jre-jammy` (S01) and `payara/server-web:7.2026.7` (S02).

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

Verify image presence:

```bash
docker image inspect eclipse-temurin:21-jre-jammy >/dev/null && \
docker image inspect payara/server-web:7.2026.7 >/dev/null && \
echo "Base images available"
```

## 3. Warm Maven Dependencies

Compile Java scenario modules to populate the local repository cache (`~/.m2/repository`):

```bash
cd scenarios/S01-spring-node && ./scripts/build.sh && cd ../..
cd scenarios/S02-payara-mvnpm && ./scripts/build.sh && cd ../..
cd scenarios/S04-maven-plugin-hidden-content && ./scripts/build.sh && cd ../..
```

## 4. Warm npm Dependencies

Install npm dependencies and validate execution of package lifecycle hooks:

```bash
cd scenarios/S05-node-prepack && ./scripts/build.sh && cd ../..
```

## 5. Warm Python Environment

Initialize the Python virtual environment and local package dependencies:

```bash
cd scenarios/S03-python-pep517 && ./scripts/build.sh && cd ../..
```

## 6. Initialize Grype Vulnerability Database

```bash
grype db update
grype db status
```

Confirm that `db status` reports an initialized local database.

## 7. Initialize Trivy Vulnerability Database

Execute a filesystem scan against S01 to populate the local Trivy vulnerability database:

```bash
trivy fs --scanners vuln --no-progress scenarios/S01-spring-node
```

## 8. Initialize Syft Cache

```bash
syft scenarios/S01-spring-node -o table >/dev/null
syft version
```

## 9. Verify Snyk CLI Authentication

```bash
snyk auth
snyk --version
```

Optional baseline execution:

```bash
cd investigations/T01-snyk-beyond-sbom
./scripts/baseline.sh
cd ../..
```

## 10. Initialize OWASP Dependency-Check NVD Cache

Export `NVD_API_KEY`:

```bash
printenv NVD_API_KEY >/dev/null && echo "NVD_API_KEY is exported"
```

Run initialization:

```bash
cd investigations/T06-owasp-dependency-check-s04
./scripts/baseline-s04.sh
./scripts/run-dependency-check-s04.sh
cd ../..
```

Local vulnerability data is cached in `~/.cache/kcdc-dependency-check/<version>`.

## 11. Verify Docker Scout Integration

```bash
docker scout version
```

Verify local scenario images are accessible in the local image registry:

```bash
docker images | grep -E 'checkout-service|payara-mvnpm-trace-lab'
```

## 12. Complete Verification Check

```bash
./scripts/tools-check.sh
printenv NVD_API_KEY >/dev/null && echo "NVD API key: configured" || echo "NVD API key: not configured"
docker image inspect eclipse-temurin:21-jre-jammy >/dev/null && \
docker image inspect payara/server-web:7.2026.7 >/dev/null && \
echo "Workshop base images ready"
```
