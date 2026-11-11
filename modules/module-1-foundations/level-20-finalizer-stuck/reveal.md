1. `kubectl get configmap export-lock -o yaml` shows `deletionTimestamp` set and `finalizers: [backup.acme.io/release]`: the delete was accepted, then paused for the finalizer's owner.
2. The backup operator that would remove that finalizer is uninstalled, so it stays forever; `--force` cannot help.
3. Remove the finalizer with `kubectl patch configmap export-lock --type=merge -p '{"metadata":{"finalizers":null}}'`. The API server deletes the object immediately.
4. Create the new one: `kubectl create configmap export-lock --from-literal=owner=billing`.
