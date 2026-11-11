# Debrief: the volume that still belongs to a deleted claim

**What was broken.** `billing-pv` was created with `Retain`, so deleting namespace `billing-v1` (and with it the claim) left the volume and its data in place. A retained volume goes to `Released`, and keeps `spec.claimRef` pointing at the old claim. The new claim `billing-data` in `k8smissions` asked for `billing-pv` by name, and stayed Pending.

**The evidence.** `kubectl describe pvc billing-data` reports that the volume is already bound to a different claim. `kubectl get pv` shows `Released` rather than `Available`, and the `claimRef` has the namespace `billing-v1` and a UID that no longer exists.

**Why Kubernetes behaves this way.** `Retain` is a promise not to delete data, so the volume is not handed to anyone automatically: it could still hold another team's information. The controller leaves the old `claimRef` so that an administrator must take an explicit decision. Clearing it is that decision: the volume becomes `Available` and the next matching claim can bind.

**The fix.** `kubectl patch pv billing-pv --type=merge -p '{"spec":{"claimRef":null}}'`. Deleting and recreating the PV would work for a cloud disk only if you knew its backing ID, and for this local volume would lose the pointer to the directory. You could also keep the reservation and edit it to name the new claim, but clearing is simpler.

**In production.** Before clearing a Released volume, check who owned the data and whether it must be wiped, the retain flow is where leaks between tenants happen. Document the claim names, because a rebuilt claim is the only way back to a retained disk. Snapshots are safer than hoping the PV survives.

**Commands worth remembering**
- `kubectl get pv -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CLAIM:.spec.claimRef.name`
- `kubectl patch pv <name> --type=merge -p '{"spec":{"claimRef":null}}'`
- `kubectl describe pvc <name>`: events say why binding fails.
