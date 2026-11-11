**What was broken.** An egress NetworkPolicy allowed DNS only over UDP. That is enough for nearly every lookup, but one name had 60 A records. Its answer did not fit in a classic 512 byte UDP reply, so the server set the TC (truncated) bit, and the resolver's TCP retry was dropped by the policy.

**The evidence.** The application log shows `quotes` and `currency` at a few milliseconds and `sku-history` at about 5000 ms, then `FAILED`. 5 seconds is the resolver's default timeout. `kubectl describe networkpolicy` lists only `UDP 53`. The query log on `catalog-dns` shows the UDP question arriving and no TCP session after it. From a pod that is not covered by the policy the same name resolves instantly.

**Why Kubernetes behaved this way.** NetworkPolicy is a plain allow-list per protocol and port: with `policyTypes: [Egress]` everything not listed is dropped without any error, and a dropped SYN is a silent timeout, not a refusal. DNS is "UDP 53" only in the common case; the protocol requires TCP for large answers, and EDNS0 buffers (not used by musl) only raise the limit.

**The fix.** Allow TCP 53 as well, to the same destination. Keep the rest of the policy: opening all egress passes this lookup but removes the control the security team wanted.

**In production.** Always allow both UDP and TCP 53 in DNS egress rules; the same applies to kube-dns. Large answers also come from DNSSEC, many endpoints on a headless Service and long TXT records, so this fails in surprising places.

**Worth remembering.**
- `kubectl describe networkpolicy <name>`
- `kubectl exec <pod> -- nslookup -vc <name> <server>` (force TCP)
- `kubectl logs deploy/catalog-dns`
