## What went wrong

The pod's command `dd if=/dev/zero bs=1M count=1000 | cat > /tmp/data` allocates approximately 1GB of memory. The declared `requests.memory: 50Mi` is far lower than actual usage — the pod was scheduled based on a 50Mi reservation but consumes 1GB. This pushes the node into `MemoryPressure` and the kubelet begins evicting other pods.

## Fix

```yaml
spec:
  containers:
  - name: app
    command:
    - /bin/sh
    - -c
    - sleep 3600
    resources:
      requests:
        cpu: 10m
        memory: 50Mi
      limits:
        cpu: 100m
        memory: 128Mi
```

## Why this matters

Understating resource requests is a common cause of node pressure. The scheduler trusts the declared request for placement — but actual runtime usage can far exceed it. When real usage exceeds the node's available memory, the kubelet evicts pods in order of QoS: BestEffort first, then Burstable (pods where requests < limits), then Guaranteed. Set requests to reflect realistic steady-state usage, and set limits conservatively above that — the gap is your burst headroom.