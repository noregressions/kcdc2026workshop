---
id: s07-provenance-s01-overview
oneliner: "Start from S01's finished image, fail to trace it home, then record provenance one layer at a time until you can."
track: core
---

# S07 — Reverse Provenance / S01: Overview

> **Workshop track: CORE** — the Part 5 provenance lab. Reuses S01's artefacts,
> so there is no new application to learn.

## The question

Every earlier part asked what is *in* an artefact. This one asks where the
artefact *came from*. Start with S01's finished Docker image and nothing else,
and try to answer:

```text
Which commit produced this?
Which repository?
What is inside it?
Can you prove the bytes are the ones you think?
```

## What you need

S01 already builds a Spring Boot service JAR and a Docker image, so the lab
reuses them. Beyond S01's own toolchain (Maven, JDK 21, Node, Docker) the
provenance layers add `syft` (SBOM) and `cosign` (signing/attestation), plus a
throwaway local registry so the image has a real content digest to key
everything on. Observed versions are in `evidence/tooling.txt`.

## Core result

**The baseline artefact answers none of those questions.** S01's Dockerfile
copies the JAR in and stops. A reverse audit of the image recovers only the
label the base image happened to carry:

```text
Config.Labels: {"org.opencontainers.image.version":"22.04"}
```

No commit in the JAR, no source repository, no inventory, no signature. From
the image alone you cannot get home.

**Four layers close the gap, each recording one missing thing:**

```text
1. git commit    git-commit-id plugin writes git.properties INTO the JAR
2. OCI labels    org.opencontainers.image.revision / .source on the image
3. SBOM          syft builds a CycloneDX inventory, keyed to the image digest
4. attestation   cosign signs the digest and attests the SBOM to it
```

After the four layers, the same reverse audit succeeds, and the final step is
the important one: with the **public key alone** you can verify the image is
what was signed and pull back the SBOM that was attested to its digest.

```text
signature:   VERIFIED
attestation: VERIFIED (the SBOM travels bound to the digest)
```

Mind what kind of evidence each layer is. The embedded commit id and the OCI
label are the same trust tier: both are *claims* anyone could fake, differing
only in how easily a tool finds them. The SBOM is a claim about contents. The
signed attestation is the first item on the list an outsider can actually
*verify* against a key rather than take on trust. Provenance is a ladder, and
in practice a lot of pipelines never climb past the unsigned rungs.

## Run

```bash
./scripts/build-baseline.sh    # build S01, then fail to trace it
./scripts/add-provenance.sh    # add the four layers, re-audit after each
./scripts/proof-check.sh
```

The scripts build a throwaway copy of S01 under `work/`; S01 itself is left
untouched. Commit ids and digests differ on every run, so the values in
`TRACE.md` and `evidence/` are illustrative, not fixed.

See `TRACE.md` for the annotated walkthrough.
