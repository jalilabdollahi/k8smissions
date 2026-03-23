# DNS Flood

## What Was Broken
Default ndots: 5 caused 5 DNS lookups for every single-word hostname (db, cache, api). With the app querying 3 hostnames every 100ms, that's 150 DNS queries/second. The app was the source of the DNS storm.

## The Fix
Set ndots: 2 (or use FQDNs). With ndots: 2, names with 2+ dots are treated as FQDNs directly — much fewer unnecessary lookups.

## Why It Matters
ndots recommendation: set to 2 for most applications. This means: 'db' still tries search domains (1 dot), but 'db.namespace' goes direct (2 dots = FQDN treatment). For microservices always use FQDNs: service.namespace.svc.cluster.local.

## Pro Tip
Enable NodeLocal DNSCache (1.18+) to reduce load on kube-dns: a DaemonSet caches DNS on each node, drastically reducing centralized DNS load. Critical for high-throughput microservices.

## Concepts
DNS, ndots, resolv.conf, DNS performance, FQDN, NodeLocal DNSCache
