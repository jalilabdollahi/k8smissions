# Reveal

The pod mounts a claim called `orders-db-data`. No such claim exists; the one that looks related, `orders-data`, is unrelated and unused.

1. Confirm the cause: `kubectl describe pod -l app=orders-db -n k8smissions` shows `persistentvolumeclaim "orders-db-data" not found`.
2. Create the missing claim with the exact name the pod references:

   ```bash
   kubectl apply -n k8smissions -f - <<'YAML'
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: orders-db-data
   spec:
     accessModes: ["ReadWriteOnce"]
     resources:
       requests:
         storage: 1Gi
   YAML
   ```

3. The scheduler retries on its own; once the pod is scheduled, `standard` provisions the volume and the claim turns Bound. (Alternative: patch the Deployment to use `orders-data`.)
