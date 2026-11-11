Three faults, each hiding the next:

1. Egress is restricted to peers on 8080 with no DNS rule, so members cannot resolve `kv-N.kv-peers...`. Add an egress rule to the `kube-dns` pods in `kube-system` on port 53 (UDP and TCP).
2. Members gossip on 9000 but the policy only admits 8080 in both directions. Add port 9000 to the ingress rule from `app: kv` and to the egress rule to `app: kv`. Do not open 9000 to clients.
3. A Ready pod is one that sees a quorum, and a headless Service only publishes Ready pods in DNS, so no member can ever see another: a bootstrap deadlock. `kubectl patch svc kv-peers --type=merge -p '{"spec":{"publishNotReadyAddresses":true}}'`.

Deleting the policy restores quorum, but the `intruder` pod could then reach the store; the validator keeps that closed.
