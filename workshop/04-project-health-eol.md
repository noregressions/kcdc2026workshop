---
id: workshop-04-project-health-eol
oneliner: "Project health signals, OpenSSF Scorecard, EOL and OpenEOX: who is expected to fix what breaks next."
track: core
status: draft
---

# Introduction

**Target duration:** 25 min guided web investigation. Browser for most of it,
one terminal command near the end.

Part 3 ended with a CVE record that changed its answers over six years without
the software changing at all. This part asks the question no CVE database can
answer, however carefully you read it:

```text
When the next vulnerability lands in this dependency,
who is expected to fix it?
```

A CVE lookup is a statement about the past. Choosing a dependency is a bet on
the future. This part is about the evidence you can gather for that bet.

**The investigation subject:** `lodash`. You already met it in Part 2, where
it went into a JavaScript bundle and vanished from every scan. It is about as
well-adopted as open source gets: roughly 71 million npm downloads a week.
Its last stable release, 4.17.21, shipped in early 2021. Both of those facts
matter, and they pull in opposite directions. We read this one dependency
through the practice lens and the vulnerability lens, then finish with a
lifecycle sweep across the workshop's own dependencies.

The Scorecard numbers below come from the captured report in `evidence/`
(Scorecard v5.0.0, generated 2026-08-18). Live scores will have drifted:
that is fine, and noticing the drift is part of the point.

---

## Step 1 — What do the project's practices say? (~9 min)

