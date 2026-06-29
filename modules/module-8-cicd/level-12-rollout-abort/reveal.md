## What went wrong

The Rollout pushed `nginx:bad-tag` as the new canary image. The canary pods entered `ErrImagePull`. Argo Rollouts detected that the canary pods were unhealthy, aborted the rollout, and shifted traffic back to the stable revision. The Rollout enters `Degraded` state — it knows something is wrong and stops retrying automatically.

## Fix

```yaml
spec:
  template:
    spec:
      containers:
      - name: web
        image: nginx:1.25
```

After fixing the image, retry the rollout:
```bash
kubectl argo rollouts retry rollout web-rollout -n k8smissions
```

## Why this matters

Argo Rollouts' automatic abort is a safety feature: when a canary fails, traffic is automatically shifted back to the stable version and the Rollout enters `Degraded` to signal that human attention is needed. The `Degraded` state is sticky — it does not auto-recover — so the on-call engineer must diagnose the root cause, fix the manifest, and explicitly retry. This prevents a broken release from being silently retried in a loop.