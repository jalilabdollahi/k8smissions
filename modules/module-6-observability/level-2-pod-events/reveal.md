## What went wrong

The pod uses `nginx:broken-tag` — a tag that doesn't exist in Docker Hub. The container runtime tries to pull the image, gets a 404 from the registry, and the pod enters `ImagePullBackOff`. Because the container never started, there are no logs — the log buffer is empty.

## Fix

```yaml
spec:
  containers:
  - name: events-pod
    image: nginx:1.27.4
```

## Why this matters

When `kubectl logs` returns nothing, the container either hasn't started yet or exited before writing anything. In both cases, `kubectl describe pod` is your first tool — the Events section records every state transition with a reason and message. For image errors, the reason will be `ErrImagePull` (first attempt) or `ImagePullBackOff` (subsequent attempts with backoff). This diagnostic path — logs empty → check events — is the most common first step in pod debugging.