---
id: setup-tools
oneliner: "The tools and minimum versions the workshop needs, how to check them in one command, and what Podman can and cannot substitute for."
track: core
---

# Install Before the Workshop

Install the tooling below before attending the workshop. One command tells
you where you stand:

```bash
./scripts/tools-check.sh
```

It reports every tool it finds against the workshop minimum and prints
install instructions for anything missing; it installs nothing and changes
nothing. Exit status is non-zero if a required tool is missing or too old.

To see the install instructions for every tool (useful when preparing a
machine you do not have in front of you):

```bash
./scripts/tools-check.sh --urls
```

## Minimum environment

| Tool | Requirement |
|---|---|
| Bash | System Bash is sufficient |
| Git | Current |
| JDK | 21+ |
| Maven | 3.9+ |
| Node.js | 20+ |
| npm | Bundled with Node.js |
| Python | 3.11+ |
| pip / venv | Bundled or installed with Python |
| Docker | Current Docker Desktop or Docker Engine |
| jq | Current |
| Syft | Current |
| Snyk CLI | Current and authenticated |
| Trivy | Current |
| Grype | Current |
| pip-audit | Current |
| Docker Scout | Current |
| curl | Current/system |
| zip / unzip / tar | Current/system |
| grep / find / sort / diff / tee | System versions |

You do not need to install `npm audit` (supplied by npm), `jar`/`javap`
(supplied by the JDK), or `pip` (supplied by Python). The Maven-side tooling
— the CycloneDX, Shade, Spring Boot, esbuild and OWASP Dependency-Check
plugins, and the mvnpm artefacts — is resolved by Maven during the builds.

## Installing what's missing

On macOS with Homebrew, most of the list is one command:

```bash
brew install openjdk@21 maven node python jq syft grype trivy pipx
pipx install pip-audit
npm install -g snyk
```

plus Docker Desktop (which includes Docker Scout).

The full copy-paste transcripts — including the Debian/Ubuntu equivalents,
per-tool verification, and Podman setup — are in
[`setup/INSTALL.md`](./INSTALL.md) in the repository. Follow the links
`tools-check.sh` prints, or work through that file, then re-run the check.

The versions the walkthroughs were recorded against (and which versions the
repository pins itself) are in [`setup/VERSIONS.md`](./VERSIONS.md): if your
output differs from what a walkthrough records, compare there first.

## A note on Podman

Docker is the workshop's canonical container engine; the scripts invoke
`docker` directly. Podman works for
the basic S01 and S02 container build/run stages if you run the equivalent
`podman` commands manually or use a Docker-compatible shim, but it is not a
transparent replacement:

- T02 uses **Docker Scout**, which Podman does not provide.
- T03 tells Trivy to use Docker as the image source.
- T04 feeds Grype a Docker image source.

Install commands for Podman are in [`setup/INSTALL.md`](./INSTALL.md).
