# Reveal

The StatefulSet mounts one fixed claim, `pgdata-shared`, instead of having `volumeClaimTemplates`. All members share one directory, so the second member finds the first member's `node-id` and refuses to start.

1. Save the manifest: `kubectl get statefulset postgres-cluster -n k8smissions -o yaml > sts.yaml`.
2. Delete the StatefulSet and the shared claim (the volume is not needed any more):

   ```bash
   kubectl delete statefulset postgres-cluster -n k8smissions
   kubectl delete pvc pgdata-shared -n k8smissions
   ```
3. Edit `sts.yaml`: remove the `persistentVolumeClaim` entry from `spec.template.spec.volumes`, and add

   ```yaml
   volumeClaimTemplates:
     - metadata:
         name: pgdata
       spec:
         accessModes: ["ReadWriteOnce"]
         resources:
           requests:
             storage: 1Gi
   ```
   (also drop the status and metadata noise from the exported YAML), then `kubectl apply -f sts.yaml`.
4. Three claims `pgdata-postgres-cluster-0..2` appear and all members become Ready.
