---
id: setup-getting-started
oneliner: "Clone the repository, check your tools, install what's missing, warm everything up — the four commands that make you workshop-ready."
track: core
---

# Getting Started

Four steps. Do them before the workshop on a good network; the opening
presentation includes time to re-run them and fix stragglers.

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
the next chapter — it has copy-paste commands for macOS and Debian/Ubuntu.

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

That is everything. The workshop itself starts at Part 1, and its opening
presentation deliberately leaves room to re-run these two commands and flag an
instructor if either misbehaves.

The remaining chapters in this section are the reference detail behind these
four steps: exact version requirements, the full install guide, the two
credentials some optional material uses, and the manual equivalent of
`build-all.sh`.
