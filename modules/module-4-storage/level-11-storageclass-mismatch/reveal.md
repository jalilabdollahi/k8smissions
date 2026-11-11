# Reveal

PV `archive-2023` has class `archive`. PVC `archive` named no class, so the default class `standard` dynamically provisioned a new empty PV for it and the pod ran happily on that. `storageClassName` cannot be changed on a claim, so recreate it.

1. Compare: `kubectl get pv,pvc -n k8smissions` shows the claim bound to a generated `pvc-...` volume, not `archive-2023`.
2. Free the claim, recreate it with the right class and bring the pod back:

   ```bash
   kubectl scale deployment archive-reader -n k8smissions --replicas=0
   kubectl delete pvc archive -n k8smissions        # the stray dynamic volume is removed with it
   kubectl apply -f - <<'YAML'
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata: {name: archive, namespace: k8smissions}
   spec:
     accessModes: ["ReadWriteOnce"]
     storageClassName: archive
     resources: {requests: {storage: 10Gi}}
   YAML
   kubectl scale deployment archive-reader -n k8smissions --replicas=1
   ```
