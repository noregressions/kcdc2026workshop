---
id: ghostcat
title: "One CVE, read as a record"
---

- CVE-2020-1938, "Ghostcat", Apache Tomcat AJP
- NVD scores: CVSS v2 **7.5**, CVSS v3.1 **9.8 Critical**
- CPE ranges: 7.0.0–7.0.100, 8.5.0–8.5.51, 9.0.0–9.0.31
- 35 of its 38 CPE entries are not `apache:tomcat` at all
- CPEs added 26 months late; KEV listing two years after exploits

## Notes

T10, live jq over the captured CVE.org and NVD records. A CVE is not a fact,
it is a record that changes for years. Scanners match whatever the record
says on the day they run.
