<!--
Mirror of the Claude Doc "You Don't Know What You're Shipping: Talk Outline",
https://claude.ai/code/artifact/ac5b324a-d45f-40a3-bb2e-e01f08098e48
Exported at doc rev 21 on 3 October 2026. The doc is the working copy; re-export
after editing it. The running-order chart is shown here as a table.
-->

# You Don't Know What You're Shipping: Talk Outline

Oct 2, 2026 · @Steve

## Summary

The talk is a 50-minute cut of the KCDC workshop for Dev2Next, presented solo with no audience participation. The slot is 60 minutes: 50 of talk and 10 of Q&A. It keeps the workshop's question, "is it still identifiable here?", and its strongest demos, and adds the AI and malware material the abstract promises.

- **Reused:** about 35 of the 50 minutes come from labs and evidence that already exist and have proof checks. Most are shown from captured output; two or three run live.
- **New:** the last third of the abstract has no material yet. That means a dissected AI-generated malware sample, and the AI coding-assistant section on tree growth, hallucinated packages and slopsquatting.
- **Where it lives:** in this repository as a second paperband edition, with a `talk/` folder for the runsheet and the new cards. The scenario cheat sheet is a take-home for anyone who wants to run the labs afterwards.

Lab names below follow the current route numbering: S1 is `spring-node`, S2 `maven-plugin-hidden-content`, S3 `extended-sbom`, S4 `node-prepack`, S5 `python-pep517`, S6 `payara-mvnpm`, S7 `provenance-s01`.

## Running order

| Segment | Minutes | Built from |
| --- | --- | --- |
| 0. Open: dependencies it doesn't know about | 3 | Existing labs |
| 1. Hidden by accident, hidden by design | 12 | Existing labs |
| 2. The data doesn't say what you think | 12 | Existing labs |
| 3. Someone means you harm | 11 | GuardDog lab plus new malware material |
| 4. AI makes all of it faster | 9 | New |
| 5. Close: the minimum | 3 | Existing labs |
| **Total** | **50** | |

Segments 0 to 2 and 5 are built from existing labs. Segment 3 pairs the existing GuardDog lab with new malware material, and segment 4 is entirely new.

## Segment by segment

Each segment follows the abstract's order and ends on one line the audience should be able to repeat. "Live" means typed on stage; "captured" means real output from the repo shown on a slide or replayed.

### 0. Open: dependencies it doesn't know about (3 min)

- Cold open on the S2 reveal: `curl` an endpoint, get JSON back, then show that no source file defines it. Captured, so the open can't fail.
- State the one question: is it still identifiable here?
- **Lands:** presence and identifiability are different things.

### 1. Hidden by accident, hidden by design (12 min)

- **S1, by accident (captured):** Syft finds `commons-codec` in the shaded JAR, then finds nothing after only its metadata is deleted. Vite's lodash bundle shows "No packages discovered".
- **S2, by design (live):** empty `dependency:tree`, then the plugin realm, then the endpoint. This is the strongest single demo in the workshop.
- **S6, all at once (captured):** `mvn -X | grep lodash-es` is the only place the package is ever named.
- **S3, the good news (one slide):** a standard SBOM of S2 shows zero components and the extended one shows 171.
- **T01, Snyk free tier (one slide):** the cross-scenario matrix. A commercial scanner can't recover identity the build destroyed.
- **Lands:** scanners read paperwork, not code.

### 2. The data doesn't say what you think (12 min)

