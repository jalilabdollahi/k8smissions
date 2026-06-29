## What went wrong

The dev environment config was promoted to production without being replaced by the production overlay. Three production requirements are missing:
1. Log level at `info` (not `debug`)
2. Three replicas for redundancy
3. Resource limits to protect other workloads

## Fix

```yaml
# ConfigMap
data:
  LOG_LEVEL: info
---
# Deployment
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: multi-env-app
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

## Why this matters

Config drift — where production ends up running different settings than intended — is one of the most common causes of production incidents. GitOps solves this by making Git the single source of truth: the production overlay in the repository defines exactly what production should look like, and the CD pipeline enforces it. The pattern works only when promotion means applying the correct environment-specific overlay, not manually editing live cluster state.