# Dev2Next talk deck

One markdown card per 16:9 slide in `content/`, built by paperband into
native PowerPoint (`target/deck.pptx`, speaker notes in the notes pane) and a
PDF (`target/deck.pdf`).

```
mvn -f talk/deck/pom.xml package
```

- Running order and segment timings: `extra/TalkOutline.md`.
- Facts and sources behind the AI and malware slides: `extra/AISlop.txt`,
  `extra/AIMalware.txt`, `extra/AITreeGrowth.txt`.
- `## Notes` in a card becomes the speaker notes; `## Aside` a second column.
- `maxPagesPerCard: 1` fails the build when a slide overflows.
- Slides marked *to capture* wait on demo runs: the GuardDog result for the
  malware replica (35) and the assistant's version picks (43).
- Edit the markdown and rebuild rather than editing the .pptx, which is
  regenerated on every build.
