# Reveal

The `uploads` volume is an `emptyDir`. It lives exactly as long as the pod: a container restart keeps it, a deleted or rescheduled pod loses it.

1. Create a claim for the data:

   ```bash
   kubectl apply -f - <<'YAML'
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata: {name: customer-uploads, namespace: k8smissions}
   spec:
     accessModes: ["ReadWriteOnce"]
     resources: {requests: {storage: 1Gi}}
   YAML
   ```
2. Replace the source of the `uploads` volume (index 1; keep `scratch` as an emptyDir):

   ```bash
   kubectl patch deployment data-app -n k8smissions --type=json \
     -p '[{"op":"replace","path":"/spec/template/spec/volumes/1","value":{"name":"uploads","persistentVolumeClaim":{"claimName":"customer-uploads"}}}]'
   ```
3. Wait for the rollout, upload a file, delete the pod and download it again.
