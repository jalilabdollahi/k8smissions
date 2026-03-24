# DNS Blackout

## What Was Broken
A NetworkPolicy with `policyTypes: [Egress]` and `egress: []` blocks ALL outbound traffic. DNS queries to kube-dns (port 53 UDP/TCP) were silently dropped, causing all hostname resolution to fail.

## The Fix
Add an egress rule permitting port 53 on both UDP and TCP to any destination (or specifically to kube-system pods with the kube-dns label). Also add an egress rule for pods in the same namespace if intra-namespace communication is needed.

## Why It Matters
This is the most common NetworkPolicy mistake. `egress: []` looks like an empty list that does nothing — but once `policyTypes: [Egress]` is set, an empty list is a full deny. Always add a DNS egress exception when using egress policies.

## Pro Tip
Use `kubectl exec -it <pod> -- nslookup kubernetes.default` as a quick DNS sanity check. If it times out, check all NetworkPolicies in the namespace with `kubectl get netpol -n <ns> -o yaml`.

## Concepts
NetworkPolicy, egress, DNS, port 53, CoreDNS, kube-dns
