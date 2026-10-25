---
id: s2-design
title: "By design: the build plugin"
---

- `mvn dependency:tree`: no trace of the endpoint
- The code arrives in the **plugin** class realm, not the app's
- A transitive dependency of a build plugin writes it into the JAR
- The app's dependency graph never sees it

## Aside

The strongest single demo in the workshop.

## Notes

S2, live. Empty dependency tree, then show the plugin realm, then hit the
endpoint again. Build tooling is part of what you ship, and no application
inventory lists it.
