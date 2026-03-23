# Quota Flood

## What Happened
A CI/CD pipeline hit a retry bug and created 50 identical test pods. Each pod counts against the namespace ResourceQuota. When the quota was exhausted, legitimate deployments could no longer create pods — they showed "exceeded quota" errors.

## The Fix
```bash
# Use label selector for bulk delete
kubectl delete pod -l job=ci-test -n k8smissions

# Verify quota is freed
kubectl describe quota ns-quota -n k8smissions
```

## Key Lessons
- **Always label CI pods** — it makes bulk cleanup trivial
- **TTLSecondsAfterFinished** on Jobs auto-cleans completed pods
- **ResourceQuota events** — `kubectl describe quota` shows current usage vs limits
- **Admission controllers** — tools like Kyverno can enforce pod count limits per label

## Prevention
```yaml
spec:
  ttlSecondsAfterFinished: 300  # in Job spec
```
