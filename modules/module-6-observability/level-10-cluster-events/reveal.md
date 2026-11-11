The cache in `cache-tier` never started: its pod mounts Secret `cache-auth`, which does not exist in that namespace. `inventory-sync` could not connect and crash-looped.

1. `kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp` shows `FailedMount ... secret "cache-auth" not found` on the cache pod, older than the app's failures.
2. Copy the password the app already uses: `kubectl -n cache-tier create secret generic cache-auth --from-literal=password="$(kubectl -n k8smissions get secret inventory-cache-credentials -o jsonpath='{.data.CACHE_PASSWORD}' | base64 -d)"`.
3. The kubelet retries the mount with a back-off, so restart the cache pod (`kubectl -n cache-tier rollout restart deploy/inventory-cache`) and then the sync pod to leave CrashLoopBackOff.
