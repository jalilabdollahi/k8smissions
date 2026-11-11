**Deleting the NetworkPolicy.** Quorum comes back, and the security team's isolation is gone with it. The validator checks that `intruder` still cannot reach a member and that clients cannot use the peer port.

**Fixing the policy only.** With DNS and 9000 open the members still report `Name or service not known`: a headless Service hides pods that are not Ready, and no pod is Ready until it sees the others. The last fault is not a policy at all.

**Allowing port 9000 from everywhere.** An ingress rule without a `from` (or with a wide selector) opens the gossip port to the intruder and to clients. Name `app: kv` as the source and destination for 9000.
