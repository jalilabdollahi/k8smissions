## What went wrong

`x-kubernetes-preserve-unknown-fields: true` is an escape hatch that tells the API server to accept any field without validation. While useful during early development, shipping a CRD with this setting means any garbage — negative replica counts, wrong types, missing required fields — is silently accepted.

## Fix

```yaml
schema:
  openAPIV3Schema:
    type: object
    properties:
      spec:
        type: object
        required: [replicas, image]
        properties:
          replicas:
            type: integer
            minimum: 1
            maximum: 100
          image:
            type: string
          env:
            type: array
            items:
              type: object
              required: [name, value]
              properties:
                name:
                  type: string
                value:
                  type: string
```

## Why this matters

CRD OpenAPI validation is your operator's first line of defense. Without it, your operator must defensively validate every field in the reconciliation loop or risk crashing on nil dereferences and type assertion panics. A proper schema: documents the API for users (shown by `kubectl explain`), rejects invalid objects before they reach the operator, and provides IDE/linter support. The `required` keyword makes fields mandatory at creation time, preventing silent failures from missing config.