Tool: [OpenSSF Scorecard](https://scorecard.dev), which runs automated checks
against a repository's observable practices and scores each 0–10, with an
aggregate on top.

**Question:** what does the project's observable behaviour say about how the
next problem would be handled?

**Do this:** open the viewer at
<https://scorecard.dev/viewer/?uri=github.com/lodash/lodash>
(fallback: the captured report in `evidence/`).

**Observed when captured:** an aggregate of **7.2**, assembled from pieces
that deserve to be read separately. Five of them do real work here:

- **Maintained: 10.** Scorecard's definition of "actively maintained" is
  recent commit and issue activity. Hold that against the release history:
  the last stable release is from 2021. Both facts are true at once, because
  *activity* and *shipping* are different acts. A repository can be busy for
  years without a fix ever reaching the artefact you actually depend on.
- **Vulnerabilities: 0.** The check asks whether OSV knows of open, unfixed
  vulnerabilities for the project, and here it fails outright. Park this one:
  Step 2 will appear to contradict it, and the contradiction is the lesson.
- **Token-Permissions: 0** and **Pinned-Dependencies: 4.** The project's own
  build pipeline: workflow tokens broader than needed, build dependencies
  mostly unpinned. After Part 2 you know exactly why a build pipeline is
  attack surface.
- **Signed-Releases: ?** Along with Branch-Protection and Packaging, the
  captured report shows a question mark: Scorecard could not gather the
  evidence, and *says so*. Treasure that. Most dashboards would have printed
  a number anyway. An honest "can't see" is rarer than it should be.

And the aggregate? A single 7.2 summarising a 10 for maintenance, a 0 for
vulnerabilities and three question marks. That is what an aggregate score
*is*: somebody's chosen checks under somebody's chosen weights, flattened
into one comfortable number. Use the pieces; be suspicious of the summary.

**While you have the repository open**, sweep the ordinary signals by hand:
date of the last release, contributor activity, whether issues get responses,
the security policy (Scorecard gave it 10: verify that it names a real
reporting route), any statement of supported versions. Every one of these is
a signal, and not one of them is a guarantee.

**What Scorecard does NOT say:** anything about whether the code is any good,
whether it fits your use, or whether *your* shipped version is vulnerable. It
measures repository practice. An old, stable, finished library can score
badly and be fine; a busy project can score well and ship a disaster next
Tuesday. And a high score is not a promise: nobody behind any of these
numbers is offering to fix lodash.

**Checkpoint before continuing:**

- [ ] You can explain how Maintained scores 10 while the last release is
      years old.
- [ ] You can say why the three "?" scores are more honest than a number.
- [ ] You can name one thing a perfect Scorecard would still not tell you.

---

## Step 2 — What does a vulnerability database say? (~4 min)

Tool: [Sonatype OSS Index](https://ossindex.sonatype.org), free vulnerability
data keyed by package coordinates (purl format: `pkg:npm/lodash@4.17.21`).

**Question:** what does a clean vulnerability lookup actually mean?

**Do this:** look up `pkg:npm/lodash@4.17.21`. (The service has had
availability wobbles; a captured response will live in `evidence/` for the
days it is having a bad day — *capture pending, see FACILITATOR.md*. The
capture is also the polite option on conference wifi.)

**Expected observation:** no known vulnerabilities for 4.17.21. Earlier 4.17
releases carry known CVEs, prototype pollution among them, which 4.17.21
fixed.

Now un-park Step 1. Scorecard's Vulnerabilities check scored **0**, meaning
OSV knows of open, unfixed vulnerabilities; the coordinate lookup for the
published 4.17.21 package comes back clean. Both results are honest. They ask
different databases different questions at different boundaries: one looks at
the project and what it drags in, the other at one published artefact's
coordinates. This is Part 2's lesson wearing new clothes: before you trust
any finding, ask *which evidence source, at which boundary*. When two tools
disagree, chase the disagreement (the viewer lets you expand the check and
see exactly which advisories it counted); don't just pick the answer you
prefer.

**The reading:** a clean lookup means exactly one thing: *not known
vulnerable*, in that database, at those coordinates, today. Hold that
thought, because the next step makes it worse in an interesting way.

---

## Step 3 — Who is expected to fix what breaks next? (~8 min)

Every lens so far described the past and the present. None of them answered
the question at the top of this part. That answer is *lifecycle* data, and it
lives nowhere in a CVE record.

**Declared interest:** I work for HeroDevs, whose business is supporting
software past its end of life, and whose tooling this step uses because it is
the tooling I know best. Every lifecycle fact below is checkable against the
projects' own announcements, and you should check.

**Do this:** from the repository root (any directory with dependency
manifests works):

```bash
npx @herodevs/cli scan eol --dir .
```

The scan needs a HeroDevs login the first time (`npx @herodevs/cli auth
login`); if you would rather not, read along with the captured
`evidence/herodevs.report.json` instead (*capture pending, see
FACILITATOR.md*). The CLI builds an SBOM from what is actually there and
reports lifecycle status per component. No dependencies are installed or
modified.

**Expected observation, against this workshop's own dependencies:**

| Component | Where you met it | Lifecycle status |
|---|---|---|
| jackson-databind 2.19.4 | S01 control | supported, actively maintained |
| commons-codec 1.17.1 | S01 shading leg | supported |
| lodash 4.17.21 | S01 bundling leg | no lifecycle statement exists, dormant in practice |
| Spring Boot 3.5.12 | S01 itself runs on it | **OSS support ended 30 June 2026** |
| Tomcat 8.5 | Part 3's Ghostcat subject | **EOL 31 March 2024** |

(Status wording is paraphrased; the live report's labels will differ.
The lifecycle *facts* are checkable at the links in the references.)

Read that fourth row again. The scenario you built with your own hands in
Part 2 runs on a framework whose open-source security patches stopped before
this workshop was delivered. Nobody chose that dramatic effect; the calendar
did. Spring Boot 4.0 is the next branch to age out, at the end of 2026: today's
"supported" is next year's sweep finding.

**Three different states, and they are not one axis:**

```text
vulnerable            a known defect exists, recorded, matchable
not known vulnerable  no recorded defect matches — the ONLY thing a clean scan means
unsupported           whatever is found next, nobody upstream is expected to fix it
```

The third state is a different *kind* of fact from the first two, and it is
the one scanners are structurally bad at showing you. After EOL, the reporting
pipeline itself winds down: researchers move on, maintainers stop triaging,
fewer reports reach the CVE process at all. The dependency keeps working.
Scanners keep showing green. The green now means "nobody is watching", and it
looks identical to "nothing is wrong". Spring Boot 2.7 is the precedent:
CVE-2024-38807 surfaced after its EOL, with no open-source patch ever coming.
(The long version of this argument is in
[Crossing the River Styx](https://foojay.io/today/crossing-the-river-styx-spring-boot-3-5-and-the-zombie-dependency-problem/),
the companion piece to Part 3's article.)

**Checkpoint before continuing:**

- [ ] You can state the difference between "not known vulnerable" and "safe".
- [ ] You can say what scanner silence means for software that is past EOL.
- [ ] You know which of this workshop's own dependencies are past EOL.

---

## OpenEoX, briefly (~2 min)

You just saw four lifecycle answers delivered four different ways: Tomcat
announced EOL on a mailing list and a web page, Spring publishes a support
table, Jackson's status lives in project communications, and lodash has never
said anything at all. Humans can read all that, slowly. Machines cannot, and
Step 3 only worked because someone curates those sources into a dataset by
hand.

[OpenEoX](https://www.oasis-open.org/tc-openeox/) is the OASIS technical
committee working on exactly this: a standard, machine-readable format for
exchanging end-of-life and end-of-support information, from vendors and
open-source projects alike. The Core Schema 1.0 went out for public comment
in July 2026. When lifecycle status becomes as queryable as CVE data, the
Step 3 question stops needing a specialist dataset to answer.

That is the whole pitch; the standards detail stays in the reference section
where it belongs.

---

## Conclusion

```text
CVE data tells us what is known to be broken now.
Lifecycle data helps tell us who is expected to fix what breaks next.
```

Which completes the model this workshop has been assembling all day:

```text
What is present?                      (Part 2 — and it was hard)
What is known to be vulnerable?       (Part 3 — and it moves)
Who is expected to maintain/fix it?   (Part 4 — and silence is not an answer)
```

**You should now know:** how to read health signals as signals rather than
verdicts; what a clean vulnerability lookup does and does not claim; and why
lifecycle status is a separate question from vulnerability status, with its
own evidence sources.

**Transition:** everything demonstrated so far, in the whole workshop, has
been legitimate behaviour honestly observed. Part 5 asks what happens when
someone uses the same machinery on purpose.

---

## References

- OpenSSF Scorecard checks documentation: <https://github.com/ossf/scorecard/blob/main/docs/checks.md>
- Scorecard viewer for lodash: <https://scorecard.dev/viewer/?uri=github.com/lodash/lodash>
- Sonatype OSS Index: <https://ossindex.sonatype.org>
- Apache Tomcat 8.5 EOL announcement: <https://tomcat.apache.org/tomcat-85-eol.html>
- Spring Boot support timeline: <https://spring.io/projects/spring-boot#support>
- HeroDevs EOL Dataset CLI: <https://docs.herodevs.com/eol-ds/getting-started>
- OASIS OpenEoX TC: <https://www.oasis-open.org/tc-openeox/>
- Steve Poole, *Crossing the River Styx: Spring Boot 3.5 and the Zombie Dependency Problem*, foojay.io, April 2026
