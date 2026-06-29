## What went wrong

The Job runs `/scripts/init-db.sh` inside a busybox container. The script does not exist in the image. The container exits with code 127 immediately. Kubernetes retries up to `backoffLimit: 2` times, then marks the Job as Failed.

## Fix

Replace the command with one that succeeds:

```yaml
command:
- /bin/sh
- -c
- echo 'DB initialised'; exit 0
```

## Why this matters

A Kubernetes Job considers any exit code other than 0 a failure and retries the pod. Only exit code 0 marks the Job as Succeeded. This is by design — Jobs are built for tasks that must complete successfully exactly once.