## What went wrong

The VirtualService timeout of 15 seconds is shorter than the backend's actual processing time. When a request exceeds the timeout, Istio's Envoy sidecar cancels the request and returns a 504 to the caller — even if the backend would have successfully completed the work a few seconds later.

## Fix

```yaml
http:
- timeout: 120s
  retries:
    attempts: 3
    perTryTimeout: 30s
    retryOn: 5xx,reset,connect-failure,retriable-4xx
  route:
  - destination:
      host: backend.k8smissions.svc.cluster.local
      port:
        number: 8080
```

## Why this matters

Timeout and retry configuration in a service mesh are separate concerns:
- **timeout**: the total budget for the entire request including all retries
- **perTryTimeout**: the budget for a single attempt before retrying
- **retryOn**: which error conditions trigger a retry

The key invariant: `perTryTimeout × attempts ≤ timeout` (with some slack). Retrying non-idempotent operations (POST, payments, writes) requires application-level idempotency keys — don't blindly retry all 5xx errors if the backend doesn't handle duplicate requests safely.