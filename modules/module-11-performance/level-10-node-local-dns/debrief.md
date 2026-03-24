# DNS Latency Spike

## What Was Broken
NodeLocal DNSCache was disabled. Every DNS query traversed the node's network to reach the central kube-dns Service. Under load, this added 5-30ms RTT per DNS query, which impacts any short connection (microservices, external calls).

## The Fix
Enable NodeLocal DNSCache. It caches DNS responses in a local CoreDNS instance on each node at a link-local IP address — sub-millisecond cache hits.

## Why It Matters
NodeLocal DNSCache benefits: cache hit latency <1ms vs 5+ms network round-trip, reduces load on kube-dns cluster, eliminates conntrack race conditions (common source of 5s DNS timeouts), enables negative caching.

## Pro Tip
Check if NodeLocal DNSCache is working: kubectl exec aaa-- cat /etc/resolv.conf should show nameserver 169.254.20.10. If it shows the ClusterIP of kube-dns, NodeLocal is not active for that pod.

## Concepts
NodeLocal DNSCache, DNS latency, CoreDNS, 169.254.20.10, caching
