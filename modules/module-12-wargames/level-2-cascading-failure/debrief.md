# Domino Effect — Cascading Failure

## What Happened
auth-svc was scaled to zero (simulating a misconfigured HPA scale-down or accidental kubectl scale). Because all downstream services depended on it, the entire call chain started failing.

## The Fix
Scale auth-svc back to a working replica count:
```bash
kubectl scale deployment auth-svc --replicas=2 -n k8smissions
```

## Key Lessons
- **Cascading failures are common** — one downstream dependency can take down entire application stacks
- **Dependency maps matter** — knowing which services depend on which is essential for fast triage
- **Circuit breakers** (Istio, Resilience4j) can prevent cascading by returning fast failures instead of timeouts
- **HPA minReplicas** should never be 0 for critical services

## Triage Pattern
```bash
# Check all deployments at once
kubectl get deployments -n k8smissions
# Find which one has 0/0 ready
kubectl describe deployment auth-svc -n k8smissions
```
