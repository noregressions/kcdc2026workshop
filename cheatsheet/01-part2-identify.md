---
id: cheatsheet-part2
oneliner: "Part 2 in run order: S1, S2, S3, S4, S5, S6, T01 — every command and the output it should produce."
track: reference
---

# Part 2 — Can We Identify What We Ship?

Seven stops, in route order. Ports: S01 8080 (`java -jar`), S02 8080
(Payara container), S03 8081, S04 8082, S05 8083. Every `run.sh` has a
matching `stop.sh`, and `run.sh` refuses to start if the port is busy.

The six scenario sheets follow, generated from their lessons, then T01.
