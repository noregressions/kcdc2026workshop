# Slide Deck Outline — You Don't Know What You're Shipping

> **STALE 2026-09-08 — needs a re-cut, not an edit.** This outline was built
> against the seven-part route. The book has since been restructured into six
> parts in four acts, the AI strand is parked, Part 5 is rebuilt attack-first,
> and the wrap-up became a hands-on Part 6. Four of the six conflicts recorded
> at the foot of this document are now closed by that restructure — see the
> updated *Conflicts to resolve* section. Slide numbering and the
> `workshop/0X:NN` line references below are out of date.

KCDC 2026 workshop, 240-minute slot. Built from two sources:

- **`WORKSHOP.md` and the book** (`target/book.pdf`) — the 7-part timed route, 205 minutes, and the labs that already exist and have verified output.
- **`outline.txt`** — the loose planning notes, which carry an A–E structure, several demos, and a whole regulation strand that the book has no material for.

Where the two disagree, this outline follows the book's Part 1–7 numbering, because that is what the manual, the cheat sheets and the labs are all built around. Everything `outline.txt` asks for that the book cannot supply is carried below as an explicit `[PLACEHOLDER]`. See [Conflicts to resolve](#conflicts-to-resolve) and [Placeholder inventory](#placeholder-inventory) at the end.

**Slide count: 113, of which 30 carry a placeholder.**

Notation:

- **[SLIDE]** — a slide you present.
- **[DRIVER]** — a slide that stays up while the room works: commands on the left, expected output on the right. The cheat sheets are the attendee-side copy of these, so a driver slide should not say anything the cheat sheet does not.
- **[PLACEHOLDER]** — content that does not exist anywhere in the repo yet. The note says what is missing and where it would have to come from.

---

## Section 0 — Holding and open (before the clock starts)

1. **[SLIDE] Title.** *You Don't Know What You're Shipping.* KCDC 2026, Wednesday 9 September 2026, 8:00–12:00 CDT. Steve Poole, Brian Vermeer.
   Source: `setup/frontpiece.md:7`.
2. **[SLIDE] Do this now.** Repo URL, `./container/run.sh` or `./scripts/tools-check.sh`, then `./scripts/build-all.sh`. Runs on the screen from the moment the doors open, because the pre-warm is the long pole.
   `[PLACEHOLDER: public repo URL and a QR code. The README references the published image noregressions/ydnwys-workshop:0.0.1 but no repo URL exists in the repo.]`
3. **[SLIDE] Who we are.** Two presenters, one line each on why this problem.
   `[PLACEHOLDER: bios. The pom.xml author vars are commented out (pom.xml:113).]`
4. **[SLIDE] Housekeeping.** Two breaks (15 min after Part 3, short one later), ask questions as they land, flag a red sticky if a command fails.
5. **[SLIDE] Ground rules for the labs.** Every claim in the manual points at the command that produced it. Versions and counts are the invariants; PIDs, digests and timestamps will differ on your machine.
   Source: `cheatsheet/00-setup.md`, `setup/frontpiece.md`.

---

## Section 1 — Framing (part of Part 1's 15 min)

6. **[SLIDE] The premise, one line.** "Every project has dependencies it knows about. Most have dependencies it doesn't."
   Source: `setup/frontpiece.md:16`.
7. **[SLIDE] The scene.** A short, concrete hook before any theory — the thing that makes the room lean in.
   `[PLACEHOLDER: outline.txt Part A says only "Set the scene …". Options: a named incident (xz, event-stream, ua-parser-js, Log4Shell-as-inventory-problem), or the linked article https://foojay.io/today/security-doesnt-start-at-liftoff/. Pick one and write it. This is the slide the whole deck hangs off.]`
8. **[SLIDE] The recurring question.** `is it still identifiable here?` — asked at every boundary, all morning. This slide comes back as a divider before each lab.
   Source: `setup/frontpiece.md:86`.
9. **[SLIDE] What you will leave with.** Six outcomes, each one "you will have done this, not watched it": traced components across build boundaries; compared resolver against artefact; read a real CVE end to end; measured health beyond CVEs; seen where build-time execution lets an attacker in; looked at what AI does to a tree.
   Source: `setup/frontpiece.md:61`.
10. **[SLIDE] Objectives.** Explain why discovery is hard and how attackers exploit the gaps; read scanner output critically; run the minimum practice every release; explain why AI-speed discovery and incoming regulation make this urgent now.
    Source: `outline.txt`. Note the fourth objective is the regulation strand, which currently has no slides — see 87–89.
