## Editing the RuntimeClass overhead down to zero

Newly created pods would fit, but the sandbox really costs that memory and the security team's guarantee is gone. The validator keeps the 700Mi overhead for that reason. Size the workload, not the class.

## Removing `runtimeClassName` from the Deployment

The pod schedules at once and breaks the compliance requirement the mission names. A Pending pod that is allowed to run unsandboxed is not a fix.

## Deleting a `tenant-*` Deployment to free memory

It frees room, but those pods belong to other teams, and the request was inflated to begin with. Look at what the process actually needs before taking someone else's capacity.
