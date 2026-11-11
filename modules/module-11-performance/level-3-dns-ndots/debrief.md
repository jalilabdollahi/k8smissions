**What was broken.** rate-limiter resolves `quotas.payments.internal` about 25 times a second. Each lookup cost four DNS queries instead of one, so the resolver (and the zone behind it) handled four times the load it needed to, and every lookup waited for three NXDOMAIN answers first.

**The evidence.** The dns-lab log showed, for every lookup, the same name with three suffixes (`.k8smissions.svc.cluster.local`, `.svc.cluster.local`, `.cluster.local`) answered NXDOMAIN, then the plain name answered NOERROR. The pod's `/etc/resolv.conf` explained why: `options ndots:5` and a `search` list of three domains.

**Why Kubernetes behaved this way.** Kubernetes defaults pods to `ndots:5` so that short Service names like `session-cache` or `db.prod` resolve through the search list. The price is that any name with fewer than five dots is treated as relative and expanded with every search domain before it is tried as written. `quotas.payments.internal` has only two dots, so it pays that price on every call, for an answer that was never in the cluster domain.

**The fix.** Either lower `ndots` for this pod (2 is enough, since the name has two dots), or write the name as an absolute name with a trailing dot, which skips the search list entirely. Emptying the search list also reduces queries but would break `session-cache`, which the same app resolves by its short name.

**In production.** External names (APIs, databases outside the cluster) are the usual victims. Use FQDNs with a trailing dot in configuration where you can, set `ndots:2` for pods that mostly talk outside the cluster, and put a caching resolver such as NodeLocal DNSCache in front of CoreDNS. Count queries in the log instead of guessing.

**Worth remembering.**
- `kubectl exec <pod> -- cat /etc/resolv.conf`
- `kubectl logs deploy/<dns> --since=20s | grep -c <name>`
- `kubectl explain pod.spec.dnsConfig.options`
