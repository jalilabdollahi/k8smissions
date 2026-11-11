## Hunting for node memory pressure

Evictions suggest a sick node, and `kubectl top node` or a cordon feels productive. The node conditions are healthy; the eviction message names the emptyDir limit. Read the Evicted pod before touching anything on the node.

## Removing or inflating the emptyDir sizeLimit

The pods stop being evicted for a while, but the spool grows without bound and will eventually fill the node's disk. The validator requires a limit of at most 100Mi and a spool that stays below it.

## Deleting the Evicted pods and calling it done

Clearing them tidies the list, but the replacement pods fill the volume and get evicted again within a minute. Cleanup is optional; the retention fix is not.
