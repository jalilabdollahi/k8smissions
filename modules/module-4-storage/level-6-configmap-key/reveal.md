## What went wrong

The pod references `key: database_host` from ConfigMap `app-config`. That key does not exist in the ConfigMap's data section. Kubernetes cannot inject the environment variable and refuses to start the container.

## Fix

In manifest.yaml, add the missing key to the ConfigMap:

```yaml
data:
  app_name: "MyApp"
  app_version: "1.0.0"
  database_host: "postgres.k8smissions.svc.cluster.local"
```

## Tip: optional keys

If you want Kubernetes to skip a missing key instead of failing, add `optional: true` to the configMapKeyRef:

```yaml
configMapKeyRef:
  name: app-config
  key: database_host
  optional: true
```

The env var will be empty instead of causing CreateContainerConfigError. Use this only when the application handles a missing value gracefully.