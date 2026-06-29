## What went wrong

A NetworkPolicy with `policyTypes: [Ingress, Egress]` and no rules is not a no-op — it is an explicit deny-all. Once it applied to all pods, every packet was dropped: backend could not reach database, and DNS stopped working too.

## Fix

Replace the deny-all with targeted rules:

```yaml
# Allow database to receive from backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-database-ingress
  namespace: k8smissions
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
---
# Allow backend to reach database and resolve DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-egress
  namespace: k8smissions
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: [Egress]
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

## Why this matters

NetworkPolicies are additive and default-deny once any policy selects a pod. Always pair a default-deny with explicit allow rules, and remember that DNS (port 53 UDP to kube-system) must be explicitly allowed in egress rules or service discovery breaks entirely.