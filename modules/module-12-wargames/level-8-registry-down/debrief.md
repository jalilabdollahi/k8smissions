# Registry Gone

## What Happened
The internal container registry became unreachable. Because imagePullPolicy was set to Always, Kubernetes tried to pull the image on every pod start — even if the image was cached locally. This caused all new pods to fail.

## The Fix
In production you'd restore the registry. In this scenario, switch to a publicly available image:
```bash
kubectl set image deployment/registry-app registry-app=nginx:1.27.4 -n k8smissions
```

## Key Lessons
- **imagePullPolicy: Always vs IfNotPresent** — Always forces a registry round-trip on every start; IfNotPresent uses cached images when available
- **Registry HA** — run registries with replication across availability zones
- **Image mirroring** — mirror critical images to multiple registries for resilience
- **Existing pods unaffected** — containers already running don't need to pull images; only new/restarted pods do
