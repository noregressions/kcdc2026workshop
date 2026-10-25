---
id: s1-shading
title: "By accident: shading and bundling"
---

- Syft finds `commons-codec` inside the shaded JAR
- Delete only its `META-INF` metadata: Syft finds nothing
- The classes are byte-for-byte the same
- Vite bundles lodash into the frontend: "No packages discovered"

## Aside

The code didn't change.

The paperwork did.

## Notes

S1, captured. Nobody did anything malicious: shading and bundling are normal
builds. Identity lived in metadata, and the build is allowed to drop it.
