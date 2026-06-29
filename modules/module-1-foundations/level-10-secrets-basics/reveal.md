## What went wrong

The pod reads `DB_USERNAME` and `DB_PASSWORD` from a Secret named `db-credentials` using `secretKeyRef`. The Secret does not exist, so Kubernetes cannot build the environment for the container.

## Fix

Add the Secret to manifest.yaml before the Pod:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: k8smissions
type: Opaque
stringData:
  username: appuser
  password: mypassword
---
apiVersion: v1
kind: Pod
# ... rest of pod spec unchanged
```

## ConfigMap vs Secret

Both inject configuration into pods, but Secret is intended for sensitive data (passwords, tokens, keys). Kubernetes stores Secret values base64-encoded — this is encoding, not encryption. In production, use a secrets manager like HashiCorp Vault or the External Secrets Operator.