11. **[SLIDE] How the morning runs.** The timing table. 240-minute slot, 205-minute route, and say out loud that the slack is deliberate.
    Source: `setup/frontpiece.md:94`, `WORKSHOP.md:39`.

---

## Part 1 — Supply-Chain Fundamentals (15 min, slide-led)

12. **[SLIDE] What counts as your supply chain.** The full span: source development, component selection, test execution, dependency resolution, build-time code execution, packaging transformations, repository distribution, runtime environments, lifecycle and EOL. Deliberately wider than the room expects.
    Source: `workshop/01-supply-chain.md:12`.
13. **[SLIDE] Every way software gets in.** Direct dependencies, transitive graphs, build plugins, build engines, execution runtimes (JDK/Node/Python), base images, OS packages.
    Source: `workshop/01-supply-chain.md`.
14. **[SLIDE] The boundary model.** The five-boundary diagram: source declarations → resolved graph → plugin execution realms → bundled/shaded artefact → runtime and container. This is the deck's spine; every later slide says which boundary it is standing on.
    Source: `workshop/01-supply-chain.md`, `README.md:7`.
15. **[SLIDE] The question this morning answers.** *Can you determine the complete set of software components present in a deployed artifact?*
    Source: `workshop/01-supply-chain.md`.
16. **[SLIDE] Why anyone should care.** Vulnerability correlation, patch remediation, compliance verification, provenance tracking, security auditing. Kept short — the labs make the case better than this slide does.
    Source: `workshop/01-supply-chain.md`.
17. **[DRIVER] Environment check.** `./scripts/tools-check.sh` then `./scripts/build-all.sh`. Ports the labs will use: S01 8080, S02 8080, S03 8081, S04 8082, S05 8083.
    Source: `WORKSHOP.md`, `cheatsheet/`.

---

## Part 2 — Software Identifiability Across Boundaries (60 min, hands-on)

18. **[SLIDE] Part 2 roadmap.** S01 (15) → S04 (15) → S05 (8) → S03 (8) → T01 (5) → synthesis. Say which are labs and which are watch-along.
    Source: `workshop/02-identification.md:12`.
19. **[SLIDE] Declared, resolved, shipped.** Three columns, three different answers, one project. The frame for every lab that follows.
    Source: `WORKSHOP.md:65`.

### S01 — Build transformations and metadata stripping (15 min)

20. **[SLIDE] S01: three tracked components, three fates.** `jackson-databind` the control, `commons-codec` shaded and relocated, `lodash` bundled by Vite. Say up front which one survives.
    Source: `scenarios/S01-spring-node/LESSON.md:42`.
21. **[DRIVER] Control baseline.** `mvn dependency:tree -Dincludes=...jackson-databind`, then `syft service/target/service-1.0.0.jar | grep -i jackson`. Both say `2.19.4`. Establishes that the method works before it is used to show a failure.
    Source: `WORKSHOP.md:82`.
22. **[DRIVER] Shading and relocation.** `syft normalizer/target/normalizer-1.0.0.jar`, then `./scripts/strip-codec-metadata.sh` and scan again. `commons-codec:1.17.1` → nothing. Bytecode untouched.
    Source: `WORKSHOP.md:93`.
23. **[SLIDE] What just happened.** The scanner was reading `META-INF/maven/...`, not code. Presence and identifiability came apart, and nothing about the running program changed.
    Source: `WORKSHOP.md:112`.
24. **[DRIVER] Frontend bundling.** `npm ls lodash` says `4.17.21`; grep finds `__lodash_hash_undefined__` and the version string in the minified bundle; `syft frontend/dist` returns *No packages discovered*.
    Source: `WORKSHOP.md:102`.
25. **[SLIDE] Two versions of commons-codec, and why.** The one the resolver names and the one physically present, in the same JAR, for a reason the build explains.
    Source: `scenarios/S01-spring-node/LESSON.md:706`.
26. **[DRIVER] SBOM from the manifest vs SBOM from the binary.** Maven CycloneDX against the POM, Syft against the finished JAR, diffed side by side. `outline.txt` calls for this explicitly and S01 steps 19–22 already produce it.
    Source: `scenarios/S01-spring-node/LESSON.md:775`–`955`.
27. **[DRIVER] Into the container.** S01 step 23: the image scan, and what a container scanner adds and drops relative to the JAR scan.
    Source: `scenarios/S01-spring-node/LESSON.md:990`.

### S04 — Build plugin execution realms (15 min)

28. **[SLIDE] S04: an empty dependency graph that ships a live endpoint.** The setup in one picture: `trace-injector-maven-plugin` generates code at build time, `trace-route-payload` rides in through the plugin's realm.
    Source: `scenarios/S04-maven-plugin-hidden-content/LESSON.md:25`.
