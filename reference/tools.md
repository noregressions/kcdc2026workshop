---
id: reference-tools
oneliner: "Every tool the workshop touches, grouped by the evidence boundary it observes, with the blind spot each lab demonstrated."
track: reference
---

# The Tools

Every tool in this workshop is competent, so what follows is not a ranking. Each
one observes a particular boundary using particular evidence, and the useful
question about any of them is never "is it good?" but:

```text
Which boundary does it observe,
what evidence does it have there,
and what can that evidence not tell it?
```

Versions used in the recorded walkthroughs are in the
*Prerequisites* chapter's verified baseline.

## Resolvers — the tools that choose

**Maven** resolves declared Java dependencies into concrete versions and, in
doing so, creates evidence the labs lean on constantly: `dependency:tree`,
the effective model, the plugin execution realm. But it answers different
questions from different domains: S04's application tree is *empty* while a
Maven plugin and its transitive payload shape the shipped JAR. The tree
describes the application's dependencies, not the software that built it.

**npm** resolves JavaScript packages and records the result in
`package-lock.json`: resolution evidence good enough that S01 deliberately
preserves it. It also *executes package-owned code* at lifecycle points:
S05's whole story is `prepack` generating runtime code while npm makes the
tarball. `npm ls` sees the graph; nothing in the graph says a script ran.

**pip** resolves Python packages and, under PEP 517, hands control to a
build backend chosen by *the package being installed*: S03's transitive
sdist executes its own build code during `pip install`. The install log is
the only place that execution leaves a trace.

## Inventory producers — the tools that list

**Syft** generates SBOMs from *artefacts*: JARs, directories, container
images. It identifies packages by the metadata they carry, which is exactly
its strength and its boundary. Demonstrated blind spot: in S01, removing
only `META-INF/maven/...` from a shaded JAR (zero bytes of code changed)
made `commons-codec` vanish from the scan; and the Vite bundle containing
lodash's own fingerprints scanned as "no packages discovered".

**CycloneDX Maven Plugin** generates SBOMs from *Maven's model*: the other
side of the producer coin. Same format as a Syft SBOM, legitimately
different contents, because the evidence source is the resolver rather than
the bytes. Demonstrated blind spot: S04's model-derived SBOM contains zero
dependency components while the JAR demonstrably carries plugin-generated
behaviour.

## Vulnerability matchers — the tools that join

These join an inventory against vulnerability data. Everything Part 3
established applies to all of them: the join needs an identity on one side
and an analyst-maintained record on the other, and both sides move.

**Grype** matches Syft-style inventories against its own daily-updated
vulnerability database. It bundles its *own* copy of Syft, a different
version from the standalone one, so its inventory can legitimately differ
from yours (T04). T04 separates its two halves: how the inventory is
constructed versus how matching is done against it.

**Trivy** scans filesystems, repositories and images against the Aqua
vulnerability database, and T03 uses it to ask one question four ways: does
the vulnerability answer change when the same software is seen as a
dependency model, a transformed JAR, a browser bundle, and a container
image? (It does.)

**Docker Scout** treats the *final container image* as the evidence source
(T02): the outermost boundary in the workshop, where the application is a
small fraction of the software present. What it cannot see is everything
that happened before the image existed: source, build, transformation
history.

**npm audit** ships with npm and matches *dependency metadata* against the
npm advisory database. T07's finding: it is metadata-driven end to end.
It never consults physical package contents, and a declared lifecycle
script is not evidence one executed. A clean audit describes the graph, not
the package-production history.

**pip-audit** matches installed Python environments against the PyPA
advisory database. T05 uses it to separate three facts that get conflated:
dependency identity, vulnerability matching, and PEP 517 build execution.
It speaks to the first two and is structurally blind to the third.

**OWASP Dependency-Check** matches evidence it gathers from artefacts
against the NVD: the same CPE machinery Part 3 dissects, which makes it
the honest choice for T06. This workshop picks its version at runtime:
13.0.0 with an `NVD_API_KEY`, 12.2.2 without. T06's result: the
default Maven scan of S04 reports zero dependencies and zero
vulnerabilities while build-time software shaped the JAR.

**Snyk** is the commercial SCA representative (T01), and the point of
including it is fairness: it genuinely knows more than a plain SBOM
(enriched provenance, checksum PURLs, unmanaged-JAR analysis). T01's
conclusion is the workshop's in miniature: *better analysis of available
evidence does not create missing evidence.* It still cannot name S04's
plugin or payload, because nothing in the artefact does.

## Data sources — the records the matchers join against

**CVE.org / the CNA system** is where a vulnerability record is born: a
claim by a numbering authority, with its own affected-version list.
**NVD** enriches those records with CVSS scores and the CPE configurations
scanners actually match on; its change-history API is how the Tomcat
investigation shows a six-year-old record still being edited. **CISA KEV**
adds "confirmed exploited": a catalogue date, not an exploitation date.
Ghostcat's KEV entry arrived two years after its public exploits. **OSV**
(osv.dev) is the open, ecosystem-native alternative keyed by package
coordinates rather than CPEs: a different answer to the identity-matching
problem Part 3 exposes. **Sonatype OSS Index** is the free per-package
lookup in the same spirit: vulnerability data addressed by package
coordinates, used in Part 4 alongside Scorecard's practice signals.

## Utilities — the tools that read

**jq** does the reading everywhere: SBOM comparison in S01, audit output in
T07, four API captures in the Tomcat investigation. **curl** fetches the
primary sources, and the Tomcat investigation stores what it fetched in
`evidence/`, because a workshop about evidence should preserve its own.
**Docker** is both a build boundary (images in S01/S02) and the runtime the
image scanners need.

## Met in Part 4 — health and lifecycle, not vulnerabilities

**OpenSSF Scorecard** scores a repository's *practices* (review, CI,
update hygiene): signals about the chance of future trouble, not knowledge
of present defects, and useful precisely when you follow a check back to
its underlying evidence rather than trusting the aggregate. **Sonatype OSS
Index** is the quick per-package vulnerability lookup, keyed by
coordinates: the fastest way to learn what "not known vulnerable" does and
does not mean. **HeroDevs EOL tooling**
answers the lifecycle question CVE data cannot: not "what is known broken
now" but *who is expected to fix what breaks next*. **OpenEOX** is the
emerging standard for exchanging that lifecycle status machine-readably.
**Dependency-Track** is where SBOMs go to live operationally: continuous
matching of your inventory against advisory data, which makes it the
system that feels record-drift (Part 3) first.

---

One closing observation the labs earn: every tool above did its job
correctly in every walkthrough. The disagreements between them were never
bugs, only different boundaries, honestly observed.
