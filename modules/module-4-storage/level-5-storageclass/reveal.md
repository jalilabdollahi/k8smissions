# Reveal

`reports-data` asks for StorageClass `gp3`, which exists in the cloud cluster but not here, so the claim has nothing to provision it and the pod stays Pending behind it.

1. `kubectl describe pvc reports-data -n k8smissions` shows `storageclass.storage.k8s.io "gp3" not found`; `kubectl get storageclass` lists only `standard`.
2. Create the class `gp3` backed by the provisioner that `standard` uses:

   ```bash
   kubectl apply -f - <<'YAML'
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: gp3
   provisioner: rancher.io/local-path
   volumeBindingMode: WaitForFirstConsumer
   reclaimPolicy: Delete
   YAML
   ```
3. The claim is picked up automatically; the pod schedules and the claim binds.

Alternative: delete `reports-data` and recreate it with `storageClassName: standard` (the field is immutable on an existing claim).
