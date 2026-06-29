## What went wrong

The ConfigMap `app-config` was applied with empty string values. Because the Deployment uses `envFrom.configMapRef`, the empty strings become empty environment variables. The startup command `[ -n "$APP_MODE" ] && [ -n "$DB_HOST" ] && sleep 3600 || exit 1` evaluates the empty vars as false and exits 1 — causing immediate CrashLoopBackOff on all 3 replicas simultaneously.

## Fix

```yaml
data:
  APP_MODE: production
  DB_HOST: postgres.k8smissions.svc.cluster.local
```

Then: `kubectl rollout restart deployment/config-app -n k8smissions`

**Important**: simply updating a ConfigMap does not restart pods. Pods using `envFrom` or `env.valueFrom.configMapKeyRef` cache the values at container start time — they only pick up new values on restart.

## Why this matters

ConfigMap changes are decoupled from pod restarts by design — Kubernetes does not auto-restart pods on ConfigMap updates. This means bad config can be 'deployed' without anyone noticing until the next rollout or pod restart triggers the crash. Prevention strategies:
1. Validate ConfigMap values in CI before applying to the cluster
2. Use a rollout annotation (`kubectl.kubernetes.io/last-applied-configuration`) that changes on every ConfigMap update, triggering a rollout automatically
3. Use admission webhooks to reject ConfigMaps with empty required fields
4. Use `kubectl rollout restart` explicitly after config changes