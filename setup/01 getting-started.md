---
id: setup-getting-started
oneliner: "Clone the repository, check your tools, install what's missing, warm everything up: the four commands that make you workshop-ready."
track: core
---

# Getting Started

Two ways in. **The container is the zero-install path** — the only thing
your machine needs is Docker. The local install gives you everything
natively.

## Option A — the workshop container (install only Docker)

Install Docker Desktop (or Docker Engine on Linux) and make sure the
machine has **~20GB of free disk** — two container images plus build
headroom. Then from the repository root:

```bash
./container/build.sh     # or: docker pull <published image, when available>
./container/run.sh
```

Every tool is preinstalled, every lab prebuilt, and the scanner databases
are already downloaded — the shell you land in is workshop-ready. Run
`./scripts/tools-check.sh` inside it to confirm.

It is two images under the hood — a big, rarely-changing tools image and a
small workshop-code image on top — so when the workshop content updates,
re-running `./container/build.sh` (or re-pulling) only fetches the small
part.

Two things to know:

- The container drives **your** Docker daemon through a mounted socket, so
  the images S01/S02 build appear on your machine and their published
  ports are reachable from your own browser.
- The S03/S04/S05 servers bind inside the container — run their `curl`
  commands in the container shell, exactly as WORKSHOP.md prints them.

Have a Snyk token or NVD key? Export `SNYK_TOKEN` / `NVD_API_KEY` before
`./container/run.sh` and they pass through.

## Option B — local install, four steps

Do them before the workshop on a good network; the opening presentation
includes time to re-run them and fix stragglers.

## 1. Clone the repository

```bash
git clone https://github.com/noregressions/kcdc2026workshop.git
cd kcdc2026workshop
```

If you already have it:

```bash
git pull
```

## 2. Check your tools

```bash
./scripts/tools-check.sh
```

This reports the version of every tool the workshop uses, flags anything below
the minimum, and prints an installation link for anything missing. It installs
nothing and changes nothing.

## 3. Install anything missing

Follow the links `tools-check.sh` printed, or use the full install guide in
the next chapter: it has copy-paste commands for macOS and Debian/Ubuntu.

Then re-run the check until it reports ready:

```bash
./scripts/tools-check.sh
```

## 4. Warm everything up

```bash
./scripts/build-all.sh
```

This pulls the two container base images, builds all five scenarios, builds
the scenario container images, and downloads the scanner vulnerability
databases. It starts no servers and leaves nothing running.

It prints a summary of what passed, what failed, and what was skipped and why.
Exit status is non-zero if anything failed.

## You are ready when

```text
tools-check.sh   exits 0 (optional tools may still be absent)
build-all.sh     reports 0 failed
```

That is everything. The workshop itself starts at Part 1.

The remaining chapters in this section are the reference detail behind these
four steps: exact version requirements, the two credentials some optional
material uses, and what `build-all.sh` warms up. The full per-OS install
transcripts and the manual equivalent of every pre-warm step live alongside
them in the repository, in `setup/INSTALL.md` and `setup/PREWARM-MANUAL.md`.
