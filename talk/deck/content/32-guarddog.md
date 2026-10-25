---
id: guarddog
title: "A scanner that reads the code"
---

| GuardDog 3.2.0 on | Score |
|---|---|
| Positive control (download-and-execute) | 8.2 / 10 |
| S05 npm tarball | 0.0 |
| S03 Python sdist | 0.0 |

## Aside

S05: the generator never shipped, so there was nothing to read.

S03: the build backend shipped, and it was benign.

## Notes

T08, captured. Calibrate first: the control proves the scanner fires. Then
two clean results for opposite reasons. Clean means nothing matched in the
bytes it was handed.
