# Control Plane Flood

## What Happened
A deployment was accidentally scaled to 50 replicas. Each pod opened a persistent watch connection to the API server. 50 concurrent watchers overwhelmed the API server, causing slow responses across the entire cluster.

## The Fix
```bash
kubectl scale deployment api-watcher --replicas=2 -n k8smissions
```

## Key Lessons
- **API server has connection limits** — too many concurrent watches causes latency for all operations
- **Audit logs help triage** — `kubectl logs -n kube-system kube-apiserver-*` shows request rates
- **Resource quotas prevent runaway scaling** — set maxReplicas limits with LimitRange or OPA policies
- **HPA maxReplicas** — always set a sane upper bound on autoscalers

## Identifying the Culprit
```bash
kubectl get deployments -A --sort-by='.spec.replicas'
```
