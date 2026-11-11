**What was broken.** Two independent faults hid behind a healthy-looking DaemonSet. The `session-gw` pods were configured (`dnsPolicy: None`) with the ClusterIP of `dns-upstream`, so the node-local cache was never asked. And the cache's own Corefile capped every cached answer at one second (`success 9984 1`), so even the traffic that did reach it was mostly misses.

**The evidence.** Three logs tell the story. The gateway's own log shows about 85ms per lookup. The `dns-cache` pods' query logs were empty, which proves nobody was using them. The upstream log had one line per lookup. After pointing the gateways at the cache, the cache log fills up but the upstream log is still busy, about one query in three: that is the TTL cap.

**Why Kubernetes behaved this way.** Ready only means the process answers `/ready`. Nothing in Kubernetes knows who should be talking to a DNS cache: a client resolves through whatever `resolv.conf` it was given, and with `dnsPolicy: None` that is exactly the `dnsConfig` you wrote. A `Service` with `internalTrafficPolicy: Local` keeps each client on the cache of its own node, but only for clients that use it. CoreDNS reads its Corefile once, so editing the ConfigMap needs a restart of the pods.

**The fix.** Point `dnsConfig.nameservers` at the `dns-cache` Service, raise the cache TTL cap, restart the DaemonSet.

**In production.** Real NodeLocal DNSCache listens on a link-local address on every node and is wired in by kubelet (`clusterDNS`), so pods use it without any per-workload `dnsConfig`. Watch `coredns_cache_hits_total` against `coredns_cache_misses_total`, and the ratio of cache to upstream query rates, rather than only pod status.

**Worth remembering.**
- `kubectl exec <pod> -- cat /etc/resolv.conf`
- `kubectl logs -l app=dns-cache --tail=20`
- `kubectl rollout restart daemonset/<name>`
