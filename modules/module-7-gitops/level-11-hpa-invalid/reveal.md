1. `kubectl -n argocd get app reports -o yaml` shows the sync failing on the HorizontalPodAutoscaler: `minReplicas: 8` with `maxReplicas: 4` is rejected by validation, and because the sync is one operation the new image in the same commit is not rolled out either.
2. Correct the replica range in `manifests/hpa.yaml`, commit and push. The sync now succeeds, but the HPA reports `ScalingActive=False` / `FailedGetScale`.
3. `kubectl describe hpa reports` shows it looks for `reports-api`; the Deployment is `reports`. Fix `scaleTargetRef.name`, commit and push again.
4. After a refresh the Application is Synced and Healthy, the pods run the new image and the HPA reports current CPU metrics.
