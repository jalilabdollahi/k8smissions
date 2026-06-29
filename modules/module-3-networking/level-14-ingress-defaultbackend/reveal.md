## What went wrong

The Ingress backend has `service.name: app-serv` but the Service is named `app-service`. The Ingress controller looked for `app-serv`, found nothing, and returned 404 for every request. Kubernetes does not warn you about this at creation time — it only becomes visible when traffic fails.

## Fix

In manifest.yaml, correct the backend service name:

```yaml
backend:
  service:
    name: app-service
    port:
      number: 80
```

## Why Kubernetes doesn't reject it

Ingress resources are intentionally not validated against existing Services at admission time — Services may be created later. This flexibility means typos in service names cause silent 404 failures at runtime, not rejection at apply time.