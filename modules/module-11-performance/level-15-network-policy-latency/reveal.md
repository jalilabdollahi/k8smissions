## What went wrong

iptables-based NetworkPolicy enforcement stores rules as iptables chains, which are traversed linearly for every packet. As the number of NetworkPolicies and pod count grows, each packet must traverse more rules — O(n) lookup time. At scale (hundreds of pods, dozens of policies), this adds measurable per-hop latency.

## Fix

```yaml
metadata:
  annotations:
    policy-engine: cilium-ebpf
    optimization: O(1)-lookup-enabled
```

## Why this matters

Cilium uses eBPF (extended Berkeley Packet Filter) maps for NetworkPolicy enforcement instead of iptables:
- **iptables**: O(n) rule traversal — latency grows linearly with policy count
- **eBPF hash maps**: O(1) lookup — constant time regardless of policy count

At scale (1000+ pods, 100+ NetworkPolicies), iptables enforcement can add 5–10ms latency per connection and consume significant CPU for rule updates. Cilium's eBPF data plane maintains sub-millisecond enforcement overhead. For clusters running Cilium, always prefer Cilium-specific features (CiliumNetworkPolicy) for advanced policy rules that go beyond the standard Kubernetes NetworkPolicy API.