---
id: one-question
title: "No source file defines it"
---

- `grep -r build-info src/` finds nothing
- `mvn dependency:tree` lists nothing that could add it
- The scanner sees nothing either
- Yet it shipped, and it runs

## Aside

**The one question for the next fifty minutes:**

Is it still identifiable here?

## Notes

Lands: presence and identifiability are different things. Something can be
in the artefact and invisible to every inventory you have.
