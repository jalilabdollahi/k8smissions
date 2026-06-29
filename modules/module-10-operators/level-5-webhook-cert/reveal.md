## What went wrong

The webhook's `caBundle` is a base64-encoded CA certificate that the API server uses to verify the webhook service's TLS certificate. If the cert was rotated (manually or by cert-manager) without updating the `caBundle`, the API server rejects the TLS handshake and all covered admission requests fail.

## Fix

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: pod-annotations-injector
  annotations:
    cert-manager.io/inject-ca-from: operators/webhook-cert
webhooks:
- name: inject.example.com
  clientConfig:
    service:
      name: webhook-service
      namespace: operators
      port: 443
    # caBundle removed — cert-manager injects it automatically
```

## Why this matters

Hardcoded `caBundle` values are a maintenance trap: every time the cert rotates, the webhook config must be manually updated or webhook calls fail cluster-wide. cert-manager's CA injector watches for the annotation and keeps the `caBundle` current whenever the cert is rotated. This is the standard pattern for production webhook certificate management. Without it, cert expiry becomes a production incident.