## What went wrong

Five independent failures compounded:
1. **Missing Secret** `p0-secret` → `CreateContainerConfigError`
2. **Missing ServiceAccount** `p0-sa` → pod spec unresolvable
3. **Deployment**: `replicas: 0` + `nodeSelector: environment: prod-zone-nonexistent` → no pods scheduled
4. **NetworkPolicy**: egress only allows TCP:80 → DNS (UDP/TCP 53) blocked → all name resolution fails
5. **PVC**: `999Ti` storage → `Pending` forever (no storage class can provision this)

## Fix (in dependency order)

```yaml
# Fix 1: Recreate Secret
apiVersion: v1
kind: Secret
metadata: {name: p0-secret, namespace: k8smissions}
stringData: {password: productionpassword}
---
# Fix 2: Recreate ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata: {name: p0-sa, namespace: k8smissions}
---
# Fix 3: Scale Deployment + remove nodeSelector
spec:
  replicas: 2
  # remove nodeSelector entirely
---
# Fix 4: Allow DNS in NetworkPolicy
egress:
- ports:
  - {port: 53, protocol: UDP}
  - {port: 53, protocol: TCP}
  - {port: 80, protocol: TCP}
  - {port: 443, protocol: TCP}
---
# Fix 5: Realistic PVC size
resources:
  requests:
    storage: 1Gi
```

## Why this matters

Multi-failure incidents require methodical triage. Dependency order matters: fixing the Deployment before creating its Secret and ServiceAccount has no effect — the pods still won't start. A P0 incident checklist:
1. **Identify all failures first** — don't fix sequentially without mapping the blast radius
2. **Fix in dependency order** — infrastructure (Secrets, SAs) before workloads
3. **Verify each fix** — `kubectl get pods -w` after each change
4. **Document the sequence** — post-mortem the fix order for the runbook