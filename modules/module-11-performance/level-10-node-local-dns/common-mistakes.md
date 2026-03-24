# Common Mistakes — DNS Latency Spike

## Mistake 1: Increasing kube-dns replicas only

**Wrong approach:** More kube-dns replicas reduces overload but doesn't reduce per-query latency for uncached lookups

**Correct approach:** NodeLocal DNSCache reduces latency by orders of magnitude; combine with kube-dns scaling for throughput
