1. `kubectl -n k8smissions logs <pod> --previous` shows the app was still "loading catalogue" when it was killed; `describe pod` shows `Liveness probe failed: connection refused` and `Container app failed liveness probe, will be restarted`.
2. The probe starts after 3 seconds and tolerates one failure, so the container is killed after about 6 seconds, long before the app opens its port at 15 seconds.
3. Patch the probe so its first failure can only happen after startup: `initialDelaySeconds: 30` (and `failureThreshold: 3` for some tolerance), then wait for the rollout.
