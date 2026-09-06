---
id: front
oneliner: "Welcome to the KCDC 2026 workshop: the session abstract, what you will leave with, how the morning runs, and how to use this manual."
track: core
---

# Welcome

You are holding the manual for **You Don't Know What You're Shipping**, a
hands-on workshop given at KCDC 2026 by Steve Poole and Brian Vermeer. The
session runs on **Wednesday 9 September 2026, 8:00 am to 12:00 pm Central
Daylight Time (UTC-05:00)**. This manual is written to be worked through at
the keyboard during the session, and to be worth going back to afterwards,
when you point the same tools at your own projects.

## The session

> Every project has dependencies it knows about. Most have dependencies it
> doesn't.
>
> This session is a guided, demo-and-hands-on tour of the modern dependency
> problem. Using free and free-tier tools and public data, we find what is
> actually in your stack, understand what it is doing, and make an informed
> judgement about whether it should be there at all.
>
> Java, Node, Python, Docker: the techniques apply regardless of what you are
> building.
>
> We use Snyk's free tier and the HeroDevs EOL database to map what you have
> and flag what is past safe support, and the OSS Index and the OpenSSF
> Scorecard to see whether the project behind a library follows the security
> practices that make future vulnerabilities less likely.
>
> Exploring the CVE process and its data shows how a record does not always
> say what you think it does, and why end-of-life versions are often secretly
> vulnerable. We look at how in-support vulnerability data can signal what is
> lurking in the versions your scanners are not covering.
>
> We also look at how dependencies get hidden: by accident, by design, and
> occasionally by someone who means you harm. We dissect some AI-generated
> malware, show you a few nasty surprises, and explore how easy it is to let
> the bad stuff in.
>
> We wrap up by examining how AI coding tools are quietly making dependency
> trees larger, picking poor libraries, and hallucinating packages that do
> not exist, and how malicious actors have learned to meet those
> hallucinations with real ones.
>
> Some slides. No theory. Demos, tools, and the kind of findings that make
> you want to go back and check your own projects the moment you get home.

## About KCDC

KCDC, the Kansas City Developer Conference, is a community-run conference for
software developers held each year in Kansas City. Its workshop day gives a
topic room to breathe: a few hours, a laptop, and enough time to run things
rather than watch them. This manual is built for that format. Everything in
it is reproducible on your own machine, and every claim points at the command
that produced it.

## What you will leave with

By the end of the morning you will have done each of the following yourself,
not watched someone else do it:

- **Traced named components across build boundaries** and seen exactly where
  a dependency stops being identifiable: shading and relocation in Java,
  bundling in JavaScript, plugin execution in Maven, lifecycle hooks in npm,
  build backends in Python.
- **Compared what the resolver says with what the artefact contains**, using
  dependency trees, CycloneDX SBOMs, Syft, and scanners such as Snyk, Trivy,
  Grype and Docker Scout, and learned to read each one as evidence from a
  specific boundary rather than as the truth.
- **Read a real CVE record end to end**, watched it change over six years, and
  worked out what had to be true for a scanner to raise a finding from it on
  any given date.
- **Measured project health beyond CVEs**, with OpenSSF Scorecard, the OSS
  Index and end-of-life data, and seen why a clean vulnerability scan on an
  unsupported component means less than it appears to.
- **Seen where build-time execution lets an attacker in**, and how controlled
  ingress, cache integrity and signed provenance close the gap, including an
  image that can prove where it came from.
- **Looked at what AI tooling does to a dependency tree**, and at the
  malware written to exploit it.

The recurring question in every lab is a small one:

```text
is it still identifiable here?
```

The answer, boundary by boundary, is the workshop.

## How the morning runs

```text
Part 1   Supply-Chain Fundamentals               15 min   Architecture Overview
Part 2   Software Identifiability Across Limits  60 min   Hands-on Build Traces
Part 3   Vulnerability Ingestion and CPE Data    35 min   Analysis & API Probes
Break                                            15 min
Part 4   Project Health & Lifecycle EOL Data     25 min   Scorecard & EOL Scanning
Part 5   Malicious Vectors & Defensive Controls  25 min   Provenance & Code Scanning
Part 6   AI Tooling & Dependency Ingress         20 min   Malware Dissection
Part 7   Synthesis & Implementation Framework    10 min   Operational Summary
```

The slot is 240 minutes; the route above uses 205, leaving room for setup
stragglers, questions, and the demos that run long. Parts 2 and 5 are
hands-on labs. The rest mixes short presentation with
guided analysis you follow along with on your own machine.

## How to use this manual

**Before the session**, work through *Introduction and Setup*. The single
most useful thing you can do in advance is to run the readiness check and
the pre-warm, on a good network:

```bash
./scripts/tools-check.sh
./scripts/build-all.sh
```

If your machine cannot be made ready, the workshop container has every tool
and every build already inside it; *Getting Started* explains both routes.

**During the session**, follow `WORKSHOP.md` in the repository. It is the
route: each step names the lab, the commands, and what you should see. The
chapters in Parts 2 to 6 of this manual are the full lessons behind those
steps, with every command, its observed output, and what that output does
and does not establish.

**Afterwards**, the appendices hold the optional labs and the reference
investigations we did not have time for, one per tool, each asking the same
questions of the same artefacts. They are self-study material, and the
scripts in every lab include a proof check so you can confirm the findings
still hold when you re-run them.

Two conventions run through everything:

- Every lab uses **tracers**: specific, named components followed from
  declaration to runtime, so that "the scanner missed it" always means a
  particular thing was missed at a particular boundary.
- Every observed output in this manual was **captured from a real run**, and
  the command that produced it is printed alongside. Versions, counts and
  database dates will drift; the structural findings should not. If one
  does, the proof checks will tell you.

Welcome to KCDC. Let's find out what you're shipping.