29. **[DRIVER] Ask the resolver.** `mvn dependency:tree` reports only the root artifact. Then `mvn dependency:resolve-plugins`, then the actual plugin ClassRealm — three questions, three different answers.
    Source: `WORKSHOP.md:116`, `scenarios/S04-maven-plugin-hidden-content/LESSON.md:216`–`314`.
30. **[DRIVER] Then ask the artefact.** `unzip -l ... | grep -E 'Generated|services'`, `./scripts/run.sh`, `curl /hidden/build-info`. Generated class in the JAR, live route in the running app, nothing in the graph.
    Source: `WORKSHOP.md:116`.
31. **[DRIVER] Then ask the scanners.** Syft on the final JAR, Maven CycloneDX on the model. Both clean.
    Source: `scenarios/S04-maven-plugin-hidden-content/LESSON.md:493`–`558`.
32. **[SLIDE] What just happened.** Resolvers evaluate the *application* graph. Build plugins execute in their own realm, and that realm is not indexed by anything the room was using.
    Source: `WORKSHOP.md:136`.
33. **[SLIDE] Optional: a second SBOM generator sees it.** S08's SBOM+ lists the plugin and its payload as `excluded` build tooling, with the path that brought them in — 0 components becomes a named path. Show the diff only; the lab is go-deeper material.
    Source: `WORKSHOP.md:138`, `scenarios/S08-extended-sbom/LESSON.md`.

### S05 — Package lifecycle hooks (8 min)

34. **[SLIDE] S05: the package generates itself while packing.** `prepack` runs `generate-dist.js` before the tarball exists.
    Source: `scenarios/S05-node-prepack/LESSON.md:17`.
35. **[DRIVER] Source vs tarball vs installed.** `tar -tzf` the tgz, then `curl /hidden/prepack-info`. `dist/` files in the artefact are absent from the repository source.
    Source: `WORKSHOP.md:140`.
36. **[SLIDE] What just happened.** Package code executes before the distributable exists, so the thing you audit and the thing you publish are different things. Hold this thought — Part 5 turns exactly this mechanism malicious.
    Source: `WORKSHOP.md:157`.

### S03 — Python PEP 517 build backends (8 min)

37. **[SLIDE] S03: the build backend writes the package.** The sdist ships `pyproject.toml` and `tracehook_backend.py`. That is all.
    Source: `scenarios/S03-python-pep517/LESSON.md:13`.
38. **[DRIVER] sdist vs site-packages.** `tar -tzf` the sdist, then `ls .venv/lib/python*/site-packages/tracehook_demo/`, then `curl /trace`. The imported package was manufactured during `pip install`.
    Source: `WORKSHOP.md:161`.
39. **[SLIDE] What just happened.** Installing an sdist executes dependency-supplied code, and that code can create software that was never in source.
    Source: `WORKSHOP.md:179`, `scenarios/S03-python-pep517/LESSON.md:625`.

### T01 — Commercial SCA, and where it stops (5 min)

40. **[SLIDE] Does paying for it fix this?** Snyk against the same five scenarios: what it knows that an SBOM does not — richer intelligence, provenance enrichment, reachability.
    Source: `investigations/T01-snyk-beyond-sbom/LESSON.md:954`–`975`.
41. **[SLIDE] The T01 scorecard.** The cross-scenario matrix: which transformations stay invisible even to a good commercial tool.
    Source: `investigations/T01-snyk-beyond-sbom/LESSON.md:914`.
42. **[SLIDE] The line that will not move.** "Algorithmic analysis cannot reconstruct evidence omitted during build transformations." Also: provenance *enrichment* is not provenance *reconstruction*.
    Source: `WORKSHOP.md:183`, `investigations/T01-snyk-beyond-sbom/LESSON.md:985`.
43. **[SLIDE] Why good scanners are still a life saver.** The counterweight to the last three slides, so the room does not leave Part 2 thinking scanning is pointless. Snyk, Sonatype: what they buy you that you will not build yourself.
    `[PLACEHOLDER: outline.txt lists this under "Essential" but there is no repo material arguing the positive case. Needs writing — probably one slide of "what T01 got right" plus one of "what you would have to build to replace it".]`

### Synthesis (the slide people photograph)

44. **[SLIDE] The evidence boundary matrix.** Five evidence sources — manifest, resolver, SBOM, artefact scanner, image scanner — each with what it observes and its systematic blind spot.
    Source: `WORKSHOP.md:193`, `workshop/02-identification.md`.
