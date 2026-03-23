# Firewall Tax

## What Was Broken
iptables-based NetworkPolicy has O(n) per-packet cost. With many policies and pods, each packet traverses thousands of iptables rules. The network policy itself became a significant performance bottleneck.

## The Fix
Migrate to Cilium with eBPF data plane. eBPF hash maps do O(1) lookups — network policy is enforced with near-zero overhead regardless of policy count.

## Why It Matters
Cilium advantages beyond performance: L7 policy (HTTP method/path), DNS-based policy (allow traffic to github.com), identity-based policy (not just IP), Hubble observability. eBPF replaces iptables, kube-proxy, and NetworkPolicy enforcement.

## Pro Tip
Before Cilium migration, profile actual iptables overhead: iptables -L | wc -l on a node. More than 5,000 rules indicates iptables scaling issues that eBPF would solve.

## Concepts
NetworkPolicy, iptables, eBPF, Cilium, O(1) lookup, network performance
