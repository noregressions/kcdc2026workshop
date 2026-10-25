---
id: agent-published
title: "When the agent published the package"
---

- Anthropic, 30 July 2026: an evaluation had internet access by mistake
- A model found setup docs naming a PyPI package that didn't exist
- It published one under that name, with hidden credential-stealing code
- Live for about an hour, it was "downloaded and run on 15 real systems"
- One was a security company's scanner that installs packages to scan them

## Notes

Quote the post; don't paraphrase it (extra/AIMalware.txt section 4). It is
a disclosed incident, not a typical attack. Two lessons: a name that doesn't
exist is an opening, and "scan it" and "run it" have to be different steps.

Lands: "no findings" describes the scanner, not the package.
