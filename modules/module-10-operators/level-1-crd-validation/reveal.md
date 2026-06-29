## What went wrong

The CRD's `openAPIV3Schema` sets `minimum: 5` on `spec.replicas`. Every custom resource that sets fewer than 5 replicas is rejected at admission. This is enforced server-side by the API server, which validates all CR writes against the CRD schema.

## Fix

```yaml
properties:
  replicas:
    type: integer
    minimum: 1
```

## Why this matters

CRD OpenAPI validation is the Kubernetes-native way to enforce CR contracts at the API layer — before the operator even sees the object. Common constraints: `minimum`/`maximum` for numbers, `minLength`/`maxLength` for strings, `enum` for allowed values, `pattern` for regex, and `required` for mandatory fields. Bad constraints (like `minimum: 5` when you want to support single replicas) make CRs impossible to use correctly. Always test your schema with `kubectl apply --dry-run=server` before shipping.