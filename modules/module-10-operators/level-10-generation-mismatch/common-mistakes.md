## Skipping the pass when observedGeneration equals generation

The writes stop, and the operator looks quiet, but it no longer repairs anything: delete `inventory-stock-us` and it stays gone, because the Inventory itself did not change. Only the status write is guarded; the child check runs every time.

## Fixing the timestamp but not the counter

Removing `lastSync` from the patch makes the object stable, but `observedGeneration` still has to equal `metadata.generation` after a spec change. Copy the generation instead of incrementing.

## Editing the ConfigMap and waiting

The pod imported the script when it started. A changed ConfigMap does not restart it; run `kubectl rollout restart` and check `kubectl logs` for the new behaviour.
