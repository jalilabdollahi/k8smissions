# Debrief: the ledger must outlive its claim

**What was wrong.** Nothing was broken yet, which is the danger. Both claims were provisioned dynamically by StorageClass `standard`, whose reclaim policy is `Delete`. Every PV it creates gets that policy. When the claim `ledger-data` is deleted for the rename, the provisioner removes the volume and the month-end close file with it.

**The evidence.** `kubectl get pv -o wide` lists a generated name (`pvc-<uid>`), the claim it is bound to and `Delete` in the RECLAIM POLICY column. The claim itself has no such field, which is why editing the PVC cannot help.

**Why Kubernetes behaves this way.** The reclaim policy answers "what should the cluster do with this volume once nobody claims it". It is stored on the PV and copied from the class at provisioning time. Changing the class later affects only future volumes, and the default class is shared, so it should not be edited for one workload. `Retain` leaves the PV in `Released` state with its data and its old `claimRef`, to be recovered by an administrator.

**The fix.** Patch the single PV that backs `ledger-data` to `Retain`. The scratch volume stays on `Delete`: retaining every volume would slowly fill the nodes with disks nobody will ever recover.

**In production.** Set `reclaimPolicy: Retain` on a dedicated StorageClass for data you cannot recreate, and use `Delete` for caches. Take snapshots as well: Retain protects against deleting the claim, not against corruption. A Released PV needs a manual step before reuse (see the later level on stale claimRef).

**Commands worth remembering**
- `kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,POLICY:.spec.persistentVolumeReclaimPolicy`
- `kubectl patch pv <name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'`
- `kubectl explain pv.spec.persistentVolumeReclaimPolicy`
