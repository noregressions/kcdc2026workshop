# Software Supply Chain Trace Lab

A hands-on workshop about what you can and cannot know about the software you
ship.

Every scenario in this repository takes a component you declared, follows it
through a real build, and asks the same question at each boundary: **is it still
identifiable here?** Sometimes it is. Often the code survives while the evidence
of what it was does not.

The labs are deliberately small, but the builds are real — Maven, npm, Vite,
esbuild, Maven Shade, Spring Boot, PEP 517, npm lifecycle hooks, Docker. Nothing
is faked or stubbed.

## The central idea

A dependency declaration, a resolved dependency graph, a packaged artefact, an
SBOM and a container image are five different observations, made at five
different points, from five different evidence sources. They are not
interchangeable, and they routinely disagree for entirely legitimate reasons.

```text
source configuration
        ↓
resolver model
        ↓
build transformation
        ↓
application artefact
        ↓
SBOM producer
        ↓
container image
```

The workshop's recurring finding is that **software presence and software
identifiability are different questions.** A build can preserve behaviour
perfectly while destroying every trace of where that behaviour came from.

## Attending the workshop?

**Go straight to [`WORKSHOP.md`](./WORKSHOP.md)** — the timed, canonical route.
You are not expected to work through every scenario and investigation in this
repository; the workshop route selects what matters and links to the rest.

## Getting started

You need a JDK 21+, Maven 3.9+, Node.js 20+, Python 3.11+ and Docker. Full
details and install commands are in [`setup/`](./setup).

**1. Check your machine.** Reports the version of every tool the workshop uses,
flags anything too old, and prints an install link for anything missing. Changes
nothing.

```bash
./scripts/tools-check.sh
```

**2. Warm it up.** Pulls the container base images, builds all five scenarios,
builds the scenario container images, and downloads the scanner databases. Do
this *before* the workshop, on a good network — it is the difference between
starting on time and watching Maven download.

```bash
./scripts/build-all.sh
```

Add `--with-investigations` to also run the T01–T07 baselines. That is slower,
and the T06 step downloads a large NVD dataset the first time.

**3. Pick a lab.** Each scenario and investigation has two documents:

```text
OVERVIEW.md   what it is, what it needs, and how to run it
TRACE.md      the annotated step-by-step walkthrough
```

Start with the overview, then work through the trace:

```bash
cd scenarios/S01-spring-node
cat OVERVIEW.md
cat TRACE.md
```

## Scenarios

Five supply chains, each hiding software somewhere different.

| | Lab | What it follows |
|---|---|---|
| **S01** | [`Spring + Node`](./scenarios/S01-spring-node) | An ordinary Java dependency, a shaded-and-relocated one, and an npm package bundled into frontend JavaScript — through to a container image |
| **S02** | [`Payara + mvnpm`](./scenarios/S02-payara-mvnpm) | Four kinds of software through one build into one running container, including a package that reaches the bundle only via a Maven **plugin** execution realm |
| **S03** | [`Python PEP 517`](./scenarios/S03-python-pep517) | A direct dependency into a transitive sdist, through PEP 517 **build-backend execution**, into the installed environment and runtime |
| **S04** | [`Maven plugin hidden content`](./scenarios/S04-maven-plugin-hidden-content) | Runtime capability entering an application through **Maven plugin execution** rather than its dependency graph — the application's dependency tree is empty |
| **S05** | [`Node npm prepack`](./scenarios/S05-node-prepack) | A package through an npm **lifecycle hook** into a tarball, into `node_modules`, and into runtime behaviour |

## Investigations

Seven tools pointed at those scenarios, asking what each one can actually see.

| | Investigation | Against |
|---|---|---|
| **T01** | [`Snyk beyond the SBOM`](./investigations/T01-snyk-beyond-sbom) | All five scenarios, with a cross-scenario matrix |
| **T02** | [`Docker Scout`](./investigations/T02-docker-scout) | S01, S02 (the container-producing scenarios) |
| **T03** | [`Trivy`](./investigations/T03-trivy-s01) | S01 |
| **T04** | [`Grype`](./investigations/T04-grype-s02) | S02 |
| **T05** | [`pip-audit`](./investigations/T05-pip-audit-s03) | S03 |
| **T06** | [`OWASP Dependency-Check`](./investigations/T06-owasp-dependency-check-s04) | S04 |
| **T07** | [`npm audit`](./investigations/T07-npm-audit-s05) | S05 |

