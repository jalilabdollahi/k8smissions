## What went wrong

NodeLocal DNSCache is installed (the DaemonSet and ConfigMap exist) but the `enabled: 'false'` flag keeps it inactive. Without it, every DNS query travels over the pod network to a kube-dns pod — adding a network round-trip and making DNS a shared bottleneck across all pods.

## Fix

```yaml
data:
  enabled: 'true'
```

## Why this matters

NodeLocal DNSCache (node-local-dns) runs CoreDNS as a DaemonSet on every node, listening on a link-local IP (169.254.20.10). Pods that use this IP for DNS bypass the pod network entirely — responses come from a local process on the same node. Benefits:
1. **Latency**: sub-millisecond for cached responses vs. 1–10ms for network round-trips
2. **Scale**: eliminates kube-dns as a centralized bottleneck; each node serves its own pods
3. **Reliability**: DNS continues working if kube-dns pods are briefly unavailable (cache serves stale responses)
4. **Connection tracking**: avoids conntrack race conditions that cause DNS packet drops under high query rates

Node-local DNS caches become especially critical when combined with low ndots values (level 3).