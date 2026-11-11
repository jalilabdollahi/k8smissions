## Tolerating every taint

`operator: Exists` with no key tolerates the reclaimed taint as well. Pods can then be placed on the dead spot node, which the check rejects: tolerate only the taint of the node you want.

## Fixing only the toleration

With the nodeSelector still asking for `lifecycle=spot`, the on-demand node is filtered out before taints even matter, and the spot node still has its taint. Both blockers have to go.

## Removing the taint from the on-demand node

The pods would start, but the taint exists to keep ordinary workloads off paid capacity. It is a policy of the node, and the check requires it to stay.