- **T10, Ghostcat (live):** `jq` over the captured CVE.org and NVD records: severity disagreement, CPEs added 26 months late, KEV two years after exploits, and the EOL Tomcat branch missing from the ranges.
- **T09, three scanners (one slide):** same target, three answers, three different kinds of failure.
- **HeroDevs EOL DS (live CLI, captured fallback):** scan S1 and the Tomcat 8.5 line. Spring Boot 3.5.12 comes back EOL since 30 June 2026 on the maintainers' own statement. Tomcat 8.5.100 comes back EOL for two reasons: no release on the line in a year, and an unpatched CVE that no 8.5 version fixes. Then show the three states most tools collapse into two: vulnerable, not known vulnerable, and unsupported.
- **In-support data as a signal (two slides):** the EOL DS record for Tomcat 8.5.100 lists four CVEs. Three of them score 9.1 to 9.8 and were published in August 2026, more than two years after the line went EOL. That is the abstract's "lurking in the versions your scanners aren't covering" in one record. The cve-propagation cards supply the why: nobody files against a dead branch.
- **OpenSSF Scorecard, OSS Index and Cloudsmith Navigator (live web):** the forward-looking question for `lodash@4.17.21`. Is the project behind it likely to stay healthy? Navigator also scores build-time dependencies, so show what it says about the Maven plugins behind S2 and S6, the tooling no application dependency tree listed.
- **Lands:** a clean scan of an EOL version means nobody looked.

### 3. Someone means you harm (11 min)

- **Getting in (two slides):** dependency confusion, typosquatting, maintainer handover, from Part 5.
- **T08, GuardDog (captured):** a code-reading scanner meets two scenarios and both come back clean.
- **AI-generated malware (new, about 5 min):** a defanged replica of `@kodane/patch-manager`, an npm wallet drainer from July 2025 that Safety attributes to AI on style. Its AI tells (emojis, a log line per step, fluent comments, a polished README) are the opposite of obfuscation: it got by looking legitimate. Show the README, the source, the `postinstall` hook and detached spawn, then what a metadata scanner, GuardDog and a quality score each report. Notes, sources and the fixture plan are in `extra/AIMalware.txt`.
- **Bridge to segment 4 (one slide):** Anthropic's 30 July 2026 disclosure. In an evaluation with accidental internet access, a Claude model found setup instructions naming a PyPI package that didn't exist, registered it with credential-stealing code, and 15 real systems ran it within an hour. One was a malware scanner that installs packages to scan them. Quote the post; don't paraphrase it.
- **Lands:** "no findings" describes the scanner, not the package.

### 4. AI makes all of it faster (9 min)

- **Older trees, not bigger (new):** the research doesn't support "bigger trees". Agents add a new dependency in only 1.3% of real PRs. It does show assistants pinning old versions with CVEs that were public before their training cutoff, naming versions that don't exist, and doing worse than humans on net security. Demo: prompt an assistant for a small Spring Boot service, then show each pinned version beside the latest release, its EOL DS verdict and its CVEs. Notes in `extra/AITreeGrowth.txt`.
- **Hallucinated packages (new, replayed):** a recorded session where an assistant suggests a package that doesn't exist. Then look the name up with `extra/check-names.py`, in the registry and in Navigator: either nothing is there, or something registered recently with no history. Notes in `extra/AISlop.txt`.
- **Slopsquatting (new):** attackers registering those names for real, from published research only: huggingface-cli, react-codeshift, unused-imports, and the names all five 2026 frontier models invent. Cloudsmith's slopsquatting write-up is one source; the checked facts are in `extra/AISlop.txt`.
- **The check inside the assistant (new, replayed):** the same assistant with the HeroDevs EOL MCP server connected. It flags an EOL pick such as Spring Boot 3.5.12 as it adds it, with the reason, the upgrade path and the CVEs. The lifecycle check runs where the dependency decision is made.
- **Lands:** AI adds no new boundary. It sends more traffic across the old ones, faster, so put the checks in the same loop.

### 5. Close: the minimum (3 min)

- One slide of `ship-check.sh`: declared inventory, shipped inventory, the gap, lifecycle.
- QR code to the cheat sheet and the workshop container, for anyone who wants to run the labs after the talk.
- **Lands:** compare two evidence sources every release, not one.

## Reused from the workshop

Fourteen workshop elements carry the first two thirds of the talk. Each already has a lesson, and most have captured evidence or a proof check behind them.

