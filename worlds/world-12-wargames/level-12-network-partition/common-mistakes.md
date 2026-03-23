# Common Mistakes — Split Cluster

## ❌ Deleting the deny-all policy
This removes your security posture. Add allow rules instead.

## ❌ Forgetting egress
A deny-all policyTypes: [Ingress, Egress] blocks DNS lookups too — add egress rules for port 53.
