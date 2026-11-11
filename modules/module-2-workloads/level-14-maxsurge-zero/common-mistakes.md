## Deleting the Pending pod

The ReplicaSet creates another one that cannot schedule either. The strategy decides whether a surge pod is allowed at all, so the pod is not the problem.

## Switching to `Recreate`

It would unblock the rollout, but takes both pods down together and drops requests during every release. The validator runs a second rollout and fails the Service if any request is lost.

## Setting `maxSurge` to 0 and leaving `maxUnavailable` at the default

`maxSurge: 0` with `maxUnavailable` rounded down to 0 is invalid, and the API server rejects it. The second value has to move too.
