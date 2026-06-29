## What went wrong

Kustomize overlays use patches on top of a shared base. Someone applied the production overlay (`replicas: 10`) to the staging environment instead of the staging overlay (`replicas: 2`). This kind of environment mismatch is a common failure mode when promotion pipelines are manual.

## Fix

```yaml
spec:
  replicas: 2
```

In a Kustomize project, the staging overlay `kustomization.yaml` should have:
```yaml
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kustomize-app
    spec:
      replicas: 2
  target:
    kind: Deployment
    name: kustomize-app
```

## Why this matters

The Kustomize base/overlay pattern is the GitOps solution to environment drift. A base directory contains the shared configuration; each environment (staging, production) has an overlay that patches only what differs. When automated promotion pipelines apply the right overlay per environment from Git, human error in environment selection is eliminated. The risk lives at the pipeline level — the wrong overlay applied by CI is more dangerous than the wrong overlay applied by hand, because CI does it consistently.