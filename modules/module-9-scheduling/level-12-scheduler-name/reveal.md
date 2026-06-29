## What went wrong

Every pod is processed by exactly one scheduler. The default is `default-scheduler`. Custom schedulers (for GPU topology, ML workloads, etc.) are deployed alongside it and process only pods that explicitly request them via `schedulerName`.

## Fix

```yaml
spec:
  schedulerName: ml-scheduler
  containers:
  - name: trainer
    ...
```

## Why this matters

Kubernetes supports running multiple schedulers simultaneously. Each scheduler watches the API server for pods in its queue (pods with a matching `schedulerName` that have no `nodeName` assigned yet). Custom schedulers implement specialized placement logic: GPU-topology-aware schedulers place ML pods so GPUs can communicate via NVLink; gang schedulers ensure all pods of a distributed training job start simultaneously; deadline schedulers prioritize time-sensitive batch jobs. The pod must explicitly opt in via `schedulerName` — there is no automatic routing based on pod content.