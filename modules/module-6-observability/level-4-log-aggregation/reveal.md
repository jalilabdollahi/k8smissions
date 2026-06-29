## What went wrong

The pod spec has `args: [/missing.sh]` — a script that doesn't exist in the busybox image. Every time the container starts, it tries to execute the missing file, gets a shell error, and exits with a non-zero code. Kubernetes restarts it, and the cycle repeats.

## Fix

Remove the broken args and replace with a valid command:

```yaml
spec:
  containers:
  - name: logs-pod
    image: busybox:1.36
    command:
    - /bin/sh
    - -c
    - sleep 3600
```

## Why this matters

`kubectl logs --previous` is essential for debugging crash loops — it retrieves the stdout/stderr of the container that just died. Without it, a restarting pod's logs reset on every restart and you only see the current (empty) buffer. The flags `--since`, `--tail`, and `--timestamps` are also useful for narrowing down logs in a running container. In production, a centralized log aggregator (Loki, Elasticsearch, CloudWatch Logs) retains logs across restarts and is essential for post-incident review.