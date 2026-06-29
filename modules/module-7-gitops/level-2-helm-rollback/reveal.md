## What went wrong

A Helm upgrade was run with a bad `image.tag` value — `broken-tag` doesn't exist in Docker Hub. Every pod in the Deployment enters `ImagePullBackOff` simultaneously.

## Fix

```yaml
spec:
  containers:
  - name: webapp
    image: nginx:1.27.4
```

In a real Helm environment, the recovery would be:
```bash
# See revision history
helm history webapp -n k8smissions

# Roll back to the last working revision
helm rollback webapp 1 -n k8smissions
```

## Why this matters

`helm rollback` is one of Helm's most valuable features. Each `helm upgrade` stores a versioned snapshot of the rendered manifests (as a Kubernetes Secret in the release namespace). A rollback atomically re-applies a previous snapshot. For zero-downtime safety, use `--atomic` on upgrades: if any pod fails to become ready within the timeout, Helm rolls back automatically without operator intervention.