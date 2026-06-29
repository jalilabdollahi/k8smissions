## What went wrong

The Secret manifest was committed to Git with `stringData` containing real credentials. Kubernetes Secrets are base64-encoded — anyone who runs `echo 'cGxhaW4tcGFzcw==' | base64 -d` gets the plaintext. In a GitOps workflow where Git is the source of truth, this means credentials are exposed to everyone with repo read access.

## Fix

Mark the Secret as externally managed:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: k8smissions
  annotations:
    managed-by: external-secrets
type: Opaque
stringData:
  username: app-user
  password: rotated-pass
```

In a real External Secrets Operator setup, you would replace the Secret with an `ExternalSecret` resource:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-secret
  data:
  - secretKey: password
    remoteRef:
      key: myapp/credentials
      property: password
```

## Why this matters

Never commit Secrets to Git, even encrypted ones. The correct GitOps approach: commit only `ExternalSecret` resources (which reference, not contain, the credential), and let the External Secrets Operator sync the actual values from a secure backend (Vault, AWS SSM, GCP Secret Manager). Credentials in a secure store can be rotated without a Git commit, audit-logged, and access-controlled per team.