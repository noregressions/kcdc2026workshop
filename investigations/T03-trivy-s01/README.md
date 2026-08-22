# T03 — Trivy / S01

One CVE tool against one supply-chain scenario.

## Scenario

```text
S01 — Spring + Node
```

## Tool

```text
Trivy 0.74.0
```

## Question

How does Trivy's package and vulnerability view change across:

```text
Maven POM
npm lockfile
shaded JAR
metadata-stripped shaded JAR
Spring Boot JAR
bundled frontend
final container image
```

## Run

From `investigations/T03-trivy-s01`:

```bash
./scripts/baseline-s01.sh
./scripts/run-trivy-s01.sh
./scripts/compare-s01.sh
```

For targeted reruns:

```bash
./scripts/run-trivy-nonarchives-s01.sh
./scripts/run-trivy-archives-s01.sh
```

Java archives are scanned with `trivy rootfs`; source dependency models use `trivy fs`; the container uses `trivy image --image-src docker`.

See `TRACE.md` for the observed evidence and conclusions.
