## What went wrong

Six independent production readiness gaps combined:
1. `image: nginx:latest` — unpinned tag, non-reproducible
2. `replicas: 1` — no redundancy, single point of failure
3. No resource limits — noisy-neighbor risk
4. No readinessProbe — traffic routed to pods that may not be ready
5. No preStop hook — in-flight requests dropped during rollouts
6. `pdb.minAvailable: 3` with `replicas: 1` — drain and rollout permanently blocked

## Fix

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3
  template:
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: grand-finale-app
        image: nginx:1.27.4
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 500m
            memory: 512Mi
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
---
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 1
```

## Why this matters

Production readiness is a checklist, not a single configuration. Every item on this list represents a real class of incident that happens in production: unpinned tags cause surprise breakages, single replicas cause outages during node maintenance, missing limits cause noisy-neighbor events, missing readiness probes route traffic to broken pods, missing preStop causes dropped connections during deploys, and impossible PDBs permanently block cluster maintenance. This level is the synthesis of module 7 — a working system requires all of these properties simultaneously.