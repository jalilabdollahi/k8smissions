## Lowering the app container's request

The app request is 100Mi and not the problem. The effective request is the larger of the init container and the app total, so changing the smaller side changes nothing.

## Dropping the init container's memory limit to match

A limit under about 550Mi makes the migration OOMKilled, so the pod schedules and then the init container fails. Lower the request for scheduling; keep the limit comfortably above what the migration really holds.

## Deleting the reserved-capacity pods

That frees memory, but those pods are held for another team. The request on the init container was the part that was oversized.
