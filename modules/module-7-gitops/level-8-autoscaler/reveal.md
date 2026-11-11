Git pins `spec.replicas: 1` and Argo's self-heal enforces it, while the HPA (min 3) sets it back to 3 every time metrics-server reports a sample. Each side reverts the other.

1. `kubectl -n k8smissions get rs -l app=storefront -w` and `kubectl describe hpa storefront` show the scale events; the Application's diff is only on `/spec/replicas`.
2. Make Argo ignore that one field and also skip it when a sync does run:
   `kubectl -n argocd patch app storefront --type merge -p '{"spec":{"ignoreDifferences":[{"group":"apps","kind":"Deployment","jsonPointers":["/spec/replicas"]}],"syncPolicy":{"syncOptions":["RespectIgnoreDifferences=true"]}}}'`
3. The HPA now owns the count; the Deployment settles at 3 and the Application stays `Synced`.

Alternative: delete `replicas` from `manifests/deployment.yaml` in Git (commit and push). Deleting the HPA or turning off automated sync only hides the symptom.
