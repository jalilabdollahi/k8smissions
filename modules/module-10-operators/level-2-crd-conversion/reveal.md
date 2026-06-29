## What went wrong

`conversion.strategy: None` tells Kubernetes: 'never convert between versions'. With two served versions, the API server needs to convert stored v1alpha1 objects when someone requests them as v1beta1. Without a conversion webhook, the conversion fails and objects are invisible.

## Fix

```yaml
versions:
- name: v1alpha1
  served: true
  storage: false
- name: v1beta1
  served: true
  storage: true
conversion:
  strategy: Webhook
  webhook:
    conversionReviewVersions: [v1]
    clientConfig:
      service:
        name: db-operator-webhook
        namespace: operators
        port: 443
```

## Why this matters

CRD multi-versioning requires a conversion webhook to translate between schema versions. The 'hub' pattern: pick one version as the internal hub (usually the latest stable), convert all others to/from it. Only one version can be `storage: true` — all objects are stored in this version. Objects stored in old versions are served via on-the-fly conversion. Never remove a version from the CRD until all stored objects have been migrated to the new storage version.