45. **[SLIDE] How code hides.** Renamed and relocated classes, payloads in resources, build-time injection, generated content with no history of its own. Names the mechanisms the four labs just demonstrated, plus the ones they did not.
    Source: `outline.txt` Part A; partly covered by S01/S04. `[PLACEHOLDER: "payloads in resources" has no lab behind it — either cite published research or drop the bullet.]`
46. **[SLIDE] Dissect a real malicious package.** Manifest says one thing, binary does another, from published research rather than a fixture.
    `[PLACEHOLDER: outline.txt Part A asks for this. Nothing in the repo. T08 has synthetic malicious fixtures (good ones) but they are ours, not a real published case. Needs a case picked and sourced — and a decision on whether it lives here or in Part 5 next to T08, where it fits better.]`
47. **[SLIDE] Scanner comparison visualiser.** One project, several tools, the disagreement shown rather than described.
    `[PLACEHOLDER: outline.txt "Others". T02–T07 each point one tool at one scenario, so the repo has the raw material but not a same-project comparison. Either build the comparison or cut the slide.]`

---

## Part 3 — Vulnerability Records and CPE Matching (35 min, guided analysis)

48. **[SLIDE] The finding pipeline.** `software → identity → package/product mapping → CVE record → affected versions → scanner matching → finding`. Seven steps, every one of which can fail quietly.
    Source: `workshop/03-vulnerabilities.md:12`.
49. **[SLIDE] Meet Ghostcat.** CVE-2020-1938, Apache Tomcat 8.5. Chosen because the record has six years of history and every failure mode in it.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:7`.
50. **[DRIVER] Read the CNA record, then read what NVD added.** Live and captured JSON in `investigations/T10-cve-tomcat-85`.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:39`, `:82`.
51. **[SLIDE] Three severities, one vulnerability.** Apache CNA "Important" vs NVD CVSS v2 7.5 vs NVD CVSS v3.1 9.8 CRITICAL. Ask which one your dashboard shows.
    Source: `workshop/03-vulnerabilities.md:20`.
52. **[SLIDE] What a CPE actually is.** `cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*` pulled apart field by field, and the range `8.5.0` to `< 8.5.51`. Everything downstream is a string match against this.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:128`.
53. **[DRIVER] Who else is in the record.** 38 CPE configurations, 20 of them embedded Oracle distributions — added 26 months after publication.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:177`.
54. **[DRIVER] The record is a changelog.** `nvd-history.json`: watch the record change under a scanner that was "correct" on every date.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:243`.
55. **[SLIDE] KEV, and the two-year gap.** Public exploit February 2020; CISA KEV catalogue March 2022.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:307`.
56. **[SLIDE] The missing branch.** EOL Tomcat 6.x omitted from the structured ranges despite the vulnerable code. Contrast CVE-2025-24813: EOL 8.5 named in prose, unbounded CPE range `* < 9.0.99`. Two records, two incompatible conventions.
    Source: `investigations/T10-cve-tomcat-85/LESSON.md:347`, `:407`.
57. **[SLIDE] So what is a scanner finding?** A point-in-time join between identifiers extracted from an artefact and CPE ranges upstream. Both halves move.
    Source: `workshop/03-vulnerabilities.md:38`.
58. **[SLIDE] False positives and false negatives, by construction.** Backports and custom builds match ranges they should not; forks and renamed packages match nothing.
    Source: `workshop/03-vulnerabilities.md:38`, `content-todo.md`.
59. **[SLIDE] Where the CVE process is going.** KEV, and the direction of travel.
    `[PLACEHOLDER: content-todo.md notes "talk about KEV, gold eagle where CVE process is going". KEV is covered at 55; the forward-looking half is not written. Needs a decision on scope — CVE Program funding turbulence, CNA growth, EUVD, CVE 5.x records?]`
60. **[SLIDE] Chat app demo: how long until it gets fixed?** An app on old dependencies, and the clock from advisory to available fix to deployed fix.
    `[PLACEHOLDER: outline.txt B2. No repo material at all. Needs the app, the dependency set, and the timeline. Largest single build in this deck — consider cutting to a slide of published data instead.]`
61. **[SLIDE] Q&A.** `outline.txt` puts a Q&A slot around here; the book route does not. Ten minutes before the break is the natural home.

---

## Break (15 min)

62. **[SLIDE] Break.** Back-at time, and the Part 4 command on screen so anyone who wants a head start can pre-warm `npx @herodevs/cli scan eol --dir .`.

---

## Part 4 — Project Health and Lifecycle EOL (25 min, guided)

63. **[SLIDE] The inequality.** `Historical defect record (CVE) != Future maintenance commitment (Lifecycle/EOL)`. Part 3 was the left side; this is the right.
    Source: `workshop/04-project-health-eol.md:12`.
