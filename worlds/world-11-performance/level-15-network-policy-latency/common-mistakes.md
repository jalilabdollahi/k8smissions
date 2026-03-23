# Common Mistakes — Firewall Tax

## Mistake 1: Reducing NetworkPolicy rules to reduce overhead

**Wrong approach:** Fewer rules helps but doesn't solve O(n) scaling

**Correct approach:** eBPF is the architectural fix — O(n) iptables vs O(1) eBPF hash maps
