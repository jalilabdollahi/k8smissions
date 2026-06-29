## What went wrong

The Python command allocates 128 × 1MB strings (128MB total), but the container's memory limit is only 64Mi. When memory usage crosses the limit, the Linux kernel OOM-kills the process with SIGKILL (signal 9), which produces exit code 137 (128 + 9). No application-level error is written — the process is killed externally, not by a crash.

## Fix

```yaml
resources:
  limits:
    memory: 256Mi
  requests:
    memory: 64Mi
```

## Why this matters

Exit codes tell you the cause of a container termination:
- `0` — clean exit
- `1` — application crash (unhandled exception, etc.)
- `137` — OOM kill (SIGKILL from kernel)
- `143` — graceful shutdown (SIGTERM)

OOM kills leave no log output because the process is interrupted externally. Always check `kubectl describe pod` → Last State → Exit Code before looking for logs when a pod keeps restarting silently.