64. **[SLIDE] Case: lodash 4.17.21.** 71M weekly downloads, published February 2021. Three evidence frameworks about to give three different pictures.
    Source: `workshop/04-project-health-eol.md:20`.
65. **[DRIVER] OpenSSF Scorecard.** `scorecard.dev/viewer/?uri=github.com/lodash/lodash`, aggregate 7.2/10.
    Source: `workshop/04-project-health-eol.md:29`.
66. **[SLIDE] Reading Scorecard honestly.** Maintained 10/10 measures commits, not releases. Vulnerabilities 0/10 measures repository issues, not published artefacts. Token-Permissions 0/10 and Pinned-Dependencies 4/10 measure CI hygiene. Missing data shows as `?`.
    Source: `workshop/04-project-health-eol.md:29`.
67. **[SLIDE] What Scorecard is not.** No runtime safety, no semantic correctness, no verdict on a specific published binary.
    Source: `workshop/04-project-health-eol.md:44`.
68. **[DRIVER] Coordinate indexing.** *Rewritten 2026-09-08 — OSS Index is retired (301 to guide.sonatype.com, API 401). Use deps.dev:* `lodash@4.17.21` → three advisory IDs, two distinct defects. Then the before-and-after: this repo's own OSS Index capture said zero, the artefact has not changed since February 2021, and the tool that produced the zero no longer exists.
    Source: `workshop/04-project-health-eol.md:48`.
69. **[DRIVER] The EOL sweep.** `npx @herodevs/cli scan eol --dir .` against this repo, with `evidence/herodevs.report.json` as the fallback.
    Source: `workshop/04-project-health-eol.md:61`.
70. **[SLIDE] The lifecycle table.** jackson-databind 2.19.4 supported; commons-codec 1.17.1 supported; lodash 4.17.21 no formal policy; spring-boot 3.5.12 **OSS support ended 30 June 2026**; apache-tomcat 8.5 **EOL 31 March 2024**. Two of the five, in the room's own workshop repo.
    Source: `workshop/04-project-health-eol.md:61`, `WORKSHOP.md:258`.
71. **[SLIDE] Three states, not two.** `vulnerable` / `not known vulnerable` / `unsupported (EOL)`. Most tools only speak the first two.
    Source: `workshop/04-project-health-eol.md:61`.
72. **[SLIDE] Why silence gets quieter after EOL.** Nobody files CVEs against dead branches. A clean scan on an unsupported component measures the absence of triage, not the absence of defects.
    Source: `workshop/04-project-health-eol.md:88`.
73. **[SLIDE] Trace a fix backwards.** Take a fix in a supported release and walk it back through the EOL versions a scanner calls green.
    `[PLACEHOLDER: outline.txt Part B asks for this and it is the most persuasive slide in Part 4. No worked example in the repo. Tomcat 8.5 vs 9.x is the obvious candidate and the CVE-2025-24813 material at slide 56 is half of it already.]`
74. **[SLIDE] Machine-readable lifecycle data.** OASIS OpenEoX: why lifecycle facts currently live in blog posts and mailing lists, and what a schema changes.
    Source: `workshop/04-project-health-eol.md:95`.
75. **[SLIDE] Quick lookups you will actually use.** endoflife.date, deps.dev, OSV, Scorecard — the four-tab habit. *(OSS Index removed 2026-09-08; retired.)*
    Source: `outline.txt` Part C. `[PLACEHOLDER: deps.dev and endoflife.date appear only in outline.txt, with no walkthrough anywhere in the repo. One live lookup each would do it.]`
76. **[SLIDE] Three scanners, one project, different answers.** Snyk free tier, OSV-Scanner, Grype on the same target, and why they disagree.
    `[PLACEHOLDER: outline.txt Part B. The repo has T03 (Trivy on S01) and T04 (Grype on S02) — different tools on different scenarios, so this comparison does not exist yet. Also note OSV-Scanner and osv.dev appear nowhere in the repo (content-todo.md flags osv.dev as still to cover).]`

---

## Part 5 — Malicious Execution Vectors and Defensive Controls (25 min)

77. **[SLIDE] Everything in Part 2 was an attack surface.** Re-show the four mechanisms as capabilities an attacker wants: plugin ClassRealms (arbitrary bytecode at compile time), lifecycle hooks (`prepack`, `postinstall`, unsandboxed), build backends (PEP 517 codegen), and ingress.
    Source: `workshop/05-integrity-provenance.md:12`.
