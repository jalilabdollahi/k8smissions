# Reveal

Both claims were provisioned by the `standard` class, so their PVs were created with `persistentVolumeReclaimPolicy: Delete`: deleting the claim would delete the volume and its data. The policy is copied into each PV at creation, so the fix is on the PV (editing the claim or the class does nothing for volumes that already exist).

1. Find the PV behind the claim: `kubectl get pvc ledger-data -n k8smissions -o jsonpath='{.spec.volumeName}'`.
2. Change only that PV:

   ```bash
   kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
   ```
3. Check with `kubectl get pv`: ledger-data's volume says `Retain`, the scratch volume still says `Delete`.
