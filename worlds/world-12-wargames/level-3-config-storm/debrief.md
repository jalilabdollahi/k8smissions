# Bad Config Rollout

## What Happened
A ConfigMap was updated with empty values for APP_MODE and DB_HOST. The application checks for these at startup and exits with code 1 if they're missing, causing a CrashLoopBackOff across all replicas simultaneously.

## The Fix
```bash
kubectl edit configmap app-config -n k8smissions
# Set APP_MODE: production
# Set DB_HOST: postgres.k8smissions.svc.cluster.local
```
Pods using envFrom will pick up the change on their next restart.

## Key Lessons
- **ConfigMap changes don't automatically restart pods** — you may need to rollout restart
- **Validate ConfigMaps before applying** in CI/CD pipelines
- **envFrom vs env** — envFrom injects all keys; if any required key is missing/empty your app may fail silently
- **GitOps config management** prevents this by requiring review of config changes

## Rollout Restart
```bash
kubectl rollout restart deployment/config-app -n k8smissions
```
