## Tolerating the control-plane taint

The third replica schedules there, so the Pending goes away, but the control plane is not meant to run workloads and the objective keeps pods on the workers.

## Scaling to 2 replicas

Pending disappears and so does the third replica; the finance commitment is for 3. The fix has to make the third replica schedulable, not remove it.

## Deleting the affinity block with no replacement

All three pods then run, but nothing pushes replicas apart, so on a bad day all three can land on one node. Keep a soft rule or a spread constraint.