78. **[SLIDE] Getting in: dependency confusion.** The mechanism in one diagram — internal name, public registry, resolution order.
    `[PLACEHOLDER: outline.txt Part 2C and content-todo.md both call for this; there is no repo material. Needs the mechanism diagram and one real published case.]`
79. **[SLIDE] Getting in: typosquatting.** Name distance, install-time execution, the numbers on how well it works.
    `[PLACEHOLDER: same as above — asked for twice, written nowhere.]`
80. **[SLIDE] Getting in: maintainer compromise.** Account takeover and the trusted-update path.
    `[PLACEHOLDER: outline.txt names account takeover in the ingress list (workshop/05-integrity-provenance.md:12 repeats it) but no slide content exists.]`
81. **[DRIVER] T08: turn S05 malicious.** Same `prepack` mechanism, payload in the generator. `./scripts/scan-malicious.sh` scans both hiding places.
    Source: `investigations/T08-guarddog/LESSON.md:222`, `:284`.
82. **[SLIDE] Catch, miss, and why.** The T08 result table: malicious A tarball silent 0.0 (generator excluded by `files: ["dist"]`); malicious A source fired 8.2; malicious B tarball fired 8.2 (payload shipped in `dist`). Same attack, two hiding places, opposite verdicts.
    Source: `investigations/T08-guarddog/LESSON.md:350`.
83. **[SLIDE] Benign S05 and S03 both score 0.0/10 too.** And they should. A code scanner that flagged them would flag every legitimate build. This is the honest limit, not a bug.
    Source: `workshop/05-integrity-provenance.md:20`, `investigations/T08-guarddog/LESSON.md:381`.
84. **[SLIDE] Defence 1 — controlled ingress.** Staging proxy, checksum verification, namespace reservation, explicit licence and policy validation.
    Source: `workshop/05-integrity-provenance.md:27`.
85. **[SLIDE] Defence 2 — cache and artefact integrity.** Digests against published checksums, immutable signature chains, tamper detection in local and remote caches.
    Source: `workshop/05-integrity-provenance.md:27`.
86. **[SLIDE] Defence 3 — layered reverse provenance.** The four-layer stack, each layer labelled with what it actually proves: embedded `git.properties` (unsigned internal claim) → OCI annotations (unsigned image claim) → Syft CycloneDX keyed to digest (unsigned content claim) → Cosign + in-toto (cryptographically verifiable).
    Source: `workshop/05-integrity-provenance.md:35`, `scenarios/S07-provenance-s01/LESSON.md:86`–`144`.
87. **[DRIVER] S07: from anonymous image to signed attestation.** `./scripts/build-baseline.sh` — an image that cannot name its origin — then `./scripts/add-provenance.sh` and the reverse audit, second time.
    Source: `WORKSHOP.md:292`, `scenarios/S07-provenance-s01/LESSON.md:41`, `:172`.
88. **[SLIDE] Digests, not tags.** And what S07 explicitly does *not* prove.
    Source: `scenarios/S07-provenance-s01/LESSON.md:201`.
89. **[SLIDE] Basic defences, on one slide.** The checklist form of 84–88, for photographing.
    Source: `outline.txt` Part 2D.

---

## Part 6 — AI and the Supply Chain (20 min)

`outline.txt` says "Do AI as a separate part" and lists four topics the book's Part 6 does not cover at all (MCPs, AIBOMs, model versions and agent guards, prompts-as-shippable-code). This section is where the deck is thinnest relative to ambition: 20 minutes of route against roughly 35 minutes of listed material.

90. **[SLIDE] Machine-speed vulnerabilities, human-speed fixes.** The framing for the whole part.
    Source: `outline.txt` Part D.
91. **[SLIDE] What LLM codegen does to a dependency tree.** Depth and volume up; selection biased toward training-set frequency rather than health, maintenance or minimal surface area.
    Source: `workshop/06-ai-dependencies.md:12`.
92. **[SLIDE] Hallucinated packages.** The mechanism: models predict plausible names across npm and PyPI namespaces; automated tooling runs `npm install` on the result.
    Source: `workshop/06-ai-dependencies.md:12`.
93. **[SLIDE] Slopsquatting.** Attackers register the hallucinated names for real.
    `[PLACEHOLDER: outline.txt insists on published research and primary sources. The term appears nowhere in the repo. Needs the paper and the numbers.]`
94. **[DRIVER] Watch an assistant do it.** Let an AI coding assistant add a feature, then audit what it pulled in: tree depth before and after, health of what it picked, and whether every name resolves.
    `[PLACEHOLDER: outline.txt Part D asks for this demo. No fixture, no script, no captured evidence in the repo. Needs building, and it needs to be deterministic enough to run live — consider recording it.]`
