# Common Mistakes — DNS Flood

## Mistake 1: Increasing kube-dns replicas

**Wrong approach:** More DNS replicas help with overload but don't fix the root cause — the app will keep flooding DNS

**Correct approach:** Fix the source: ndots or FQDNs; horizontal scaling is a band-aid
