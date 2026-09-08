---
id: cheatsheet-setup
oneliner: "Part 1 and the setup behind it: what to run before the workshop, the route in order, and where each stop lives in this book."
track: reference
---

# Part 1 — Start Here

This is the cheat sheet: every command of the route, **in the order you will
run them**, with the output each one should produce. Keep it beside the
keyboard. The manual is what explains why each command is there.

Part 1 is the scene-setting — what counts as the supply chain, and the
question the rest of the workshop asks — so the only thing you type during it
is the machine check below. Everything from Part 2 on has its own card, in
route order.

## Before the workshop

Everything below happens inside a checkout of
<{{ vars.repoUrl }}> — clone it first if you are starting from nothing
(*Getting Started* has the exact commands, and the container route if your
machine will not cooperate).

Run these on a good network, in advance. The pre-warm is the slowest thing in
the whole workshop, and doing it in the room is how people fall behind.

Report the version of every tool the labs need and flag anything missing or too old.
```command
./scripts/tools-check.sh
```

Pull base images, build S01–S05, build the S01/S02 container images, warm the scanner DBs.
```command
./scripts/build-all.sh
```

If your machine cannot be made ready, the workshop container has every tool
and every build inside it:

```command
./container/run.sh
```

Two things `tools-check.sh` flags that are easy to ignore and awkward later:

- **`syft`** — Part 6's drill produces half an answer without it.
- **`grype`, `trivy`, `osv-scanner`** — T09 needs at least two of the three.

Optional, and only for two stops: `snyk auth`, and an `NVD_API_KEY` export.

## The route

| Part | Stops | Where |
|---|---|---|
| 1 — What is actually in our software? | the machine check above — nothing else to type | *this card* |
| 2 — Can we identify what we ship? | S01, S04, S08, S05, S03, S02, T01 | *next card* |
| 3 — What does a CVE finding mean? | Ghostcat, T09 | |
| 4 — CVEs aren't enough | Scorecard, deps.dev, EOL sweep | |
| 5 — Someone is counting on that | T08, S07 | |
| 6 — The minimum that keeps you honest | `ship-check.sh` | |

T02–T07 are off the route and collected at the back.

## Ports

```text
S01 8080 (java -jar)      S03 8081      S05 8083
S02 8080 (Payara)         S04 8082
```

Every `run.sh` has a matching `stop.sh`, and `run.sh` refuses to start if the
port is already busy. If a PID file goes missing:

```command
lsof -nP -iTCP:8082 -sTCP:LISTEN
kill <PID>
```

## The one question

Every lab follows named components — **tracked components** — across build boundaries,
asking the same thing at each one:

```text
is it still identifiable here?
```

And of every inventory you are shown: what **evidence** says this is present,
what **identity** is it carrying, and what could be here that this evidence
source structurally cannot show?