95. **[SLIDE] AI-generated malware, dissected.** Generation patterns, evasion, execution triggers.
    `[PLACEHOLDER: workshop/06-ai-dependencies.md:12 describes this as a module and frontpiece.md promises the room will see it, but there are no AI malware fixtures in the repo. T08's fixtures are hand-written, not AI-generated. Needs sourcing plus the non-networked sandbox the outline requires.]`
96. **[SLIDE] EOL as the undefended backlog.** AI-speed discovery aimed at code nobody is triaging any more. Joins Part 4 to Part 6 and is the strongest argument in the deck.
    Source: `outline.txt` Part D. `[PLACEHOLDER: the join is asserted in outline.txt but not written up anywhere.]`
97. **[SLIDE] MCP servers as a new ingress surface.** Another install-and-execute channel, with weaker convention around pinning and review than npm had.
    `[PLACEHOLDER: outline.txt "Essential". Nothing in the repo.]`
98. **[SLIDE] AIBOMs.** What they are, what they would have to record (model, weights, version, training provenance, prompts), and how far the CycloneDX/SPDX work has got.
    `[PLACEHOLDER: outline.txt "Essential". Nothing in the repo.]`
99. **[SLIDE] Model versions and agent guards.** Pinning a model is a dependency decision; an unguarded agent is an ingress path.
    `[PLACEHOLDER: outline.txt "Essential". Nothing in the repo.]`
100. **[SLIDE] Prompts and skills are shippable code.** They are versioned, distributed, executed, and they can be malicious — so they belong under the same ingress controls as everything else.
     `[PLACEHOLDER: outline.txt "Essential", and the most original claim on the list. Nothing in the repo. Worth two slides if it survives.]`
101. **[SLIDE] Same boundaries, same controls.** AI-suggested dependencies traverse resolution, transformation and packaging exactly like any other, so Part 5's controls apply unchanged. The reassuring close to an alarming section.
     Source: `workshop/06-ai-dependencies.md:30`.

---

## Section 7 — Regulation (5 min; not in the book route)

`outline.txt` makes regulation the fourth objective and asks for "one slide each, primary sources only". The book has no regulation content whatsoever. Budget is not allocated for it in the 205-minute route — it fits in the 35 minutes of slack, or Part 7 absorbs it.

102. **[SLIDE] The bar has been raised.** Why a compliance slide belongs in a technical workshop: the evidence these regulations want is exactly the evidence Parts 2–5 showed you cannot currently produce.
     `[PLACEHOLDER: framing to be written.]`
103. **[SLIDE] EU Cyber Resilience Act.** Obligations, dates, who is in scope.
     `[PLACEHOLDER: primary sources only, per outline.txt. Nothing in the repo.]`
104. **[SLIDE] US regulation.** EO/OMB/CISA attestation requirements, SBOM expectations.
     `[PLACEHOLDER: primary sources only. Nothing in the repo, and "US" is all outline.txt says — scope needs deciding.]`

---

## Part 7 — Synthesis and Implementation (10 min)

105. **[SLIDE] The whole model, one picture.** Six boundary transitions: source declaration → dependency resolution → build execution → artefact packaging → containerization → cryptographic provenance.
     Source: `workshop/07-wrap-up.md:12`.
106. **[SLIDE] The data overlay.** CVE/NVD/OSV as point-in-time defect records; CISA KEV as exploitation status; Scorecard as observable practice; OpenEoX and support datasets as maintenance horizon. Four datasets, four different questions.
     Source: `workshop/07-wrap-up.md:30`.
107. **[SLIDE] The minimum that keeps you informed.** Inventory the artefact and not just the manifest, every build. More than one scanner, plus a lifecycle check. Keep current deliberately. Judge before adopting.
     Source: `outline.txt` Part C, `workshop/07-wrap-up.md:37`.
108. **[SLIDE] The five-item checklist.** Differential SBOM generation and diff; CPE matching audit; lifecycle horizon audit; Scorecard on direct dependencies; lockfile integrity verification.
     Source: `workshop/07-wrap-up.md:37`, `WORKSHOP.md:350`.
109. **[SLIDE] Decision path for a finding.** upgrade → patch in-house → accept → buy support. A flow, not a list, and honest about what each costs.
     Source: `outline.txt` Part C. `[PLACEHOLDER: the four options are named in outline.txt but the decision criteria between them are not written anywhere.]`
110. **[SLIDE] When the answer is "buy support".** HeroDevs Never-Ending Support as the drop-in option for the EOL components Part 4 found.
     Source: `outline.txt` ("Closing decision path names HeroDevs NES as the drop-in option"). Placed here, after the decision path, so it reads as one branch of four rather than a pitch.
