## What went wrong

The Service uses the default `sessionAffinity: None`, which load-balances each request independently across all pods. A stateful app that stores sessions in memory requires the same client to always reach the same pod.

## Fix

In manifest.yaml, add to the Service spec:

```yaml
sessionAffinity: ClientIP
sessionAffinityConfig:
  clientIP:
    timeoutSeconds: 10800
```

## The better long-term fix

ClientIP affinity breaks if the client changes IP (mobile networks, proxies). The production solution is to store sessions outside the pods — in Redis or a database. Then any pod can serve any request and statelessness is preserved. This level shows why stateless applications are easier to scale.