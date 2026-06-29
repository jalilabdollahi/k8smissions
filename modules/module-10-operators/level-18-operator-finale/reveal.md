## What went wrong

Three independent operator configuration failures combined:
1. **Webhook**: no `namespaceSelector` + `failurePolicy: Fail` → kube-system pods blocked → DNS breakage
2. **CRD**: v1 removed before v1-stored objects were migrated → `kubectl get` returns errors for existing resources
3. **Operator**: `--leader-elect=false` with 2 replicas → both replicas actively reconciling → resource flapping

## Fix

```yaml
# Fix 1: Webhook — safe failure policy + system namespace exclusion
webhooks:
- name: validate.example.com
  namespaceSelector:
    matchExpressions:
    - key: kubernetes.io/metadata.name
      operator: NotIn
      values: [kube-system]
  failurePolicy: Ignore
---
# Fix 2: CRD — restore v1 as served-but-not-stored
versions:
- name: v1
  served: true
  storage: false
- name: v2
  served: true
  storage: true
---
# Fix 3: Operator — enable leader election
args:
- --leader-elect=true
```

## Why this matters

Operator infrastructure failures compound: a broken webhook can break DNS, which breaks the webhook's own service discovery, which escalates to a full cluster communication failure. Triage order matters: fix the webhook first (it may be blocking your ability to apply fixes), then the CRD (restores visibility into cluster state), then the operator (stops resource flapping). Keep these three operator safety rules: always scope webhooks with namespaceSelector, always maintain old CRD versions until migration is complete, and always enable leader election with more than one replica.