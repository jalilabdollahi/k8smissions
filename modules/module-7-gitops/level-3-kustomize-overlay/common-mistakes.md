**Running `kubectl delete -k overlays/production` with `-n shop-prod`, or without `-n` at all.** The overlay does not fix a namespace, so the namespace flag (or your current context namespace) decides where the delete happens. Pointing it at `shop-prod` removes real production. Always pass `-n shop-staging`, and preview with `kubectl get -k ... -n shop-staging` first.

**Re-applying the staging overlay.** `kubectl apply -k overlays/staging` changes nothing: the `stg-` objects already exist and the `prod-` ones are not part of that overlay, so they stay. Apply never prunes.

**Deleting the quota or the namespace.** Removing the ResourceQuota makes the `stg-` pods start, but the `prod-` objects are still there and the check for a clean staging fails. Deleting the namespace destroys the staging objects the team needs.