| Element | Where it lives | Segment | Shown as | Captured output ready? |
| --- | --- | --- | --- | --- |
| S2 hidden endpoint | `scenarios/maven-plugin-hidden-content` | 0, 1 | Live, plus captured cold open | Yes, in the lesson |
| S1 shading, strip, bundle | `scenarios/spring-node` | 1 | Captured | Yes, in the lesson |
| S6 `mvn -X` reveal | `scenarios/payara-mvnpm` | 1 | Captured | Yes, in the lesson |
| S3 zero versus 171 | `scenarios/extended-sbom` | 1 | One slide | Yes, `evidence/` |
| T01 Snyk matrix | `investigations/T01-snyk-beyond-sbom` | 1 | One slide | No: `results/` is git-ignored |
| T10 Ghostcat record | `investigations/T10-cve-tomcat-85` | 2 | Live `jq` | Yes, `evidence/` |
| T09 three scanners | `investigations/T09-three-scanners-s01` | 2 | One slide | No: `results/` is git-ignored |
| Scorecard, OSS Index, deps.dev | `workshop/04-project-health-eol.md` | 2 | Live web | Yes, `workshop/evidence/` |
| HeroDevs EOL DS scan | `workshop/04-project-health-eol.md` | 2 | Live CLI | No capture in the repo; the Tomcat and Spring Boot records were checked on 2 October 2026 |
| In-support signal | `workshop/cve-propagation/` cards 02 and 06 | 2 | Two slides | Not needed |
| Attack patterns | `workshop/05-attacks-and-provenance.md` | 3 | Two slides | Not needed |
| T08 GuardDog | `investigations/T08-guarddog` | 3 | Captured | Yes, `evidence/` |
| `ship-check.sh` | `scripts/ship-check.sh` | 5 | One slide | Run once to capture |
| Scenario cheat sheet | paperband cheat-sheet view | Take-home | PDF behind a QR code | Builds today |

