## What went wrong

Kustomize patches use a target selector to find which resource to modify. When the `target.name` doesn't match any resource in the build, Kustomize silently skips the patch — this is a design choice to allow partial overlays, but it creates a hard-to-spot failure mode where patches appear to succeed but have no effect.

## Fix

Change the patch target name to match the actual Deployment:

```yaml
patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: api-server
      spec:
        replicas: 5
    target:
      kind: Deployment
      name: api-server
```

## Why this matters

Kustomize patch targets match by `kind`, `name`, `namespace`, `labelSelector`, and `annotationSelector`. If any selector field doesn't match, the patch is skipped without error. This silent-skip behavior can cause hours of debugging when a configuration change appears to be applied but has no effect. Always verify with `kubectl kustomize .` (dry-run rendering) before applying, and check the rendered output against your expectation rather than assuming the patch ran.