The point is not to rank the tools. It is to see which boundary each one
observes, and what that choice makes visible or invisible.

## How a walkthrough is structured

Every step in every `TRACE.md` follows the same five beats, so you always know
which part is argument and which part is evidence:

```text
Why we need to do this      the question this step answers
How we're going to do it    what the command does, and why this one
Run                         the command
Observed output             what it actually printed
Establish                   what that does and does not prove
```

The `Observed output` blocks are real captured output, not illustrations. If
yours differs, that is worth investigating — versions and vulnerability
databases move.

## Conventions

The scenarios share a common script interface. S01 has no runtime, so it has
no `run.sh` or `stop.sh`:

| Script | Does |
|---|---|
| `./scripts/build.sh` | Build it |
| `./scripts/run.sh` | Start the runtime |
| `./scripts/stop.sh` | Stop it — **run this when you finish a lab** |
| `./scripts/clean.sh` | Return to a known-clean state |
| `./scripts/proof-check.sh` | Assert the walkthrough's claims still hold |

Several scenarios also have a trace helper (`trace.sh`, `trace-mvnpm.sh`,
`trace-python.sh`, `trace-plugin.sh`) that replays the core evidence sequence in
one pass, once you have already been through it step by step.

**Ports.** The scenarios use distinct ports so they can run side by side:

```text
S02   8080      S04   8082
S03   8081      S05   8083
```

`run.sh` refuses to start if its port is already busy, and each detached runtime
is tracked in `.runtime.pid`. If you skip `stop.sh`, the next `run.sh` will tell
you.

**`proof-check.sh`** is how you find out whether a walkthrough has gone stale.
It asserts the structural claims — which components appear, which are omitted.
Note that some also assert exact vulnerability counts, and those *will* drift as
databases change; a failure there means the recorded numbers need refreshing,
not that the lesson broke.

## Repository layout

```text
FACILITATOR.md    instructor-side notes: timings, expected outputs, failure playbook
setup/            prerequisites, accounts and keys, pre-pull and pre-warm
scenarios/        S01-S05, each with an OVERVIEW.md and a TRACE.md
investigations/   T01-T07, each with an OVERVIEW.md and a TRACE.md
scripts/          tools-check.sh, build-all.sh
pom.xml           builds the whole workshop as a single PDF
```

The `README.md` in each lab directory is a short pointer for browsing the
repository on GitHub. The content lives in `OVERVIEW.md`, because the book
build skips files named `README.md`.

## Building the workshop as a book

The `setup/`, `scenarios/` and `investigations/` markdown is assembled into one
PDF:

```bash
mvn package
# -> target/book.pdf   (US Letter, running headers, page numbers)
```

The table of contents is generated — after adding, removing or materially
resizing content, refresh its page numbers:

```bash
./scripts/generate-toc.sh
```

## Prerequisites in full

- [`setup/00 about.md`](./setup/00%20about.md) — what the workshop is for, the
  approach it takes, and how to read a trace
- [`setup/01 intro.md`](./setup/01%20intro.md) — required versions, and the
  versions the walkthroughs were recorded against
- [`setup/02 tools.md`](./setup/02%20tools.md) — install commands for macOS and
  Linux, plus notes on using Podman
- [`setup/03 ACCOUNTS-AND-KEYS.md`](./setup/03%20ACCOUNTS-AND-KEYS.md) — Snyk
  authentication and the NVD API key
- [`setup/04 PREPULL-PREWARM.md`](./setup/04%20PREPULL-PREWARM.md) — what
  `build-all.sh` automates, and the manual equivalent

Two things are worth knowing before you start:

- **Docker is the canonical engine.** Podman works for the S01/S02 container
  build and run stages, but the scripts invoke `docker` directly, and T02 needs
  Docker Scout, which Podman does not provide.
- **An NVD API key changes T06.** With `NVD_API_KEY` set, T06 uses
  Dependency-Check 13.0.0; without it, 12.2.2. Both work, but they are not the
  same tool version.

## License

Apache License 2.0 — see [`LICENSE`](./LICENSE).
