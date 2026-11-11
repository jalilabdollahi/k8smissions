1. `kubectl get ns payments-sandbox -o yaml` shows a condition about a failed discovery of `reports.example.io/v1beta1`, not about a finalizer. The namespace is empty apart from what is already being deleted.
2. `kubectl get apiservice` lists `v1beta1.reports.example.io` as `False (MissingEndpoints)`: its Service `reports-api` in `k8smissions` has no pods.
3. The tenant no longer uses that API, so delete the dead registration: `kubectl delete apiservice v1beta1.reports.example.io`.
4. The namespace controller can enumerate all kinds again, the namespace is removed, and the Application's finalizer completes. `keep-me` was never touched.
