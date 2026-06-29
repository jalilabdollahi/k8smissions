## What went wrong

The Deployment was updated to `image: nginx:nonexistent-v2.0-xyz` — a tag that does not exist. All pods entered ImagePullBackOff because the registry returned 404.

## Fix

Roll back immediately:

```bash
kubectl rollout undo deployment/web-app -n k8smissions
```

Then verify recovery:

```bash
kubectl rollout status deployment/web-app -n k8smissions
```

Finally update manifest.yaml image to match the working revision:

```yaml
image: nginx:latest
```

## Why this matters

Kubernetes keeps a rollout history (controlled by `revisionHistoryLimit`, default 10). This makes rollback instant — no rebuild, no re-push, just pointer to an old ReplicaSet. In a real incident, `kubectl rollout undo` is often the first command you run.