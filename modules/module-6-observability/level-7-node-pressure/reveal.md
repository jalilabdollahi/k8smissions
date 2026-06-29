## What went wrong

The Deployment runs 4 pods, each executing `dd if=/dev/zero` — a command that continuously writes null bytes and consumes memory. With no `limits.memory`, the combined usage pushes the node into MemoryPressure. When the kubelet detects this condition, it starts evicting pods in QoS order (BestEffort first, then Burstable, then Guaranteed) until pressure is relieved.

## Fix

Reduce replicas and add memory limits:

```yaml
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: memory-hog
        command:
        - /bin/sh
        - -c
        - sleep 3600
        resources:
          requests:
            memory: 64Mi
          limits:
            memory: 128Mi
```

## Why this matters

Node conditions — `MemoryPressure`, `DiskPressure`, `PIDPressure` — trigger the kubelet's eviction manager. Pods without limits have `BestEffort` QoS and are evicted first. You can prevent this by always setting both requests and limits. If a node is under sustained pressure, consider cordoning it (`kubectl cordon`) to stop new scheduling while you diagnose.