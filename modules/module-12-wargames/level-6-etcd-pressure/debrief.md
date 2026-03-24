# etcd Pressure

## What Happened
CI/CD pipelines created a ConfigMap for every pipeline run but never cleaned them up. Over time these accumulated into thousands of objects, approaching etcd's storage limit (default 8GB).

## The Fix
```bash
# Delete all stale CI run ConfigMaps
kubectl delete configmap -n k8smissions \
  $(kubectl get cm -n k8smissions --no-headers | awk '/^ci-run-/{print $1}')
```

## Key Lessons
- **etcd has a hard size limit** — when it fills up the API server becomes read-only
- **CI/CD pipelines must clean up after themselves** — use TTL or post-job hooks
- **kubectl bulk operations** — label-based selection is cleaner: `kubectl delete cm -l pipeline=ci -n k8smissions`
- **CronJob cleaners** — run a periodic cleanup job to prune old objects

## Prevention
```yaml
# In your CI pipeline pod spec
ttlSecondsAfterFinished: 300  # auto-delete Job after 5 minutes
```
