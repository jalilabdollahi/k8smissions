## What went wrong

`policyTypes: [Egress]` combined with `egress: []` is a total egress block. Every outbound packet from every pod is dropped — including DNS queries to kube-dns. Without DNS, service names cannot resolve, which breaks virtually every application.

## Fix

In manifest.yaml, replace the empty egress list with rules that allow DNS and intra-namespace communication:

```yaml
egress:
- ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
- to:
  - podSelector: {}
```

## The trap

When you add an Egress policy to block external traffic, you almost always need to explicitly allow DNS (port 53) in the same policy — otherwise all name resolution stops. This is one of the most common NetworkPolicy mistakes in production.