# T02 — Docker Scout

Docker Scout investigation for the container-producing workshop scenarios.

Completed coverage:

```text
S01  Spring + Node
S02  Payara + mvnpm
```

## Run S01

```bash
./scripts/baseline-s01.sh
./scripts/run-scout-s01.sh
./scripts/compare-s01.sh
```

## Run S02

```bash
./scripts/baseline-s02.sh
./scripts/run-scout-s02.sh
./scripts/compare-s02.sh
```

All Scout commands target `local://IMAGE` so the scan is performed against the exact locally built scenario image.

See `TRACE.md` for the observed evidence and cross-tool conclusions.
