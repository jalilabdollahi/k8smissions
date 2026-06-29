## What went wrong

`image: nginx:nonexistent-tag-xyz-123` — this tag does not exist. When Kubernetes tries to pull it, the registry returns a 404. After a few failed attempts it enters BackOff mode and stops retrying immediately.

## Fix

Change the image tag to one that exists:

```yaml
image: nginx:latest
```

## Why this matters

In production, using `latest` is discouraged — a new image version could be pulled unexpectedly and break your app. Prefer a specific version tag like `nginx:1.25.3` so the cluster always runs the exact version you tested with.