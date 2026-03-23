# Memory Wave

## What Happened
Three services had memory limits set to 32Mi — the same as their requests (Guaranteed QoS). When a memory spike occurred (even briefly), all three were OOMKilled simultaneously, triggering a wave of restarts.

## The Fix
```bash
for SVC in svc-alpha svc-beta svc-gamma; do
  kubectl set resources deployment $SVC \
    --requests=memory=64Mi --limits=memory=256Mi \
    -n k8smissions
done
```

## Key Lessons
- **Limits = requests = Guaranteed QoS** — safest for latency, but any spike gets OOM-killed
- **Burst headroom** — limits should be 2-4x requests for memory to allow temporary spikes
- **VPA (Vertical Pod Autoscaler)** — can automatically right-size memory requests and limits
- **OOM kill order** — when a node runs low on memory, Kubernetes evicts BestEffort → Burstable → Guaranteed
