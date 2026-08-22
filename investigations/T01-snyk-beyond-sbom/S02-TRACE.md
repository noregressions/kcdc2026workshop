# T01 / S02 — Snyk Against Payara + mvnpm

This is the second case inside **T01 — Snyk Beyond the SBOM**.

S02 gives us a different kind of missing software from S04.

The tracer is:

```text
org.mvnpm:lodash-es:4.17.21
```

S02 already established:

```text
application project dependency tree
        → no lodash-es

Maven plugin execution realm
        → lodash-es present

esbuild source map
        → lodash-es modules contributed to browser bundle

generated-web Syft scan
        → 0 packages

WAR
        → app.js + app.js.map ship
        → lodash-es package identity absent

WAR Syft scan
        → application + commons-lang3
        → no lodash-es

Maven CycloneDX
        → project-model components
        → no lodash-es
```

T01 now asks:

> Can any Snyk analysis mode recover `lodash-es` after it has moved from Maven plugin dependency identity into bundled JavaScript?

There is also a positive control:

```text
commons-lang3
```

Unlike `lodash-es`, its original Maven JAR survives inside `WEB-INF/lib`. Snyk's unmanaged artefact scanning should therefore have much better evidence to work with.

---

# 1. Re-establish the S02 ground truth

## Run

```bash
./scripts/baseline-s02.sh
```

## Observed output

Capture during walkthrough.

## Establish

Confirm:

```text
lodash-es
    absent from application dependency tree
    present in actual Maven plugin execution realm
    visible in source-map evidence
    absent as identified package from generated-web/WAR Syft views
```

Also record the treatment of:

```text
commons-lang3
Jakarta provided dependencies
```

---

# 2. Run the Snyk probes

## Run

```bash
./scripts/run-snyk-s02.sh
```

The harness performs:

```text
1. normal Snyk Maven test
2. Maven test + --include-provenance
3. Snyk CycloneDX
4. Snyk CycloneDX + --include-provenance
5. unmanaged scan of final WAR
6. unmanaged scan of embedded commons-lang3 JAR
7. recursive unmanaged scan of the unpacked WAR
```

## Observed output

Capture during walkthrough.

---

# 3. Normal Snyk Maven dependency view

## Question

Does Snyk identify:

```text
commons-lang3?
Jakarta provided dependencies?
lodash-es?
esbuild plugin dependencies?
```

## Observed output

Capture during walkthrough.

## Establish

Do not assume Snyk's Maven view is identical to either `dependency:tree` or the Maven CycloneDX output. Record exactly what it emits.

---

# 4. Snyk CycloneDX

## Question

Does Snyk's own SBOM recover anything missing from the Maven-generated CycloneDX?

Particularly:

```text
lodash-es
```

## Observed output

Capture during walkthrough.

## Establish

Compare component identity, not just SBOM format.

---

# 5. Snyk provenance mode

## Question

Does `--include-provenance`:

```text
add fingerprints?
add PURLs?
add components?
recover lodash-es?
```

## Observed output

Capture during walkthrough.

## Establish

Distinguish **identity enrichment** from **broader component discovery**, as T01/S04 already required.

---

# 6. Scan the final WAR directly

## Why

The project model may have lost information that remains in the final bytes.

## Question

Can Snyk identify:

```text
commons-lang3 from the WAR?
lodash-es from bundled JavaScript?
the application WAR itself?
```

## Observed output

Capture during walkthrough.

## Establish

Record whether Snyk can inspect the custom WAR directly and what it can name.

Snyk's current documentation supports individual JAR/WAR/AAR unmanaged scans, while noting limitations for custom-built artefacts.

---

# 7. Positive control — scan `commons-lang3` directly

## Why

We need to know whether a failure to identify `lodash-es` is simply because unmanaged scanning is not working.

The WAR contains the original `commons-lang3` JAR, whose identity should be recoverable from published Maven artefact evidence.

## Observed output

Capture during walkthrough.

## Establish

If Snyk identifies `commons-lang3` here, we have a strong contrast:

```text
original dependency JAR survives
        → package identity recoverable

dependency transformed into JS bundle
        → test whether package identity remains recoverable
```

---

# 8. Scan the unpacked WAR recursively

## Why

Snyk's documentation recommends extracting container archives when you want it to inspect embedded dependency JARs.

## Observed output

Capture during walkthrough.

## Establish

Compare direct WAR inspection with access to the embedded JARs as individual artefacts.

---

# 9. Compare every view

## Run

```bash
./scripts/compare-s02.sh
```

## Observed output

Capture during walkthrough.

## Establish

Complete this matrix:

| Evidence view | commons-lang3 | Jakarta API | lodash-es | Build/bundle provenance |
| --- | --- | --- | --- | --- |
| Maven dependency tree | ? | ? | ? | ? |
| Maven plugin ClassRealm | ? | ? | ? | ? |
| Maven CycloneDX | ? | ? | ? | ? |
| Syft generated-web | ? | ? | ? | ? |
| Syft WAR | ? | ? | ? | ? |
| Snyk Maven test | ? | ? | ? | ? |
| Snyk Maven + provenance | ? | ? | ? | ? |
| Snyk CycloneDX | ? | ? | ? | ? |
| Snyk final WAR | ? | ? | ? | ? |
| Snyk embedded JAR | ? | n/a | n/a | ? |
| Snyk unpacked WAR | ? | ? | ? | ? |

The central T01/S02 question is:

```text
Can a scanner recover package identity after a build transformation
has kept the code but discarded the original package boundary?
```
