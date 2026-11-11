kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp
kubectl -n cache-tier describe pod -l app=inventory-cache
PW=$(kubectl -n k8smissions get secret inventory-cache-credentials -o jsonpath='{.data.CACHE_PASSWORD}' | base64 -d)
kubectl -n cache-tier create secret generic cache-auth --from-literal=password="$PW"
kubectl -n cache-tier rollout restart deploy/inventory-cache
kubectl -n cache-tier rollout status deploy/inventory-cache --timeout=90s
kubectl -n k8smissions rollout restart deploy/inventory-sync
kubectl -n k8smissions rollout status deploy/inventory-sync --timeout=60s
