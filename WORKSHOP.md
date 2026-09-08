# The Route

One page. Where to be, what to run, and which chapter of the manual carries
the detail. The manual is the workshop — every part below is a chapter, and
each chapter opens with its own commands and closes with what you should be
able to do. This card exists so you can find your place again after a break.

Build the manual with `mvn package`, or read the chapters directly in
[`workshop/`](./workshop).

## Before anything

```bash
./scripts/tools-check.sh    # report every tool's version, flag what's missing
./scripts/build-all.sh      # pull images, build S01-S05, warm the scanner DBs
```

If the machine will not cooperate, `./container/run.sh` has all of it inside.

## The four acts

**Act 1 — You can't see what you ship.** Parts 1–2.
**Act 2 — The scanner can't either.** Parts 3–4.
**Act 3 — Someone is counting on that.** Part 5.
**Act 4 — The minimum that keeps you honest.** Part 6.

## Running order

| | Part | Chapter | Labs |
|---|---|---|---|
| 1 | What is actually in our software? | [`workshop/01-supply-chain.md`](./workshop/01-supply-chain.md) | — |
| 2 | Can we identify what we ship? | [`workshop/02-identification.md`](./workshop/02-identification.md) | S01, S04, S08, S05, S03, S02, T01 |
| 3 | What does a CVE finding actually mean? | [`workshop/03-vulnerabilities.md`](./workshop/03-vulnerabilities.md) | T10, T09 |
| — | **Break** | | |
| 4 | CVEs aren't enough | [`workshop/04-project-health-eol.md`](./workshop/04-project-health-eol.md) | Scorecard, deps.dev, EOL scan |
| 5 | Someone is counting on that | [`workshop/05-attacks-and-provenance.md`](./workshop/05-attacks-and-provenance.md) | T08, S07 |
| 6 | The minimum that keeps you honest | [`workshop/06-minimum-practice.md`](./workshop/06-minimum-practice.md) | `ship-check.sh` |

Part 2 is six labs. If one misbehaves, move on rather than debug it.

## The one question

Every lab follows a handful of named dependencies — the **tracked
components** — across build boundaries, asking the same thing at each one:

```text
is it still identifiable here?
```

And of every inventory you are shown: what **evidence** says this is present,
what **identity** is it carrying, and what could be here that this evidence
source structurally cannot show?

## Commands, in run order

The cheat sheet in [`cheatsheet/`](./cheatsheet) is the printable version of
everything below, in the same order, with the output each command should
produce. It builds to `target/cheatsheets.pdf` — that is the thing to print
and keep beside the keyboard.

```bash
# Part 2 — Step 1: build transformations (S01)
cd scenarios/S01-spring-node && ./scripts/build.sh
mvn -pl service dependency:tree -Dincludes=com.fasterxml.jackson.core:jackson-databind
syft service/target/service-1.0.0.jar | grep -i jackson
syft normalizer/target/normalizer-1.0.0.jar
./scripts/strip-codec-metadata.sh
npm --prefix frontend ls lodash
syft frontend/dist

# Part 2 — Step 2: plugin execution realms (S04)
cd scenarios/S04-maven-plugin-hidden-content && ./scripts/build.sh
mvn -Dmaven.repo.local="$PWD/.maven-repo" dependency:tree
./scripts/run.sh && curl -sS http://localhost:8082/hidden/build-info | jq && ./scripts/stop.sh

# Part 2 — Step 3: an SBOM that does see it (S08)
cd scenarios/S08-extended-sbom
./scripts/seed-plugin.sh          # offline machines only
./scripts/scan-s04.sh && ./scripts/scan-s01.sh

# Part 2 — Step 4: lifecycle hooks (S05)
cd scenarios/S05-node-prepack && ./scripts/build.sh
tar -tzf npm-repo/trace-route-package-1.0.0.tgz
./scripts/run.sh && curl -sS http://localhost:8083/hidden/prepack-info | jq && ./scripts/stop.sh

# Part 2 — Step 5: build backends (S03)
cd scenarios/S03-python-pep517 && ./scripts/build.sh
tar -tzf python-repo/tracehook_demo-1.0.0.tar.gz
./scripts/run.sh && curl -sS http://localhost:8081/trace | jq && ./scripts/stop.sh

# Part 2 — Step 6: all of it at once, Jakarta EE (S02)
cd scenarios/S02-payara-mvnpm && ./scripts/build.sh
mvn dependency:tree -Dincludes=org.apache.commons:commons-lang3
mvn dependency:tree -Dincludes=org.mvnpm:lodash-es                 # nothing
mvn -X generate-resources 2>&1 | grep 'org.mvnpm:lodash-es'        # there it is
./scripts/run.sh   # ... then ./scripts/stop.sh

# Part 3 — T10, the Ghostcat record (offline-safe: read evidence/ with jq)
cd investigations/T10-cve-tomcat-85 && jq -r '.containers.cna.metrics' evidence/cve-org.json

# Part 3 — three scanners, one target (needs grype, trivy, osv-scanner)
cd investigations/T09-three-scanners-s01
./scripts/baseline-s01.sh && ./scripts/run-scanners-s01.sh && ./scripts/compare-s01.sh

# Part 4 — lifecycle sweep
npx @herodevs/cli scan eol --dir .

# Part 5 — provenance, layer by layer (S07)
cd scenarios/S07-provenance-s01 && ./scripts/build-baseline.sh && ./scripts/add-provenance.sh

# Part 6 — the drill
./scripts/ship-check.sh scenarios/S01-spring-node
```

Ports: S01 8080, S02 8080, S03 8081, S04 8082, S05 8083.

## Off the route

Reference material, all of it self-study:

- **Reference investigations** — one tool each, same questions, same artefacts:
  [T02 Docker Scout](./investigations/T02-docker-scout/LESSON.md),
  [T03 Trivy](./investigations/T03-trivy-s01/LESSON.md),
  [T04 Grype](./investigations/T04-grype-s02/LESSON.md),
  [T05 pip-audit](./investigations/T05-pip-audit-s03/LESSON.md),
  [T06 OWASP Dependency-Check](./investigations/T06-owasp-dependency-check-s04/LESSON.md),
  [T07 npm audit](./investigations/T07-npm-audit-s05/LESSON.md)
- **Appendices** — [the tools](./reference/tools.md),
  [vulnerability data sources](./workshop/cve-propagation/07-sources.md),
  [AI and the supply chain](./workshop/appendix-ai-dependencies.md) (parked)
- **Instructor notes** — [`FACILITATOR.md`](./FACILITATOR.md)
