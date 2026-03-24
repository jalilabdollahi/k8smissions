# Split Cluster

## What Happened
A default-deny NetworkPolicy was applied to the entire namespace. This is good security practice, but without corresponding allow rules, it blocked all traffic including required service-to-service communication.

## The Fix
Add a targeted allow rule:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: k8smissions
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

## Key Lessons
- **Default-deny is best practice** — but you must add allow rules for all required traffic
- **NetworkPolicy is additive** — multiple policies combine with OR logic for allow rules
- **Test before applying** — use tools like Cilium's policy editor or network policy validator
- **Egress also matters** — deny-all blocks outgoing DNS too; add egress rules for DNS (port 53)
