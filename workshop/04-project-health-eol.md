---
id: workshop-04-project-health-eol
oneliner: "Project maintenance metrics, OpenSSF Scorecard heuristics, and lifecycle support/EOL data analysis."
track: core
status: draft
---

# Part 4: Project Maintenance Metrics and Lifecycle Support

**Target duration:** 25 minutes (guided web and CLI analysis)

## Core Technical Problem

Vulnerability databases record historical security advisories. They do not document upstream support commitments, release cadences, or end-of-life (EOL) timelines:

```text
Historical defect record (CVE) != Future maintenance commitment (Lifecycle/EOL)
```

## Case Study: `lodash` (v4.17.21)

Target characteristics:
- High deployment volume (approx. 71M weekly npm downloads).
- Release timestamp: `4.17.21` published February 2021.
- Analysis across three distinct evidence frameworks: repository practice heuristics, coordinate vulnerability indexing, and software lifecycle datasets.

---

## Step 1: Repository Practice Analysis (OpenSSF Scorecard)

Tool: [OpenSSF Scorecard](https://scorecard.dev) — automated analysis evaluating repository maintenance practices.

Evaluate: `https://scorecard.dev/viewer/?uri=github.com/lodash/lodash` (Reference capture in `evidence/scorecard.json`).

### Captured Scorecard Metrics (Aggregate: 7.2 / 10)

1. **Maintained (10/10):** Measures commit frequency and issue closure within the last 90 days. Commit activity in the main branch does not indicate that patched artifacts are tagged and published to registries.
2. **Vulnerabilities (0/10):** OSV integration query identifying open, unpatched vulnerabilities against the source repository.
3. **Token-Permissions (0/10) & Pinned-Dependencies (4/10):** Measures CI/CD workflow security hygiene (unrestricted `GITHUB_TOKEN` permissions and unpinned build actions).
4. **Signed-Releases (?), Branch-Protection (?), Packaging (?):** Indicates missing verification data or unmonitored release paths.

### Technical Scope of Scorecard

Scorecard measures observable repository hygiene metrics. It does not evaluate compiled runtime safety, semantic code correctness, or vulnerability status of a specific published binary artifact.

---

## Step 2: Coordinate Vulnerability Indexing (Sonatype OSS Index)

Tool: [Sonatype OSS Index](https://ossindex.sonatype.org) — package coordinate vulnerability index (`pkg:npm/lodash@4.17.21`).

### Output Comparison

- **Coordinate Query (`lodash@4.17.21`):** 0 matching vulnerability records. Historical vulnerabilities in prior 4.17.x releases (such as prototype pollution) were remediated in 4.17.21.
- **Scorecard Metric vs Coordinate Query:** Scorecard's `Vulnerabilities: 0` reflects source repository issue tracking, while coordinate lookups query published artifact releases.

A clean vulnerability query confirms only that no defect matching the specified package coordinates is indexed in the queried database at query execution time.

---

## Step 3: Lifecycle and EOL Analysis

Vulnerability records do not document component support windows or EOL deadlines.

Run lifecycle scan against repository dependencies:

```bash
npx @herodevs/cli scan eol --dir .
```

(Fallback data: `evidence/herodevs.report.json`)

### Repository Dependency Lifecycle State

| Component | Usage Boundary | Lifecycle Status |
|---|---|---|
| `jackson-databind:2.19.4` | S01 direct dependency | Active upstream maintenance |
| `commons-codec:1.17.1` | S01 shaded dependency | Active upstream maintenance |
| `lodash:4.17.21` | S01 bundled dependency | No formal lifecycle statement |
| `spring-boot:3.5.12` | S01 runtime framework | **OSS support ended 30 June 2026** |
| `apache-tomcat:8.5` | S02 / CVE investigation subject | **EOL 31 March 2024** |

### Lifecycle State Taxonomy

```text
vulnerable            Known security advisory matched and indexed
not known vulnerable  No active security advisory matches queried coordinates
unsupported / EOL     Upstream vendor/maintainer has ceased triage, patching, and releases
```

When software reaches EOL, upstream vulnerability triage and CVE filing activity decrease. Consequently, scanner silence on EOL components indicates a lack of active upstream monitoring rather than the absence of security defects.

---

## Step 4: Machine-Readable Lifecycle Data (OpenEoX)

Lifecycle information is traditionally distributed across release announcements, documentation tables, and mailing lists.

[OASIS OpenEoX](https://www.oasis-open.org/tc-openeox/) defines an open schema for publishing structured end-of-life and end-of-support records across software ecosystems.

---

## Technical Summary

```text
1. Component presence:       Determined via artifact and build inspection (Part 2)
2. Vulnerability matching:   Determined via CVE and advisory indexes (Part 3)
3. Support / EOL status:     Determined via lifecycle data specifications (Part 4)
```

## References

- OpenSSF Scorecard Documentation: <https://github.com/ossf/scorecard/blob/main/docs/checks.md>
- Sonatype OSS Index: <https://ossindex.sonatype.org>
- Apache Tomcat 8.5 EOL Notice: <https://tomcat.apache.org/tomcat-85-eol.html>
- Spring Boot Support Lifecycle: <https://spring.io/projects/spring-boot#support>
- OASIS OpenEoX Technical Committee: <https://www.oasis-open.org/tc-openeox/>
