**What was broken.** Three layers failed in sequence. The Friday `kv-lockdown` policy restricted egress without allowing DNS, so members could not resolve their peers. It also allowed only port 8080 between members while the gossip port is 9000. And underneath, the headless Service `kv-peers` did not publish not-ready addresses, while a member is only Ready when it sees a quorum: a bootstrap deadlock that no policy change alone could break.

**The evidence.** The logs of `kv-0` printed `peer kv-1: unreachable: [Errno -3] Temporary failure in name resolution` first. After DNS was allowed the message changed to `Name or service not known` (no DNS record yet), and after the Service fix it became `timed out` until port 9000 was opened. Each message pointed at a different layer.

**Why Kubernetes behaved this way.** A NetworkPolicy that selects a pod for egress denies everything not listed, including port 53. A headless Service publishes DNS records only for Ready pods unless `publishNotReadyAddresses` is true; that flag exists for clustered software that must find peers before it is healthy. Policies are additive per port and direction, so ingress on the receiver and egress on the sender both need the rule.

**The fix.** Allow DNS egress, add 9000 to both peer rules, and publish not-ready addresses on the headless Service. Keep the policy: the validator proves an unrelated pod is still shut out.

**In production.** Ship default-deny with a tested DNS rule; use `Parallel` pod management and `publishNotReadyAddresses` for quorum systems; let peers use a readiness that does not depend on their own quorum when possible.

**Commands to remember.** `kubectl logs <pod>`, `kubectl describe networkpolicy`, `kubectl exec <pod> -- nslookup <name>`, `kubectl explain service.spec.publishNotReadyAddresses`.
