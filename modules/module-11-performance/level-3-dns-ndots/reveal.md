## What went wrong

`ndots: 5` means: if the hostname has fewer than 5 dots, try each search domain before attempting the name as-is. A lookup for `db` has 0 dots — so Kubernetes tries `db.k8smissions.svc.cluster.local`, `db.svc.cluster.local`, `db.cluster.local`, `db.default.svc.cluster.local` (etc.) before resolving. 100 lookups/second becomes 500+ DNS queries/second, overwhelming kube-dns.

## Fix

```yaml
spec:
  dnsConfig:
    options:
    - name: ndots
      value: '2'
  containers:
  - name: app
    command:
    - /bin/sh
    - -c
    - while true; do nslookup db.k8smissions.svc.cluster.local; sleep 0.1; done
```

## Why this matters

Two strategies reduce DNS overhead:
1. **Lower ndots**: `ndots: 2` means names with 2+ dots are treated as FQDNs and bypass the search list entirely. `db.k8smissions` has 1 dot — still searches. `db.k8smissions.svc` has 2 dots — tries as-is first.
2. **Use FQDNs**: always append `.svc.cluster.local` in service URLs to bypass all search path lookups.

For extreme DNS traffic, enable NodeLocal DNSCache (level 10) which caches responses at the node level, eliminating round-trips to kube-dns for repeated lookups.