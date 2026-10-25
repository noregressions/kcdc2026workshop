---
id: three-tools
title: "Three tools, one replica"
---

| Tool | Reads | Result |
|---|---|---|
| Metadata scanner | `package.json`, lockfile | Clean: no dependencies, no CVEs |
| GuardDog | The code in the tarball | *to capture* |
| Quality score | Project history | None: two days old, no repository |

## Notes

Fill the GuardDog row from the captured run of the replica; do not predict
rule names. A missing quality score is not a verdict, the same lesson as
"no findings".
