## What went wrong

CI/CD pipelines create per-run ConfigMaps to pass build metadata but never clean them up. 20 ConfigMaps simulate what becomes thousands in a busy cluster — each object is a key in etcd, and list operations (LIST configmaps) scan all keys matching the prefix. Thousands of CI artifacts bloat etcd and slow down every `kubectl get` and controller list call.

## Fix

```bash
kubectl delete configmap -n k8smissions \
  $(kubectl get cm -n k8smissions --no-headers | awk '/^ci-run-/{print $1}')
```

Prevention for CI Jobs:
```yaml
spec:
  ttlSecondsAfterFinished: 300
```

## Why this matters

etcd stores all Kubernetes objects as key-value pairs. Object count matters:
- **List latency**: listing all ConfigMaps scans all keys with the prefix — more objects = longer scans
- **Watch cost**: each object change broadcasts to all watchers — more objects = more events
- **Storage quota**: hitting etcd's quota (default 2GB, recommended 8GB) makes the cluster read-only

Cleanup strategies:
1. **TTL controllers**: `Job.spec.ttlSecondsAfterFinished` auto-deletes jobs and their pods
2. **Label-based cleanup**: label CI objects at creation (`pipeline=ci`) then delete by label
3. **CronJob cleanup**: run a periodic job that deletes old artifacts
4. **Admission webhooks**: reject CI object creation without a TTL label set