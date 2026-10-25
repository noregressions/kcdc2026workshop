---
id: kodane
title: "AI-written malware: @kodane/patch-manager"
---

- npm, July 2025. Claimed to be an "NPM Registry Cache Manager"
- Its own source called it "ENHANCED STEALTH WALLET DRAINER"
- `postinstall` hides files in a directory named like an npm cache
- Spawns a detached process that reports to a C2 server
- 19 versions in two days, 1,500+ downloads, caught by Safety

## Notes

Source: Paul McCarty, Safety, archived post (extra/AIMalware.txt [1]). We
show a defanged replica built in the repo, not the original. Same structure,
the C2 points at .invalid, and there is no wallet code.
