**What was broken.** A page took two seconds because of three faults at three layers, none of which was visible in pod status: each page view made 4 DNS queries instead of 1; `pricing` ran under a 100m CPU limit that throttled it; and `sessionAffinity: ClientIP` on the pricing Service pinned the only client (the one storefront pod) to a single pricing pod, so two of the three replicas did nothing.

**The evidence.** The resolver log showed four lines per lookup (three NXDOMAIN from search domains). `cpu.stat` in the busy pricing pod showed `nr_throttled` close to `nr_periods`. The per-pod `/stats` counters showed one pod serving everything. Every one of these was one command away, and every one had to be fixed: after any single fix the page was still over 300ms, which is why the work is measuring, changing one thing, measuring again.

**Why Kubernetes behaved this way.** The resolver follows `ndots` and the search list, so short and 2-dot names are tried against each search domain first. CPU limits are enforced as quota per 100ms period regardless of idle nodes. kube-proxy's ClientIP affinity keys on the source address, and from the Service's point of view every request from one pod is the same client.

**The fix.** A fully qualified name (or a lower `ndots`), a CPU limit that fits the burst (or none, with a request kept), and `sessionAffinity: None` unless the application truly needs stickiness and has enough distinct clients.

**In production.** Use traces and per-hop metrics (`container_cpu_cfs_throttled_periods_total`, resolver metrics, per-endpoint request rates) to find the slow layer, then verify each fix with the same measurement before moving on. Affinity belongs behind an ingress that sees many client IPs.

**Worth remembering.**
- `kubectl exec <pod> -- cat /etc/resolv.conf /sys/fs/cgroup/cpu.stat`
- `kubectl get svc <name> -o yaml | grep -A2 sessionAffinity`
- `kubectl logs deploy/<dns-copy> --since=30s | wc -l`
