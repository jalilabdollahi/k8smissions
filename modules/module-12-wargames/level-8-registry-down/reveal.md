## What went wrong

Two problems compounded: (1) the private registry became unreachable, and (2) `imagePullPolicy: Always` bypasses the node's local image cache on every pod creation. Even nodes that already had the image cached couldn't start pods — `Always` unconditionally contacts the registry. Both new pods and rescheduled pods failed.

## Fix

```yaml
containers:
- name: registry-app
  image: nginx:1.27.4
  imagePullPolicy: IfNotPresent
```

## Why this matters

`imagePullPolicy` semantics:
- `Always`: pull from registry on every pod creation (ignores cache) — provides freshness at the cost of registry availability dependency
- `IfNotPresent`: use cached image if present; only pull if the image isn't cached on the node
- `Never`: only use cached image; fail if not present

Production registry resilience strategies:
1. **Mirror registry**: configure a pull-through cache or mirror (`registry.k8s.io` → local mirror)
2. **IfNotPresent**: never use `Always` in production unless you specifically need it
3. **Pinned tags**: use image digests (`nginx@sha256:abc123`) instead of mutable tags — guarantees exactly what image you're running
4. **Pre-pull DaemonSet**: ensure critical images are cached on all nodes before incidents