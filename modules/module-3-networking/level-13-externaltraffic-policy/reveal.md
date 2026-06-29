## What went wrong

`externalTrafficPolicy: Local` tells kube-proxy: only forward traffic if a matching pod is running on this node. If no pod is here, drop the packet. This is by design — it preserves the original client IP and avoids an extra network hop.

But in this cluster, pods are not on every node, so some nodes silently drop all NodePort traffic.

## Fix

In manifest.yaml:

```yaml
externalTrafficPolicy: Cluster
```

With `Cluster`, any node receiving the traffic will forward it to a backend pod on another node if needed — no silent drops.

## Local vs Cluster trade-off

- `Cluster` — works everywhere, but loses original client IP and adds a network hop
- `Local` — preserves client IP, no extra hop, but requires pods on every node that might receive traffic (common with DaemonSets)