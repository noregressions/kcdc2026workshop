---
id: s6-all-at-once
title: "All at once"
---

```
$ mvn -X package | grep lodash-es
```

- The only place `lodash-es` is ever named
- Not in the POM, not in `dependency:tree`, not in the SBOM

## Notes

S6, captured. Payara plus mvnpm: an npm package resolved through Maven at
build time. Debug logging is the only evidence it was ever fetched.
