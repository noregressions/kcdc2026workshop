# Content backlog

What is still missing from the workshop. Everything else on the original list
is built — see the "Delivered" note at the foot for where each item landed.

## Still to do

- [ ] **Remediation tooling.** Nothing in the route shows how a finding
  actually gets fixed at scale. Candidates: OSV's remediation tooling
  (<https://osv.dev/#use-remediation-tools>), Dependabot/Renovate-style
  automated PRs, and commercial "evergreen" offerings. The interesting angle
  is the one the workshop is built to ask: automated upgrade PRs are
  themselves an ingress path — who reviews them, and against what evidence?
  Natural home: Part 6, after the four decisions.

- [ ] **A tools-and-sites catalogue.** A single reference list of the free
  open-source tooling in this space, beyond the ones the labs happen to use —
  <https://dependencytrack.org/>, <https://osv.dev/>, deps.dev,
  endoflife.date, OpenSSF Scorecard. Natural home: `reference/tools.md`,
  which already has the taxonomy but not the catalogue.

- [ ] **Where the CVE process is going.** CVE 5.x record format, the CNA
  expansion, and the various proposals to fix the enrichment backlog. Part 3
  currently shows the process failing without saying what is being done about
  it. Needs primary sources; do not ship speculation.

## Delivered

| Original item | Where it landed |
|---|---|
| CVE process, Tomcat 8.5 walkthrough, how CPEs work | Part 3 + T10 |
| A CVE is not a point in time but an evolving event | T10 (57 edits over six years) |
| Whether CVEs against older software show up | Part 4 + cve-propagation cards 02 and 06 |
| How forks are or are not tracked | cve-propagation card 03 |
| Malicious dependency types — typosquatting, dependency confusion | Part 5 |
| KEV | Part 3, finding 4 |
| Choosing better components; sites providing CVE + package info | Part 4 (Scorecard, deps.dev) + Part 6's card |
| Assessing a project's future CVE likelihood — Scorecard | Part 4, step 1 |
| EOL, OpenEoX and the key stages; run the EOL tool | Part 4, steps 3 and 4 |
