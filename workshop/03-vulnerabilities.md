---
id: workshop-03-vulnerabilities
oneliner: "Vulnerability publication pipeline, CPE configuration matching mechanics, and empirical analysis of CVE lifecycle evolution."
track: core
status: planned
---

# Part 3: Vulnerability Ingestion and Matching Mechanics

**Target duration:** 35 minutes (presentation and guided API investigation)

## Technical Architecture

The vulnerability finding pipeline consists of distinct translation steps where matching failures can occur:

```text
software -> identity -> package/product mapping -> CVE record -> affected versions -> scanner matching -> finding
```

## Investigation Focus: Apache Tomcat 8.5 (Ghostcat / CVE-2020-1938)

Hands-on investigation against live and captured JSON payloads in `investigations/CVE-tomcat-85`:

1. **CNA vs NVD Severity Models:**
   - Vendor advisory classification (Apache: "Important") compared against CVSS v2 (7.5) and CVSS v3.1 (9.8 CRITICAL).
2. **CPE Matching Criteria:**
   - Syntax: `cpe:2.3:a:apache:tomcat:*:*:*:*:*:*:*:*`
   - Evaluation of exact version matching conditions: vendor, product, version format, and range bounds (`8.5.0` to `< 8.5.51`).
3. **Embedded Dependencies and Vendor CPEs:**
   - Analysis of 38 CPE entries in NVD for CVE-2020-1938, where 20 represent embedded Oracle product distributions.
   - Timing analysis: Oracle CPE configurations were added 26 months post-initial CVE publication.
4. **CISA KEV Integration Latency:**
   - Addition to KEV catalogue (March 2022) vs public exploit availability (February 2020).
5. **End-of-Life (EOL) Version Exclusions:**
   - Exclusion of EOL Tomcat 6.x from CVE-2020-1938 structured ranges despite vulnerability in underlying code.
   - Contrast with CVE-2025-24813: prose documentation of EOL 8.5 paired with unbounded CPE ranges (`* < 9.0.99`).

## Technical Conclusions

- A CVE entry is a versioned, mutable record updated over multiple years.
- Scanner findings represent a point-in-time join between extracted artifact identifiers and upstream CPE ranges.
- Downstream backports and custom builds can produce false positives against static CPE version ranges, while forks and renamed packages produce false negatives.
