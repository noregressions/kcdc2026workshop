---
id: slopsquatting
title: "Slopsquatting is real"
---

- `huggingface-cli`: registered empty, 15,000+ real downloads in 3 months
- `react-codeshift`: invented in agent skills, spread to 237 repositories
- `unused-imports`: malicious, part of the PhantomRaven campaign

```
$ ./check-names.py react-codeshift dns-sd
react-codeshift  npm:  EXISTS created 2026-01-14, latest 1.0.0,
                       1 versions, 3 dl/wk, repo=none
dns-sd           npm:  absent (404)
```

## Notes

Say honestly: most registered hallucinated names were registered by
researchers or defenders. unused-imports is the clearest malicious case, and
even there the intent is inferred. Rerun check-names.py the day before.
