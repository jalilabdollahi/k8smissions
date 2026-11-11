1. `kubectl describe pod` Events: `couldn't find key password in Secret k8smissions/reports-db`.
2. `kubectl get secret reports-db -o jsonpath='{.data}'` shows the keys are `db-user` and `db-password`.
3. Edit Deployment `reports-api` so the `secretKeyRef` uses `key: db-password`; the rollout replaces the pods and they authenticate.
