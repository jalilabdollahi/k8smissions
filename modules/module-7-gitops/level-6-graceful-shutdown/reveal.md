## What went wrong

Kubernetes sends SIGTERM and removes the pod from endpoints at the same time. But kube-proxy (or the CNI) takes a few seconds to propagate the endpoint removal to all nodes. During that window, requests still arrive at a pod that has already received SIGTERM and may be shutting down — causing connection resets.

## Fix

```yaml
spec:
  terminationGracePeriodSeconds: 60
  containers:
  - name: graceful-app
    image: nginx:1.27.4
    lifecycle:
      preStop:
        exec:
          command:
          - /bin/sh
          - -c
          - sleep 15
```

The `preStop` hook runs before SIGTERM is sent. The 15-second sleep gives kube-proxy time to propagate the endpoint removal before the application starts shutting down.

## Why this matters

The full pod termination sequence:
1. Pod added to `Terminating` state
2. `preStop` hook executes
3. SIGTERM sent to container
4. Container has `terminationGracePeriodSeconds` total (including preStop time) to exit cleanly
5. After grace period, SIGKILL is sent

For zero-downtime deployments: preStop sleep ≥ time for kube-proxy propagation (typically 5–15s). This pattern is essential for any production web service.