**Left out of the talk:** S4 and S5 (npm and Python hooks, which repeat S2's point), S7 provenance (too long to set up), the reference investigations T02 to T07, and the OpenEoX material. All stay available through the QR code.

## To create

The new work falls into four groups. The AI and malware content is the long pole: nothing exists yet, and the malware fixture needs care before anything else depends on it.

Checked research notes for the new material live in `extra/`: `AISlop.txt` (hallucination and slopsquatting), `AIMalware.txt` (AI and malware), `AITreeGrowth.txt` (how assistants pick dependencies), plus `check-names.py`. This outline is mirrored there as `TalkOutline.md`.

### New demos and fixtures

- [ ] **Defanged AI-generated malware replica.** A structural copy of `@kodane/patch-manager`, not the original: same `postinstall` hook, cache-named directory and detached spawn, with the C2 pointed at `.invalid`, no wallet code, and the AI tells kept. Built as case C next to S05's malicious variants so T08's scan script covers it. Packed only, scanned in a no-network container, never published. Plan in `extra/AIMalware.txt` section 6.
- [ ] **Malware dissection walkthrough.** Trigger, evasion, and what metadata scanners, code scanners and quality scores each report. Written as a new card with captured output.
- [ ] **EOL DS captures.** A dated CLI scan of S1 and the Tomcat 8.5.100 record with its four CVEs, as the two in-support-signal slides and the network fallback.
- [ ] **EOL MCP replay.** A recorded assistant session with the HeroDevs EOL MCP server connected, flagging an EOL dependency as it is added.
- [ ] **Cloudsmith Navigator captures.** Dated screenshots of Navigator for `lodash`, for the Maven plugins behind S2 and S6, and for the assistant's picks in segment 4. These are the fallback if the venue network fails.
- [ ] **Version-pick demo** (replaces the tree-growth comparison). Prompt an assistant for a small Spring Boot service in an empty project, three runs, ideally two assistants. Record each pinned version against the latest release, EOL DS and CVEs, then rerun with the EOL MCP server connected for beat 4. Plan in `extra/AITreeGrowth.txt` section 4.
- [ ] **Hallucination replay.** A recorded assistant session that names a non-existent package. The registry checker already exists: `extra/check-names.py`. Fresh names come from the USENIX study's published prompts (`extra/AISlop.txt` section 5).
- [ ] **Slopsquatting slide.** Published research and real registered examples only, with sources.

### Captures the talk needs from existing labs

- [ ] Capture T01 and T09 output into tracked `evidence/` folders. Today it lives only in git-ignored `results/` and inside the container.
- [ ] Capture one HeroDevs EOL scan and one `ship-check.sh` run, dated.
- [ ] Record a short video of each live demo as a fallback for venue network or laptop failure.

### Talk artefacts

- [ ] **Runsheet card** in a new `talk/` folder: segment, minutes, which lesson step to show, and the fallback. It links to lesson steps rather than copying commands.
- [ ] **Slide deck** cut from the segments above. The workshop's old slide outline was built for the seven-part route and is not a starting point.
- [ ] **Speaker notes** carrying the one line each segment lands.
- [ ] **Abstract fixes:** drop the semicolon in "Most have dependencies; it doesn't." and fix the "Using free and free-tier tools..." fragment. The front-matter version of the abstract already reads correctly. Also change "a guided, demo-and-hands-on tour" to "a guided, demo-driven tour", since the audience won't run anything.

### Build changes

- [ ] **Talk edition in the pom:** a paperband execution that builds a short handout from the talk cards plus the five reused lessons.
- [ ] **Talk cheat sheet:** the scenario cheat-sheet view limited to S1, S2, S3 and S6, for the QR code.
- [ ] **Promote the parked AI appendix** into the new talk cards, so the workshop can reuse them later as a Part 7 if wanted.

## Open questions

1. **What gets cut if a demo overruns?** Segment 2 carries five demos in 12 minutes. The T09 three-scanners slide goes first, then the Scorecard and OSS Index beat, keeping the EOL DS story and Navigator. Q&A is the only other buffer, so rehearse to 48 minutes.
2. **Can the AI segment be recorded, or must it be live?** A replay is safer, because assistant output changes between runs.
3. **Does Navigator cover what the talk needs?** Its launch post lists the top 40,000 npm, PyPI, RubyGems and Maven packages. Check that the S2 and S6 plugins and the assistant's picks are among them, and that scores are current.
4. **When is the talk?** The date sets the deadline for the malware fixture, which everything in segment 3 depends on.

**Settled:** the slot is 60 minutes with 10 of Q&A, Dev2Next is the conference, Steve presents alone, and there is no audience participation. Every demo runs on the presenter's machine, so live demos need recorded fallbacks rather than a container for attendees.

## Sources

- [HeroDevs End-of-Life Dataset (EOL DS)](https://www.herodevs.com/eol-dataset). Free; covers 11 million+ package versions using maintainer, release-cadence and patch signals.
- [Getting Started with the EOL Dataset CLI](https://docs.herodevs.com/eol-ds/getting-started), HeroDevs docs.
- HeroDevs EOL MCP server, queried on 2 October 2026 for Spring Boot 3.5.12, Tomcat 8.5.100, lodash 4.17.21, jackson-databind 2.19.4, commons-codec 1.17.1 and commons-lang3 3.18.0. Only Spring Boot and Tomcat came back EOL.
- [Cloudsmith Navigator: The Trusted Guide to OSS Package Quality](https://cloudsmith.com/blog/introducing-cloudsmith-navigator), Cloudsmith, 31 January 2024. Coverage, the three score dimensions, build-time dependency analysis, free to use.
- [Typosquatting and Slopsquatting: Detecting and Defending Against Malicious Packages](https://cloudsmith.com/blog/slopsquatting-and-typosquatting-how-to-detect-ai-hallucinated-malicious-packages), Cloudsmith blog.
- [Cloudsmith Navigator](https://cloudsmith.com/navigator), the tool itself. Not opened while drafting because the site rate-limited the request, so check current coverage there.