111. **[SLIDE] Remediation tooling.** Auto-PR bots and remediation tools: what they buy and where they bite.
     `[PLACEHOLDER: content-todo.md asks for this ("need to show remediation tools, including evergreen", osv.dev remediation tools, "auto PR stuff? any good or dangerous?"). Nothing in the repo. Cut if Part 7 is tight.]`
112. **[SLIDE] Take it home.** The cheat-sheet PDF, the repo, the manual, and the one command to re-run any lab (`./scripts/proof-check.sh`).
     *Resolved 2026-09-08:* Part 6 now carries the one-page card (`workshop/06-minimum-practice.md`), and the cheat sheet is route-ordered in `cheatsheet/`. Promise both: the card is the one-pager, the cheat sheet is the reference.
113. **[SLIDE] Thanks, links, questions.** Repo, the cheat sheet, the tooling reference, <https://foojay.io/today/security-doesnt-start-at-liftoff/>.
     `[PLACEHOLDER: QR and final URL list.]`

---

## Conflicts to resolve

These are places where `outline.txt` and the book do not agree. Each needs a decision before the deck is built, because they change the running order.

1. ~~**Structure.**~~ **CLOSED 2026-09-08.** The book was re-cut to six parts in four acts, mapped to the three surviving objectives: Act 1 (Parts 1–2) discovery is hard; Act 2 (Parts 3–4) reading scanner output critically; Act 3 (Part 5) how attackers exploit the gaps; Act 4 (Part 6) the minimum practice. This is the plan. The deck needs re-cutting against it.
2. **Where provenance and attestations live.** *Still open, but narrowed.* `outline.txt` Part 1B puts provenance immediately after the build-transformation labs; the book keeps S07 in Part 5. Part 5 is now attack-first, which strengthens the book's placement — S07 reads as the answer to "how would you even know", rather than as a defences miscellany. Decide before the deck.
3. ~~**Part 6 is oversubscribed.**~~ **CLOSED 2026-09-08 — by descoping.** The AI strand is off the route; the material is parked as `workshop/appendix-ai-dependencies.md`. Its 20 minutes went to Part 5 (+10) and Part 6, the minimum-practice drill (+10).
4. **Regulation has no budget.** *Still open, and now also off-objective* — the CRA/US strand was objective four, which is descoped alongside AI. Drop the slides or reinstate the objective; do not leave them unbudgeted.
5. **Q&A placement.** `outline.txt` schedules a Q&A block; the book route does not. Slide 61, before the break, is the natural slot but it is unbudgeted.
6. ~~**Three labs are in neither book edition.**~~ **CLOSED 2026-09-08.** `investigations/T10-cve-tomcat-85` is now in Part 3, and `investigations/T08-guarddog` and `scenarios/S07-provenance-s01` are in Part 5 — both editions. T08 was deliberately removed from the Reference Investigations appendix so it is not duplicated.

## Placeholder inventory

30 of 113 slides. Grouped by what it would take to close them.

**Needs writing only — material exists or it is a judgement call (8):** 3 bios, 43 why-scanners-help, 45 how-code-hides, 96 EOL-as-backlog, 102 regulation framing, 109 decision criteria, 112 one-pager decision, 113 links and QR.

**Needs external sourcing — published research or primary sources (8):** 7 the-scene hook, 46 real malicious package, 59 where-CVE-is-going, 93 slopsquatting, 97 MCPs, 98 AIBOMs, 103 CRA, 104 US regulation.

**Closed by the 2026-09-08 restructure (partially):** 109 decision criteria and 112 one-pager are now written — Part 6 carries the four-decision path and the take-home card, backed by `scripts/ship-check.sh`. Slides 93, 97–100 (AI) are parked with the strand.

**Needs a lab or demo built (7):** 47 scanner visualiser, 60 chat-app fix-timeline, 73 trace-a-fix-backwards, 75 endoflife.date and deps.dev lookups, 76 three-scanners-one-project, 94 AI assistant audit, 95 AI-generated malware fixtures.

**Needs a position taken, then written (7):** 2 repo URL and QR, 78 dependency confusion, 79 typosquatting, 80 maintainer compromise, 99 model versions and agent guards, 100 prompts-as-shippable-code, 111 remediation tooling.

The seven demo builds are the schedule risk. Cheapest high-value closures, in order: 73 (trace a fix backwards — half the material is already in the CVE-2025-24813 slide), 76 (three scanners — T03 and T04 exist, they just need pointing at one target), 75 (two live web lookups), 78 and 79 (mechanism diagrams, no code).
