## What went wrong

The NetworkPolicy has `podSelector: {app: admin-tool}` in its ingress rule. This allows traffic only from pods labelled `admin-tool`. The frontend pod has `app: frontend` — it does not match. Kubernetes silently drops all packets from frontend to backend.

## Fix

In manifest.yaml, change the NetworkPolicy ingress rule:

```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend
  ports:
  - protocol: TCP
    port: 8080
```

## Why packets are dropped silently

NetworkPolicy drop is not a TCP RST (connection refused) — it is an iptables DROP. The sender sees a timeout, not a refusal. This makes NetworkPolicy misconfigurations harder to spot than port or selector errors.