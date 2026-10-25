---
id: it-answered
title: "It answered"
---

```
$ curl -sS http://localhost:8082/hidden/build-info | jq
{
  "message": "This runtime endpoint came from a transitive Maven plugin dependency.",
  "origin": "trace-route-payload",
  "introducedBy": "trace-injector-maven-plugin",
  "route": "/hidden/build-info"
}
```

## Notes

Cold open, captured so it cannot fail. A running Spring app, an endpoint,
JSON back. Don't explain yet. Ask the room what defines this endpoint.
