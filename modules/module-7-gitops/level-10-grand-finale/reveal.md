1. `targetRevision: release-2.3` names a branch that was deleted. Point it at `main`: `kubectl -n argocd patch app grand-finale-app --type merge -p '{"spec":{"source":{"targetRevision":"main"}}}'`.
2. `helm.valueFiles` lists `values-prod.yml`, the file is `values-production.yaml`. Fix the name (do not use `ignoreMissingValueFiles`: Helm then falls back to the dev defaults).
3. The pods are rejected by the namespace quota (`kubectl -n k8smissions get events`, `describe rs`): the chart sets no `resources.requests`. Add requests that fit the quota for 2 replicas, in `values-production.yaml` or as Helm parameters.
4. The Application is now Healthy, but `service.targetPort: 8080` in the production values points at a port nothing listens on (the container uses 5678). Fix it in the values file (commit and push) or as a parameter.
5. Hard refresh, wait for Synced and Healthy, and test the Service from `probe`.
