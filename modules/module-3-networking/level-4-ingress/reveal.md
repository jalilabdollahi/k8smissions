## What went wrong

The Ingress rule has `path: /api` with `pathType: Prefix`. This means only requests whose URL path starts with `/api` are routed to the backend. Any request to `/` returns 404 from the Ingress controller, because no rule matches.

## Fix

In manifest.yaml, change the Ingress path:

```yaml
paths:
- path: /
  pathType: Prefix
  backend:
    service:
      name: web-service
      port:
        number: 80
```

## pathType values

- `Prefix` — matches the path and any subpath (e.g. `/api` matches `/api/users`)
- `Exact` — matches only that exact path
- `ImplementationSpecific` — behavior depends on the Ingress controller