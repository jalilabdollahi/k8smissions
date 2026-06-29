## What went wrong

The `api-watcher` Deployment was accidentally scaled to 50 replicas. Each pod maintains a persistent HTTP/2 watch stream to the API server. 50 concurrent watch connections from a single application, combined with controllers, operators, and monitoring tools, overwhelms the API server's connection queue. All operations slow down or time out.

## Fix

```yaml
spec:
  replicas: 2
```

## Why this matters

The Kubernetes API server is a centralized bottleneck — every kubectl command, every controller reconciliation, and every watch connection goes through it. API server load is dominated by:
- **Watch connections**: each connection holds an HTTP/2 stream open, consuming memory and goroutines
- **List operations**: full list scans are expensive — prefer watches
- **Admission webhooks**: each mutating/validating webhook adds an API server outbound call

Protections:
1. **ResourceQuota `count/pods`**: cap maximum pod count per namespace
2. **HPA maxReplicas**: prevent accidental scale-out beyond sensible limits
3. **API priority and fairness (APF)**: Kubernetes APF queues and rate-limits requests by priority class, preventing one actor from starving others
4. **Monitoring**: alert on `apiserver_request_duration_seconds_p99 > 1s`