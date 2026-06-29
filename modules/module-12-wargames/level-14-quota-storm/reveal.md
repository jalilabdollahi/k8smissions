## What went wrong

Completed Kubernetes pods (phase `Succeeded` or `Failed`) continue to count against `ResourceQuota.spec.hard.pods` until they are explicitly deleted. A CI retry bug created 20 pods — each completing in seconds but never being cleaned up. The accumulated completed pods exhausted the namespace pod quota, blocking all new pod creations.

## Fix

```bash
kubectl delete pod -l job=ci-test -n k8smissions
```

Prevention (add to all CI Job specs):
```yaml
spec:
  ttlSecondsAfterFinished: 300  # auto-delete 5 minutes after completion
```

## Why this matters

ResourceQuota counts all pods regardless of phase — Running, Pending, Succeeded, Failed, and even Terminating. This surprises many teams who expect completed pods to be 'free'. Cleanup strategies:
1. **TTL controller**: `spec.ttlSecondsAfterFinished` on Jobs auto-deletes the Job and its pods after completion
2. **Admission webhook**: reject Jobs without `ttlSecondsAfterFinished` set
3. **Periodic cleanup CronJob**: `kubectl delete pods --field-selector=status.phase==Succeeded -n k8smissions`
4. **Limit pod count quota**: set a quota slightly below 'all theoretical pods at once' to catch accumulation before it blocks real workloads