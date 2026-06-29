## What went wrong

Three independent scheduling failures:
1. **Team A**: `nodeSelector: {team: team-a}` — no node has this label, pod can never schedule
2. **Team B**: `required` anti-affinity per hostname with 5 replicas — needs 5 unique nodes but only 2 exist, 3 pods stuck Pending
3. **Team C**: `priorityClassName: non-existent-priority` — PriorityClass doesn't exist, API server rejects the pod before it enters the scheduler queue

## Fix

```yaml
# Team A: remove nodeSelector
spec:
  # nodeSelector removed
  containers: ...
---
# Team B: change to preferred anti-affinity
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: team-b
        topologyKey: kubernetes.io/hostname
---
# Team C: remove priorityClassName
spec:
  # priorityClassName removed
  containers: ...
```

## Why this matters

Real scheduling incidents often involve multiple teams with different failure modes active simultaneously. The diagnosis discipline: check each pod's events independently — `nodeSelector` failures say 'didn't match node selector', anti-affinity failures say 'didn't match pod anti-affinity rules', and PriorityClass failures are caught at admission (the pod may not even appear in `kubectl get pods`). Fixing one doesn't fix another — triage all three before touching the manifest, then apply all fixes at once.