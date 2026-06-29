## What went wrong

A `deny-all` NetworkPolicy with `podSelector: {}` and `policyTypes: [Ingress, Egress]` but no `ingress` or `egress` rules blocks all traffic for all pods in the namespace. This includes DNS queries (UDP port 53) — without DNS, even internal service names can't resolve. The namespace is completely isolated.

## Fix

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

Note: you may also need to add an egress allow rule for DNS (port 53 UDP/TCP) to the deny-all or a separate policy.

## Why this matters

NetworkPolicy rules are additive: multiple policies apply with OR logic. The `deny-all` baseline is the right starting point (zero-trust network posture), but it must be followed immediately by targeted allow rules for legitimate traffic. Key patterns:
1. **DNS egress**: always allow egress on UDP/TCP port 53 to kube-dns, or pods can't resolve any names
2. **Namespace-scoped**: NetworkPolicies apply only within their namespace
3. **No 'deny' rules**: NetworkPolicy is whitelist-only — once any policy applies to a pod, all non-matched traffic is denied
4. **Test with netpol-editor or Cilium editor** before applying to production